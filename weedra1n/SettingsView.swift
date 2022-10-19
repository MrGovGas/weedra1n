//
//  SettingsView.swift
//  Pogo
//
//  Created by Uckermark on 17.10.22.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var action: Actions
    @State private var showFile = false
    var body: some View {
        VStack {
            List {
                Toggle("Enable Verbose", isOn: $action.verbose)
                Button("Save log") {
                    showFile = true
                }
            }
            Spacer()
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .fileExporter(isPresented: $showFile, document: action.getLogFile(),
                      contentType: .utf8PlainText, defaultFilename: "weed_log") { result in
            switch result {
                case .success(let url):
                action.addToLog(msg: "[*] Shared log successfully")
                case .failure(let error):
                action.addToLog(msg: "[*] Failed to share log")
                action.vLog(msg: error.localizedDescription)
            }
        }
    }
}
