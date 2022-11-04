//
//  SettingsView.swift
//  Pogo
//
//  Created by Uckermark on 17.10.22.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var action: Actions
    var body: some View {
        VStack {
            List {
                Toggle("Enable Verbose", isOn: $action.verbose)
            }
            Spacer()
        }
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}
