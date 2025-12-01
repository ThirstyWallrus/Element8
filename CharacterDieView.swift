
//
//  CharacterDieView.swift
//  Element8
//
//  Created by Copilot on 2025-12-01 (proposal).
//  Purpose: A reusable die view that supports per-character image faces with a styled SwiftUI fallback.
//
//  Usage:
//    // If you have images named "fire_die_1" ... "fire_die_6" in Assets.xcassets
//    CharacterDieView(profile: someProfile, face: 4)
//
//    // If you don't have images yet, the view will render a colored vector die using profile.color
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Simple in-memory image cache for UIImage lookups from the asset catalog.
/// Keeps things snappy when rotating faces quickly during animations.
fileprivate final class DieImageCache {
    static let shared = DieImageCache()
    private init() {}
    
    #if canImport(UIKit)
    private let cache = NSCache<NSString, UIImage>()
    
    func image(named name: String) -> UIImage? {
        let key = NSString(string: name)
        if let img = cache.object(forKey: key) { return img }
        if let loaded = UIImage(named: name) {
            cache.setObject(loaded, forKey: key)
            return loaded
        }
        return nil
    }
    #else
    func image(named: String) -> Image? { nil }
    #endif
}

/// A customizable die that first attempts to show an asset-based image for the given profile/key and face.
/// If the asset is missing, the view draws a stylized die using the profile color and overlays the numeric face.
public struct CharacterDieView: View {
    /// Optional profile used to style the fallback die; if nil, uses default gray.
    public let profile: CharacterProfile?
    /// Which numeric face to show (1...6). Values outside 1..6 will be clamped to 1..6.
    public let face: Int
    /// Optional override for the asset name prefix. If non-nil, this exact prefix is used instead of deriving from profile.key.
    /// Example: "fire" -> tries "fire_die_<face>".
    public let assetPrefixOverride: String?
    
    /// Padding inside the die for the numeric text, etc.
    private let innerPadding: CGFloat = 8
    
    public init(profile: CharacterProfile?, face: Int, assetPrefixOverride: String? = nil) {
        self.profile = profile
        self.face = min(max(face, 1), 6)
        self.assetPrefixOverride = assetPrefixOverride
    }
    
    public var body: some View {
        // Attempt to load the image from asset catalog first.
        if let image = uiImageForCurrentFace() {
            // Use the UIImage-backed SwiftUI Image for consistent rendering.
            #if canImport(UIKit)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .accessibilityLabel(accessibilityLabel())
            #else
            // On platforms without UIImage, fallback to vector
            fallbackDie()
            #endif
        } else {
            // Render the vector fallback die (colored rectangle + large number)
            fallbackDie()
        }
    }
    
    /// Fallback vector die: rounded rectangle gradient, number, subtle emboss.
    @ViewBuilder
    private func fallbackDie() -> some View {
        let baseColor = profile?.color ?? Color.gray
        let textColor = idealForegroundColor(for: baseColor)
        
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(gradient: Gradient(colors: [
                        baseColor.opacity(0.98),
                        baseColor.opacity(0.84)
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 4)
            
            // Numeric face (large)
            Text("\(face)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .shadow(color: Color.white.opacity(0.25), radius: 0.6, x: -0.6, y: -0.6)
                .shadow(color: Color.black.opacity(0.18), radius: 1.8, x: 1, y: 2)
                .padding(innerPadding)
        }
        .accessibilityLabel(accessibilityLabel())
    }
    
    /// Accessibility label describing the die face and profile.
    private func accessibilityLabel() -> Text {
        let who = profile?.displayName ?? "Die"
        return Text("\(who) die, face \(face)")
    }
    
    /// Determine the image name and try to load a UIImage for it.
    private func uiImageForCurrentFace() -> UIImage? {
        #if canImport(UIKit)
        let prefix = assetPrefixOverride ?? profile?.key ?? ""
        guard !prefix.isEmpty else { return nil }
        // Naming template: "<prefix>_die_<face>" (recommended).
        let candidate = "\(prefix)_die_\(face)"
        if let img = DieImageCache.shared.image(named: candidate) {
            return img
        }
        // Try alternate candidate ordering if you prefer "die_<prefix>_<face>"
        let alt = "die_\(prefix)_\(face)"
        if let altImg = DieImageCache.shared.image(named: alt) {
            return altImg
        }
        // No image found
        return nil
        #else
        return nil
        #endif
    }
    
    /// Decide whether white or black text contrasts better on the given Color.
    private func idealForegroundColor(for background: Color) -> Color {
        #if canImport(UIKit)
        // Try to get components via UIColor for a heuristic. Default to white if unknown.
        if let ui = UIColor(background) {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            // perceived brightness (standard formula)
            let brightness = (r * 299 + g * 587 + b * 114) / 1000
            return brightness > 0.6 ? Color.black : Color.white
        }
        #endif
        return Color.white
    }
}

#if DEBUG
struct CharacterDieView_Previews: PreviewProvider {
    static var previews: some View {
        // A couple of demo profiles (mirrors your CharacterProfile model)
        let fire = CharacterProfile(key: "fire", displayName: "Fire", description: "Fierce attacker", baseHealth: 12, color: .red, spriteName: "char_fire", elementCase: .fire, movementModifier: 0, attackModifier: 2, defenseModifier: 0, healModifier: 0, specialAbility: "Inferno Strike")
        let light = CharacterProfile(key: "light", displayName: "Light", description: "Support", baseHealth: 11, color: Color(red: 1.0, green: 0.95, blue: 0.7), spriteName: nil, elementCase: nil, movementModifier: 0, attackModifier: 0, defenseModifier: 0, healModifier: 1, specialAbility: "Illuminate")
        
        return Group {
            VStack(spacing: 12) {
                Text("Fire die (image fallback may render vector if assets missing)")
                HStack(spacing: 12) {
                    ForEach(1...6, id: \.self) { f in
                        CharacterDieView(profile: fire, face: f)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .padding()
            
            VStack(spacing: 12) {
                Text("Light die (no images -> vector fallback colored)")
                HStack(spacing: 12) {
                    ForEach(1...6, id: \.self) { f in
                        CharacterDieView(profile: light, face: f)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
