//
//  Element8App.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//

import SwiftUI

@main
struct Element8App: App {
    var body: some Scene {
        WindowGroup {
            // Global background: Sepia applied here so every view in the window group
            // inherits the background and we avoid duplicating full-screen images
            ZStack {
                Image("Sepia")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                // Main app entry view (navigation is handled inside)
                ContentView()
            }
        }
    }
}
