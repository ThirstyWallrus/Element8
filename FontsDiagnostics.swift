//
//  FontsDiagnostics.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/4/25.
//


// https://github.com/ThirstyWallrus/Element8
// FontsDiagnostics.swift
// Safe debug helper: prints registered font families and names on launch.
// Add this file and call FontsDiagnostics.printAvailableFonts() from Element8App.init()

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum FontsDiagnostics {
    static func printAvailableFonts() {
        #if canImport(UIKit)
        NSLog("----- Registered font families and names -----")
        for family in UIFont.familyNames.sorted() {
            NSLog("Family: \(family)")
            let names = UIFont.fontNames(forFamilyName: family).sorted()
            for name in names {
                NSLog("    Font: \(name)")
            }
        }
        NSLog("----- End registered fonts -----")
        #else
        print("FontsDiagnostics: Not running on UIKit platform; skipping font listing.")
        #endif
    }
}