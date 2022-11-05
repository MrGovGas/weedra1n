//
//  ContentView.swift
//  Pogo
//
//  Created by Uckermark on 16.10.22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var action: Actions
    @State private var showTools = false
    @State private var showSettings = false
    private let gitCommit = Bundle.main.infoDictionary?["REVISION"] as? String ?? "unknown"
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Button("Install", action: action.Install)
                    Button("Remove", action: action.Remove)
                    Button("Tools") { showTools = true }
                        .confirmationDialog("", isPresented: $showTools) {
                            Button("Rebuild Icon Cache", action: action.runUiCache)
                            Button("Remount Preboot", action: action.remountPreboot)
                            Button("Launch Daemons", action: action.launchDaemons)
                            Button("Respring", action: {
                                respring()
                            })
                            Button("Do All", action: action.runTools)
                        }
                }
                .navigationBarTitle("weedra1n", displayMode: .inline)
                .foregroundColor(Color.blue)
                Divider()
                ScrollView {
                    HStack {
                        Text(action.log)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding()
                        Spacer()
                    }
                }
                Divider()
                HStack {
                    Text("v\(version) beta (\(gitCommit))")
                    Spacer()
                    NavigationLink(destination: SettingsView(action: action)) {
                        Text("Settings")
                            .foregroundColor(Color(UIColor.systemBackground))
                            .colorInvert()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(.stack)
    }
}
