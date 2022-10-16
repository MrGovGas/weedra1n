//
//  PogoApp.swift
//  Pogo
//
//  Created by Leonard Lausen on 16.10.22.
//

import Foundation
import SwiftUI

@main
struct PogoApp: App {
    var action = actions()
    var body: some Scene {
        WindowGroup {
            ContentView(action: action)
        }
    }
}
