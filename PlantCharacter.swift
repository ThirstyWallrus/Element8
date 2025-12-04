//
//  PlantCharacter.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/2/25.
//  Plant (Wood) character profile and registration.
//

import SwiftUI

private let plantProfile = CharacterProfile(
    key: "plant",
    displayName: "Plant",
    description: "Nature healer. Gains healing benefits when drawing cards or at end of turn.",
    baseHealth: 11,
    color: .green,
    spriteName: "char_plant",
    elementCase: .plant, // maps to existing ElementCharacter.wood
    startingCornerIndex: 3, // bottom-left
    movementModifier: 0,
    attackModifier: 0,
    defenseModifier: 0,
    healModifier: 1,
    specialAbility: "Leaf Renew: heals when drawing a card and regenerates 1 HP at end of turn."
)

private let _register_plant: Void = {
    CharacterRegistry.shared.register(plantProfile)
}()
