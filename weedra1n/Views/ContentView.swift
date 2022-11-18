//
//  ContentView.swift
//  weedra1n
//
//  Created by Uckermark on 16.10.22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var action: Actions
    @State private var showTools = false
    @State private var showSettings = false
    init(act: Actions) {
        UITabBar.appearance().backgroundColor = .systemGroupedBackground
        action = act
    }
    var body: some View {
        TabView {
            JailbreakView(action: action)
                .tabItem {
                    Label("Jailbreak", systemImage: "wand.and.stars")
                }
            LogView(action: action)
                .tabItem {
                    Label("Log", systemImage: "doc.text.magnifyingglass")
            }
            SettingsView(act: action)
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver")
                }
        }
    }
}
