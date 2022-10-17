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
    private let gitCommit = Bundle.main.infoDictionary?["REVISION"] as? String ?? "unknown"
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    
    var body: some View {
        VStack {
            List {
                Button("Install", action: action.Install)
                Button("Remove", action: action.Remove)
                Button("Tools") { showTools = true }
                    .confirmationDialog("", isPresented: $showTools) {
                        Button("uicache", action: action.runUiCache)
                        Button("Remount Preboot", action: action.remountPreboot)
                        Button("Launch Daemons", action: action.launchDaemons)
                        Button("Respring", action: action.respring)
                        Button("Do All", action: action.runTools)
                    }
            }
            HStack {
                Text(action.log)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                Spacer()
                    
            }
            HStack {
                Text("v\(version) (\(gitCommit))")
                Spacer()
                Text(action.status)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(action: Actions())
    }
}
