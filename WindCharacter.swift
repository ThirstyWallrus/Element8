//
//  WindCharacter.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Wind character profile and registration.
//

import SwiftUI

private let windProfile = CharacterProfile(
    key: "wind",
    displayName: "Wind",
    description: "Light and fast. Gains extra movement to outmaneuver opponents.",
    baseHealth: 10,
    color: .cyan,
    spriteName: "char_wind",
    elementCase: .wind,
    startingCornerIndex: 3, // bottom-left
    movementModifier: 2,
    attackModifier: 0,
    defenseModifier: 0,
    healModifier: 0,
    specialAbility: "Gale Step: +2 movement and can move through one occupied tile."
)

private let _register_wind: Void = {
    CharacterRegistry.shared.register(windProfile)
}()
