//
//  ElectricityCharacter.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Electricity character profile and registration.
//  (Requested as 'Electricy' — filename uses 'Electricity' for clarity)
//

import SwiftUI

private let electricityProfile = CharacterProfile(
    key: "electricity",
    displayName: "Electricity",
    description: "High-risk, high-reward. Chance to stun opponents and disrupt their next turn.",
    baseHealth: 10,
    color: .yellow,
    spriteName: "char_electricity",
    elementCase: .electricity, // maps to existing ElementCharacter.lightning
    movementModifier: 0,
    attackModifier: 1,
    defenseModifier: 0,
    healModifier: 0,
    specialAbility: "Chain Shock: may stun an enemy (skip their next action) on successful attack."
)

private let _register_electricity: Void = {
    CharacterRegistry.shared.register(electricityProfile)
}()

