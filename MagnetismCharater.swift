//
//  MagnetismCharater.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/2/25.
//  Magnetism (Metal) character profile and registration.
//

import SwiftUI

private let magnetismProfile = CharacterProfile(
    key: "magnetism",
    displayName: "Magnetism",
    description: "Controls metalic forces — can disrupt enemy equipment and fortify defenses.",
    baseHealth: 12,
    color: .gray,
    spriteName: "char_magnetism",
    elementCase: .magnetism, // maps to existing ElementCharacter.metal
    startingCornerIndex: 3, // bottom-left
    movementModifier: 0,
    attackModifier: 0,
    defenseModifier: 2,
    healModifier: 0,
    specialAbility: "Magnetic Field: raises defense and can pull/repel nearby enemy tokens in special moves."
)

private let _register_magnetism: Void = {
    CharacterRegistry.shared.register(magnetismProfile)
}()
