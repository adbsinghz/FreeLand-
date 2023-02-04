//
//  FreedomLandApp.swift
//  FreedomLand
//
//  Created by Arshdeep Singh on 1/23/23.
//

import SwiftUI
import Firebase

@main
struct FreedomLandApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
