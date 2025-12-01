//
//  WaterCharacter.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Water character profile and registration.
//

import SwiftUI

private let waterProfile = CharacterProfile(
    key: "water",
    displayName: "Water",
    description: "Adaptive and protective. Offers defensive bonuses in combat.",
    baseHealth: 11,
    color: .blue,
    spriteName: "char_water",
    elementCase: .water,
    startingCornerIndex: 3, // bottom-left
    movementModifier: 0,
    attackModifier: 0,
    defenseModifier: 1,
    healModifier: 0,
    specialAbility: "Tide Guard: gain defensive advantage when adjacent to allies."
)

private let _register_water: Void = {
    CharacterRegistry.shared.register(waterProfile)
}()

