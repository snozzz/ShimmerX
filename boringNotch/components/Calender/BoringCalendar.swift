//
//  BoringCalender.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 08/09/24.
//

import EventKit
import SwiftUI
import Defaults

private enum CalendarPanelMode {
    case calendar
    case todo
}

final class TodoManager: ObservableObject {
    @Published var items: [TodoItem]

    init(items: [TodoItem] = Defaults[.todoItems]) {
        self.items = items
    }

    var pendingItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }

    var completedItems: [TodoItem] {
        items.filter(\.isCompleted)
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed), at: 0)
        persist()
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isCompleted.toggle()
        persist()
    }

    private func persist() {
        Defaults[.todoItems] = items
    }
}

struct Config: Equatable {
//    var count: Int = 10  // 3 days past + today + 7 days future
    var past: Int = 3
    var future: Int = 7
    var steps: Int = 1  // Each step is one day
    var spacing: CGFloat = 1
    var showsText: Bool = true
    var offset: Int = 2 // Number of dates to the left of the selected date
}

struct WheelPicker: View {
    @EnvironmentObject var vm: BoringViewModel
    @Binding var selectedDate: Date
    @State private var scrollPosition: Int?
    @State private var haptics: Bool = false
    @State private var byClick: Bool = false
    let config: Config
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: config.spacing) {
                let totalSteps = config.steps * (config.past + config.future)
                let spacerNum = config.offset
                ForEach(0..<totalSteps + 2 * spacerNum + 1, id: \.self) { index in
                    if(index < spacerNum || index > totalSteps + spacerNum - 1){
                        Spacer().frame(width: 24, height: 24).id(index)
                    } else {
                        let offset = -config.offset - config.past
                        let date = dateForIndex(index, offset: offset)
                        let isSelected = isDateSelected(index, offset: offset)
                        dateButton(date: date, isSelected: isSelected, offset: offset){
                            selectedDate = date
                            byClick = true
                            withAnimation{
                                scrollPosition = indexForDate(date, offset: offset) - config.offset
                            }
                            haptics.toggle()
                        }
                    }
                }
            }
            .frame(height: 50)
            .scrollTargetLayout()
        }
        .scrollIndicators(.never)
        .scrollPosition(id: $scrollPosition, anchor: .leading)
        .safeAreaPadding(.horizontal)
        .sensoryFeedback(.alignment, trigger: haptics)
        .onChange(of: scrollPosition) { oldValue, newValue in
            if(!byClick){
                handleScrollChange(newValue: newValue, config: config)
            }else{
                byClick = false
            }
        }
        .onAppear {
            scrollToToday(config: config)
        }
    }
    
    private func dateButton(date: Date, isSelected: Bool, offset: Int, onClick:@escaping()->Void) -> some View {
        Button(action: onClick) {
            VStack(spacing: 2) {
                dayText(date: dateToString(for: date), isSelected: isSelected)
                dateCircle(date: date, isSelected: isSelected)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .id(indexForDate(date, offset: offset))
    }
    
    private func dayText(date: String, isSelected: Bool) -> some View {
        Text(date)
            .font(.caption2)
            .foregroundStyle(
                isSelected ? Defaults[.accentColor] : .gray
            )
    }
    
    private func dateCircle(date: Date, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Defaults[.accentColor] : .clear)
                .frame(width: 24, height: 24)
            Text("\(date.date)")
                .font(.title3)
                .foregroundStyle(isSelected ? .white : .gray)
        }
    }
    
    func handleScrollChange(newValue: Int?, config: Config) {
        let offset = -config.offset - config.past
        let todayIndex = indexForDate(Date(), offset: offset)
        guard let newIndex = newValue else { return }
        let targetDateIndex = newIndex + config.offset
        switch targetDateIndex{
        case todayIndex-config.past..<todayIndex+config.future:
            selectedDate = dateForIndex(targetDateIndex, offset: offset)
            haptics.toggle()
        default:
            return
        }
    }
    
    private func scrollToToday(config: Config) {
        let today = Date()
        let todayIndex = indexForDate(today, offset: -config.offset - config.past)
        byClick = true
        scrollPosition = todayIndex - config.offset
        selectedDate = today
    }
    
    private func indexForDate(_ date: Date, offset: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date())
        let targetDate = calendar.startOfDay(for: date)
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
        return daysDifference
    }
    
    private func dateForIndex(_ index: Int, offset: Int) -> Date {
        let startDate = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        return Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? Date()
    }
    
    private func dayForIndex(_ index: Int, offset: Int) -> String {
        let date = dateForIndex(index, offset: offset)
        return dateToString(for: date)
    }
    
    private func dateToString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func isDateSelected(_ index: Int, offset: Int) -> Bool {
        Calendar.current.isDate(dateForIndex(index, offset: offset), inSameDayAs: selectedDate)
    }
}

struct CalendarView: View {
    @EnvironmentObject var vm: BoringViewModel
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var todoManager = TodoManager()
    @State private var selectedDate = Date()
    @State private var panelMode: CalendarPanelMode = .calendar
    @State private var gestureConsumed = false

    private let switchThreshold: CGFloat = 65
    private let panelHeight: CGFloat = 148

