//
//  ContentView.swift
//  Pogo
//
//  Created by Leonard Lausen on 16.10.22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var action: actions
    @State private var showPopover = false
    private let gitCommit = Bundle.main.infoDictionary?["REVISION"] as? String ?? "unknown"
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    var body: some View {
        VStack {
            List {
                Button("Install", action: action.Install)
                Button("Remove", action: action.Remove)
                Button("Tools") { showPopover = true}
                    .popover(isPresented: $showPopover) {
                        VStack {
                            Text("Tools")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding()
                            List {
                                Section {
                                    Button("uicache", action: action.runUiCache)
                                    Button("Remount Preboot", action: action.remountPreboot)
                                    Button("Launch Daemons", action: action.launchDaemons)
                                    Button("Respring", action: action.respring)
                                }
                                Section {
                                    Button("Do All", action: action.Tools)
                                }
                            }
                            Text("Pogo - by Amy")
                                .font(.callout)
                                .fontWeight(.ultraLight)
                                .multilineTextAlignment(.center)
                        }
                        .background(Color(.systemGroupedBackground))
                    }
            }
            Text(action.status)
            Text("v\(version) (\(gitCommit))")
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(action: actions())
    }
}
