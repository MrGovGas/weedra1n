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
    @State private var scripturl = ""
    @State private var showNewUrl = false
    @State private var urlIsInvalid = false
    var body: some View {
        VStack {
            List {
                Section {
                    Toggle("Enable Verbose", isOn: $action.verbose)
                }
                Section {
                    TextField("Enter script URL", text: $scripturl)
                    Button("Select custom postinst script") {
                        if action.canOpenURL(string: scripturl) {
                            action.scripturl = scripturl
                            showNewUrl = true
                        } else {
                            urlIsInvalid = true
                        }
                    }
                    Button("Use default script") {
                        action.useDefaultScript()
                        showNewUrl = true
                    }
                }
            }
            .alert("Using script: " + action.scripturl, isPresented: $showNewUrl) {
                Button("OK", role: .cancel) { }
            }
            .alert("Invalid URL. Script unchanged", isPresented: $urlIsInvalid) {
                Button("OK", role: .cancel) { }
            }
            Spacer()
        }
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}
