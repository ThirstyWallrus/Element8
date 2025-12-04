//
//  FireCharacter.swift
//  Element8
//
//  Fire character profile and registration.
//

import SwiftUI

private let fireProfile = CharacterProfile(
    key: "fire",
    displayName: "Fire",
    description: "A fierce attacker. Excels at dealing extra damage in combat.",
    baseHealth: 12,
    color: .red,
    spriteName: "char_fire", // optional: place an asset with this name in Assets.xcassets
    elementCase: .fire,
    startingCornerIndex: 3, // bottom-left
    movementModifier: 0,
    attackModifier: 2,
    defenseModifier: 0,
    healModifier: 0,
    specialAbility: "Inferno Strike: increased chance to critically damage adjacent enemies."
)

private let _register_fire: Void = {
    CharacterRegistry.shared.register(fireProfile)
}()

