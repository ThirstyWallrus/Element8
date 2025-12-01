//
//  CharacterProfile.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Purpose: Shared model for editable character profiles and a lightweight registry.
//

import SwiftUI

/// A single editable character profile used by the UI for display and editing.
/// This is intentionally separate from the game's ElementCharacter enum so profiles
/// can include presentation metadata and optional mapping to the enum.
public struct CharacterProfile: Identifiable, Hashable {
    public let id: UUID
    /// Unique key used to look up this profile (e.g., "fire", "wind", "plant").
    public let key: String
    /// Human readable name shown in UI ("Fire", "Wind", "Plant", ...).
    public var displayName: String
    /// Short help or description shown in editors or tooltips.
    public var description: String
    /// Base health for this character (editable).
    public var baseHealth: Int
    /// Primary color used to tint UI elements for this character.
    public var color: Color
    /// Optional sprite / asset name in the asset catalog.
    public var spriteName: String?
    /// Optional mapping to the ElementCharacter enum (if applicable).
    /// If nil, this profile is purely presentational and not directly mapped.
    public var elementCase: ElementCharacter?
    /// Movement modifier (added to dice roll movement).
    public var movementModifier: Int
    /// Attack modifier (added to attack rolls).
    public var attackModifier: Int
    /// Defense modifier (added to defense rolls).
    public var defenseModifier: Int
    /// Heal modifier (used by heal effects).
    public var healModifier: Int
    /// A short human readable description of the special ability or power.
    public var specialAbility: String?
    
    public init(key: String,
                displayName: String,
                description: String,
                baseHealth: Int = 10,
                color: Color = .white,
                spriteName: String? = nil,
                elementCase: ElementCharacter? = nil,
                movementModifier: Int = 0,
                attackModifier: Int = 0,
                defenseModifier: Int = 0,
                healModifier: Int = 0,
                specialAbility: String? = nil) {
        self.id = UUID()
        self.key = key
        self.displayName = displayName
        self.description = description
        self.baseHealth = baseHealth
        self.color = color
        self.spriteName = spriteName
        self.elementCase = elementCase
        self.movementModifier = movementModifier
        self.attackModifier = attackModifier
        self.defenseModifier = defenseModifier
        self.healModifier = healModifier
        self.specialAbility = specialAbility
    }
}

/// Lightweight registry to collect character profiles. This makes it easy to add
/// new/edit existing profiles without changing other areas of the app.
public final class CharacterRegistry {
    public static let shared = CharacterRegistry()
    
    private var storage: [String: CharacterProfile] = [:]
    private init() {}
    
    /// Register or overwrite a profile using its key.
    public func register(_ profile: CharacterProfile) {
        storage[profile.key.lowercased()] = profile
    }
    
    /// Return a profile by key (case-insensitive).
    public func profile(forKey key: String) -> CharacterProfile? {
        storage[key.lowercased()]
    }
    
    /// All profiles in insertion order (dictionary order not guaranteed).
    public var profiles: [CharacterProfile] {
        Array(storage.values)
    }
    
    /// Sorted copy of profiles by displayName.
    public var profilesSortedByName: [CharacterProfile] {
        profiles.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
