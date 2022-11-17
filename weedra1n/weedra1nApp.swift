//
//  PogoApp.swift
//  Pogo
//
//  Created by Uckermark on 16.10.22.
//

import Foundation
import SwiftUI

@main
struct PogoApp: App {
    var action: Actions
    
    init() {
        action = Actions()
        if FileManager().fileExists(atPath: "/var/mobile/Documents/") {
            action.removeDocDirectory()
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView(act: action)
        }
    }
}
