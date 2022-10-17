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
    var action = Actions()
    var body: some Scene {
        WindowGroup {
            ContentView(action: action)
        }
    }
}
