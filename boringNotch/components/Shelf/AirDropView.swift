//
//  AirDrop+View.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/8.
//

import SwiftUI
import UniformTypeIdentifiers

struct AirDropView: View {
    @EnvironmentObject var vm: BoringViewModel
    
    @State var trigger: UUID = .init()
    @State var targeting = false
    @State private var activeDrop: AirDrop?
    
    var body: some View {
        dropArea
            .onDrop(of: [.data], isTargeted: $vm.dropZoneTargeting) { providers in
                trigger = .init()
                vm.beginDrop(to: .airdrop)
                DispatchQueue.global().async { beginDrop(providers) }
                return true
            }
    }
    
    var dropArea: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .opacity(0.5)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay { dropLabel }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
    }
    
    var dropLabel: some View {
        VStack(spacing: 8) {
            Image(systemName: "airplayaudio")
            Text("AirDrop")
        }
        .foregroundStyle(.gray)
        .font(.system(.headline, design: .rounded))
        .contentShape(Rectangle())
        .onTapGesture {
            trigger = .init()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let picker = NSOpenPanel()
                picker.allowsMultipleSelection = true
                picker.canChooseDirectories = true
                picker.canChooseFiles = true
                picker.begin { response in
                    if response == .OK {
                        startDrop(with: picker.urls, shouldResetDropInteraction: false)
                    }
                }
            }
        }
    }
    
    func beginDrop(_ providers: [NSItemProvider]) {
        assert(!Thread.isMainThread)
        guard let urls = providers.interfaceConvert() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startDrop(with: urls, shouldResetDropInteraction: true)
        }
    }

    func startDrop(with urls: [URL], shouldResetDropInteraction: Bool) {
        let drop = AirDrop(files: urls)
        drop.onFinish = {
            DispatchQueue.main.async {
                activeDrop = nil
                if shouldResetDropInteraction {
                    vm.resetDropInteraction()
                }
                vm.close()
                vm.coordinator.currentView = .home
            }
        }
        activeDrop = drop
        drop.begin()
    }
}
