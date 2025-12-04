//
//  FontLoader.swift
//  Element8
//
//  Purpose:
//   - Programmatically register bundled .ttf/.otf fonts at app startup using CoreText.
//   - Print diagnostics in DEBUG builds to show discovered PostScript names to use with Font.custom(...).
//   - Provide helpers to register specific filenames if fonts are in a subdirectory.
//
//  Non-invasive: calling these functions is safe and idempotent — CoreText will report already-registered fonts.
//  Add this file to the app target and call FontLoader.registerAllBundleFonts() early (Element8App.init).
//

import Foundation
import CoreText
import SwiftUI

enum FontLoader {
    /// Register all .ttf and .otf font files found at the top-level of the main bundle.
    static func registerAllBundleFonts() {
        let exts = ["ttf", "otf"]
        var anyFound = false
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    anyFound = true
                    registerFontFile(at: url)
                }
            }
        }

        #if DEBUG
        if !anyFound {
            print("FontLoader: No .ttf/.otf files found at the top-level of the main bundle.")
            print("  - If your fonts are inside a subdirectory in the bundle, call FontLoader.registerFontFile(named:subdirectory:)")
            print("  - Verify Target Membership and Copy Bundle Resources.")
        }
        // Print available fonts and mapping of PostScript names to filenames
        printAvailableFonts()
        let mapping = mapRegisteredBundleFonts()
        if mapping.isEmpty {
            print("FontLoader: No PostScript->filename mapping discovered for bundle fonts.")
        } else {
            print("FontLoader: Discovered PostScript name -> filename mapping:")
            for (ps, filename) in mapping.sorted(by: { $0.key < $1.key }) {
                print("  \(ps)  ->  \(filename)")
            }
        }
        #endif
    }

    /// Register a single font file by its URL (returns true on success).
    @discardableResult
    static func registerFontFile(at url: URL) -> Bool {
        #if DEBUG
        print("FontLoader: Registering font file: \(url.lastPathComponent)")
        #endif
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if success {
            #if DEBUG
            print("FontLoader: Registered '\(url.lastPathComponent)' ✅")
            #endif
            return true
        } else {
            #if DEBUG
            if let e = error?.takeRetainedValue() {
                print("FontLoader: Failed to register \(url.lastPathComponent): \(e.localizedDescription)")
            } else {
                print("FontLoader: Failed to register \(url.lastPathComponent): unknown error")
            }
            #endif
            return false
        }
    }

    /// Convenience: register a font file by filename (relative to main bundle).
    /// Use when fonts are in a subdirectory: provide subdirectory parameter.
    @discardableResult
    static func registerFontFile(named filename: String, subdirectory: String? = nil) -> Bool {
        if let url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: subdirectory) {
            return registerFontFile(at: url)
        } else {
            #if DEBUG
            print("FontLoader: Could not find font file named '\(filename)' in bundle (subdirectory: \(subdirectory ?? "nil")).")
            #endif
            return false
        }
    }

    /// Print available font families and font names to console (DEBUG builds).
    static func printAvailableFonts() {
        #if canImport(UIKit)
        let families = UIFont.familyNames.sorted()
        print("FontLoader: Available font families (\(families.count)):")
        for f in families {
            let names = UIFont.fontNames(forFamilyName: f).sorted()
            print("  Family: \(f)")
            for n in names {
                print("    - \(n)")
            }
        }
        #elseif canImport(AppKit)
        let families = NSFontManager.shared.availableFontFamilies.sorted()
        print("FontLoader: Available font families (\(families.count)):")
        for f in families {
            let members = NSFontManager.shared.availableMembers(ofFontFamily: f) ?? []
            let names = members.compactMap { $0[0] as? String }
            print("  Family: \(f)")
            for n in names {
                print("    - \(n)")
            }
        }
        #else
        print("FontLoader: Platform does not support UIKit/AppKit font listing.")
        #endif
    }

    /// Create a map: PostScriptName -> filename for registered font files found in the bundle (top-level).
    static func mapRegisteredBundleFonts() -> [String: String] {
        var map: [String: String] = [:]
        let exts = ["ttf", "otf"]
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    if let data = try? Data(contentsOf: url) as CFData,
                       let provider = CGDataProvider(data: data),
                       let cgFont = CGFont(provider) {
                        if let postScript = cgFont.postScriptName as String? {
                            map[postScript] = url.lastPathComponent
                        }
                    }
                }
            }
        }
        return map
    }
}
