
//
//  CustomDie.swift
//  Element8
//
//  Created by Copilot Space on 2025-12-01.
//  Purpose: Flexible custom die model + SwiftUI view.
//  - Supports numeric faces (1..N), pips (d6-style), and image faces.
//  - Supports optional side weights for non-uniform dice.
//  - Provides a roll() helper that returns chosen index + semantic value if needed.
//  - Provides CustomDieView which displays one face and is animation-friendly.
//

import SwiftUI
import Combine

// MARK: - DieFaceContent
/// Content for a single die face.
public enum DieFaceContent: Hashable {
    /// Simple numeric face (e.g., "4")
    case number(Int)
    /// Pips layout: we keep it as an Int for standard d6 style (1..6).
    /// If you want custom pip layouts for non-6-sided dice you can extend this.
    case pips(Int)
    /// Image asset name to render for the face (the image should exist in Assets.xcassets)
    case image(String)
    
    /// Human-friendly label used for accessibility. You can extend this to localize
    func accessibilityLabel() -> String {
        switch self {
        case .number(let n):
            return "Face \(n)"
        case .pips(let n):
            return "\(n) pips"
        case .image(let name):
            // If you want to be extra-friendly, map asset names to text labels elsewhere.
            return name.replacingOccurrences(of: "_", with: " ")
        }
    }
    
    /// Semantic numeric value for gameplay (e.g., movement amount). For most face types
    /// the numeric value is the same as a number/pips; for image we assume images are named
    /// with trailing _<value> or you provide a mapping externally.
    func semanticValue(defaultValue: Int = 1) -> Int {
        switch self {
        case .number(let n): return n
        case .pips(let n): return n
        case .image(_):
            // Cannot infer a numeric value safely for arbitrary images.
            // Default to 1; prefer supplying a separate mapping if needed.
            return defaultValue
        }
    }
}

// MARK: - DieSpec
/// Describes a die with arbitrary faces and optional weights.
/// Example: standard d6 -> sides = [.pips(1), ... .pips(6)]
public struct DieSpec {
    /// The faces of the die in order (indexable)
    public var faces: [DieFaceContent]
    /// Optional weights to allow non-uniform probabilities. If nil, uniform weights are used.
    /// weights.count must equal faces.count when provided.
    public var weights: [Double]?
    /// Optional identifier name for this die (useful for per-player die selection).
    public var id: String?
    
    /// Create a DieSpec
    public init(id: String? = nil, faces: [DieFaceContent], weights: [Double]? = nil) {
        self.id = id
        self.faces = faces
        if let w = weights, w.count == faces.count {
            self.weights = w
        } else {
            self.weights = nil
        }
    }
    
    /// Roll the die and return (index, face)
    public func rollOnce() -> (index: Int, face: DieFaceContent) {
        if let w = weights, w.count == faces.count {
            // Weighted random
            let idx = DieSpec.weightedIndex(weights: w)
            return (idx, faces[idx])
        } else {
            let idx = Int.random(in: 0..<faces.count)
            return (idx, faces[idx])
        }
    }
    
    /// Helper: return uniform standard d6 spec (pips)
    public static func standardD6Pips(id: String? = nil) -> DieSpec {
        let sides = (1...6).map { DieFaceContent.pips($0) }
        return DieSpec(id: id, faces: sides, weights: nil)
    }
    
    /// Helper: return numeric dN die
    public static func numeric(dSides: Int, id: String? = nil) -> DieSpec {
        let sides = (1...dSides).map { DieFaceContent.number($0) }
        return DieSpec(id: id, faces: sides, weights: nil)
    }
    
    /// Weighted random index helper (returns an Int index into faces)
    private static func weightedIndex(weights: [Double]) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else {
            return Int.random(in: 0..<weights.count)
        }
        let r = Double.random(in: 0..<total)
        var running: Double = 0
        for (i, w) in weights.enumerated() {
            running += w
            if r < running {
                return i
            }
        }
        return max(0, weights.count - 1)
    }
}

// MARK: - CustomDieView
/// Renders a single die face from a DieSpec. The view is intentionally simple so it's
/// easy to animate rotation/scale/opacity on transitions.
public struct CustomDieView: View {
    /// Face to render
    public var face: DieFaceContent
    /// Optional accent border color (for player color)
    public var accent: Color? = nil
    /// Size of the die square
    public var size: CGFloat = 96
    /// Corner radius
    public var cornerRadius: CGFloat = 12
    
    public init(face: DieFaceContent, accent: Color? = nil, size: CGFloat = 96, cornerRadius: CGFloat = 12) {
        self.face = face
        self.accent = accent
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.white, Color(white: 0.96)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(accent?.opacity(0.85) ?? Color.black.opacity(0.06), lineWidth: accent == nil ? 0.9 : 2)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)
            
            // Face content
            switch face {
            case .number(let n):
                Text("\(n)")
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .accessibilityLabel(Text("Die \(n)"))
            case .pips(let n):
                PipsView(pips: n, maxSize: size * 0.7)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(n) pips"))
            case .image(let name):
                if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.78, height: size * 0.78)
                        .clipShape(RoundedRectangle(cornerRadius: max(6, cornerRadius/1.5)))
                        .accessibilityLabel(Text(name.replacingOccurrences(of: "_", with: " ")))
                } else {
                    // Fallback to a numbered placeholder if image not found
                    Text(name)
                        .font(.system(size: size * 0.18, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(Text(name))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - PipsView
/// Lightweight view that draws standard pip arrangements for 1..6.
/// It scales to maxSize provided.
fileprivate struct PipsView: View {
    let pips: Int
    let maxSize: CGFloat
    
    init(pips: Int, maxSize: CGFloat) {
        self.pips = min(max(pips, 1), 6)
        self.maxSize = maxSize
    }
    
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let pipSize = max(6, s * 0.16)
            let offset = s * 0.22
            
            ZStack {
                // For each pip position, optionally draw a circle depending on pips
                if pips == 1 || pips == 3 || pips == 5 {
                    // center pip
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                }
                
                if pips >= 2 {
                    // top-left & bottom-right pair
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                        .position(x: s * 0.2, y: s * 0.2)
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                        .position(x: s * 0.8, y: s * 0.8)
                }
                
                if pips >= 4 {
                    // top-right & bottom-left pair
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                        .position(x: s * 0.8, y: s * 0.2)
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                        .position(x: s * 0.2, y: s * 0.8)
                }
                
                if pips == 6 {
                    // middle-left & middle-right
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                        .position(x: s * 0.2, y: s * 0.5)
                    Circle()
                        .fill(Color.black)
                        .frame(width: pipSize, height: pipSize)
                        .position(x: s * 0.8, y: s * 0.5)
                }
            }
            .frame(width: s, height: s)
        }
        .frame(width: maxSize, height: maxSize)
    }
}

// MARK: - Integration Helpers (Examples)
public extension DieSpec {
    /// Example: create an elemental die that uses image assets named "die_fire_1" .. "die_fire_6"
    /// Make sure those assets exist if you use this helper.
    static func elementalImageDie(prefix: String, id: String? = nil) -> DieSpec {
        let faces = (1...6).map { DieFaceContent.image("\(prefix)_\($0)") }
        return DieSpec(id: id ?? "\(prefix)-die", faces: faces, weights: nil)
    }
}