    var body: some View {
        ZStack {
            if panelMode == .calendar {
                calendarContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                TodoPanelView(todoManager: todoManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: 250, alignment: .top)
        .frame(height: panelHeight, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .panGesture(direction: .up) { amount, phase in
            handleSwipe(amount: amount, phase: phase, direction: .up)
        }
        .panGesture(direction: .down) { amount, phase in
            handleSwipe(amount: amount, phase: phase, direction: .down)
        }
        .animation(.smooth(duration: 0.22), value: panelMode)
        .listRowBackground(Color.clear)
        .onChange(of: selectedDate) { _, newDate in
            calendarManager.updateCurrentDate(newDate)
        }
        .onChange(of: vm.notchState) { _, _ in
            calendarManager.updateCurrentDate(Date.now)
            if vm.notchState == .closed {
                panelMode = .calendar
            }
        }
        .onAppear {
            calendarManager.updateCurrentDate(Date.now)
        }
    }

    private var calendarContent: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(selectedDate, format: .dateTime.month())")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                ZStack {
                    WheelPicker(selectedDate: $selectedDate, config: Config())
                    HStack {
                        LinearGradient(
                            colors: [.black, .clear], startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: 20)
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black], startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: 20)
                    }
                }
            }
            if calendarManager.events.isEmpty {
                EmptyEventsView()
            } else {
                EventListView(events: calendarManager.events)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func handleSwipe(amount: CGFloat, phase: NSEvent.Phase, direction: PanDirection) {
        if phase == .ended || phase == .cancelled {
            gestureConsumed = false
            return
        }

        guard !gestureConsumed, amount >= switchThreshold else { return }

        switch direction {
        case .up where panelMode == .calendar:
            panelMode = .todo
            gestureConsumed = true
        case .down where panelMode == .todo:
            panelMode = .calendar
            gestureConsumed = true
        default:
            break
        }
    }
}

struct TodoPanelView: View {
    @ObservedObject var todoManager: TodoManager
    @State private var draftTitle = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Reminders")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                Spacer()
                Text("Swipe down")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Defaults[.accentColor])
                    .font(.system(size: 16))
                TextField("Add a reminder", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .focused($isComposerFocused)
                    .onSubmit(addItem)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onTapGesture {
                NSApp.activate(ignoringOtherApps: true)
                isComposerFocused = true
            }

            if todoManager.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No reminders")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Add one here, then swipe back down to the calendar.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(todoManager.pendingItems.prefix(4)) { item in
                            TodoRowView(item: item) {
                                todoManager.toggle(item)
                            }
                        }

                        if !todoManager.completedItems.isEmpty {
                            Divider()
                                .overlay(.white.opacity(0.08))
                                .padding(.vertical, 2)

                            ForEach(todoManager.completedItems.prefix(2)) { item in
                                TodoRowView(item: item) {
                                    todoManager.toggle(item)
                                }
                                .opacity(0.7)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func addItem() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            todoManager.add(trimmed)
        }
        draftTitle = ""
        isComposerFocused = true
    }
}

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(item.isCompleted ? Defaults[.accentColor] : .gray)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(item.isCompleted ? .gray : .white)
                        .strikethrough(item.isCompleted, color: .gray)
                        .multilineTextAlignment(.leading)
                    Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyEventsView: View {
    var body: some View {
        ScrollView {
            Text("No events today")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Enjoy your free time!")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct EventListView: View {
    @Environment(\.openURL) private var openURL
    let events: [EKEvent]

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack(alignment: .top) {
                VStack(alignment: .trailing, spacing: 5) {
                    ForEach(events.indices, id: \.self) { index in
                        VStack(alignment: .trailing) {
                            if isAllDayEvent(
                                start: events[index].startDate, end: events[index].endDate)
                            {
                                Text("All-day")
                            } else {
                                Text("\(events[index].startDate, style: .time)")
                                Text("\(events[index].endDate, style: .time)")
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        .padding(.bottom, 8)
                        .font(.caption2)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(events.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            VStack(spacing: 5) {
                                Image(
                                    systemName: isEventEnded(events[index].endDate)
                                        ? "checkmark.circle" : "circle"
                                )
                                .foregroundColor(isEventEnded(events[index].endDate) ? .green : .gray)
                                .font(.footnote)
                                Rectangle()
                                    .frame(width: 1)
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .opacity(index == events.count - 1 ? 0 : 1)
                            }
                            .padding(.top, 1)

                            Button {
                                if let url = generateEventURL(for: events[index]) {
                                    openURL(url)
                                }
                            } label: {
                                Text(events[index].title)
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)

                            Spacer(minLength: 0)
                        }
                        .opacity(isEventEnded(events[index].endDate) ? 0.6 : 1)
                    }
                }
            }
        }
        .scrollIndicators(.never)
        .scrollTargetBehavior(.viewAligned)
    }

    private func isAllDayEvent(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current

        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)

        return startComponents.hour == 0 && startComponents.minute == 0 && endComponents.hour == 23
            && endComponents.minute == 59
    }

    private func isEventEnded(_ end: Date) -> Bool {
        return Date.now > end
    }

    private func generateEventURL(for event: EKEvent) -> URL? {
        var dateComponent = ""
        if event.hasRecurrenceRules {
            if let startDate = event.startDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                formatter.timeZone = TimeZone.current
                if !event.isAllDay {
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                }
                dateComponent = "/\(formatter.string(from: startDate))"
            }
        }
        return URL(string: "ical://ekevent\(dateComponent)/\(event.calendarItemIdentifier)?method=show&options=more")
    }
}

// Keep the CalendarManager, EmptyEventsView, and EventListView as they were in the previous implementation

#Preview {
    CalendarView()
        .frame(width: 250)
        .padding(.horizontal)
        .background(.black)
        .environmentObject(BoringViewModel())
}
