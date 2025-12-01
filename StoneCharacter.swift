//
//  StoneCharacter.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Stone (Earth) character profile and registration.
//

import SwiftUI

private let stoneProfile = CharacterProfile(
    key: "stone",
    displayName: "Stone",
    description: "Sturdy defender. Resilient to damage and hard to push back.",
    baseHealth: 13,
    color: Color(red: 0.45, green: 0.36, blue: 0.24), // earthy brown
    spriteName: "char_stone",
    elementCase: .stone, // maps to existing ElementCharacter.earth
    startingCornerIndex: 3, // bottom-left
    movementModifier: 0,
    attackModifier: 0,
    defenseModifier: 1,
    healModifier: 1,
    specialAbility: "Stonewall: reduces incoming damage and slightly regenerates on turn end."
)

private let _register_stone: Void = {
    CharacterRegistry.shared.register(stoneProfile)
}()

