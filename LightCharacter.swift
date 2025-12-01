//
//  LightCharacter.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Light character profile and registration.
//  Note: This does not map to an existing ElementCharacter case — elementCase is nil.
//

import SwiftUI

private let lightProfile = CharacterProfile(
    key: "light",
    displayName: "Light",
    description: "Illuminator and support. Reveals hidden map features and grants small buffs to allies.",
    baseHealth: 11,
    color: Color(red: 1.0, green: 0.95, blue: 0.7),
    spriteName: "char_light",
    elementCase: nil, // not currently in ElementCharacter enum
    movementModifier: 0,
    attackModifier: 0,
    defenseModifier: 0,
    healModifier: 1,
    specialAbility: "Illuminate: reveals tiles and temporarily increases ally visibility and accuracy."
)

private let _register_light: Void = {
    CharacterRegistry.shared.register(lightProfile)
}()

