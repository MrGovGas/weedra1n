//
//  ToolsView.swift
//  weedra1n
//
//  Created by Uckermark on 11.11.22.
//

import SwiftUI

struct ToolsView: View {
    @ObservedObject var action: Actions
    var body: some View {
        VStack {
            List {
                Button("Rebuild Icon Cache", action: action.runUiCache)
                Button("Remount Preboot", action: action.remountPreboot)
                Button("Launch Daemons", action: action.launchDaemons)
                Button("Respring", action: respring)
            }
            Divider()
        }
        .background(Color(.systemGroupedBackground))
    }
}
