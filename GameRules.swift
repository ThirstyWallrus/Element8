//
//  GameRules.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/4/25.
//


//
//  GameRules.swift
//  Element8
//
//  Created by Copilot on 2025-12-04.
//  Purpose: Dedicated, scrollable Game Rules view. Uses Caribbean for headings
//           and Norse for button labels per project conventions.
//

import SwiftUI

struct GameRules: View {
    @Environment(\.dismiss) private var dismiss
    
    // Replace or extend this rules text as you wish. Kept detailed but clear.
    private let rulesText: String = """
Game Rules — Element 8

Overview
Element 8 is a perimeter-focused area-control and elimination game for 2–8 players.
Players select elemental characters with unique abilities and start at corner tiles,
then move along the board perimeter to engage opponents and capture advantages.

Setup
• Choose 2–8 character profiles in the Play menu.
• Each profile starts at its assigned corner on the perimeter path.
• Map obstacles (barriers) are placed randomly during board initialization,
  but never on perimeter tiles to ensure movement is always possible.
• Each player begins with their profile's Base Health.

Turn Sequence
1. Choose direction: Forward (clockwise) or Backward (counter-clockwise).
2. Roll the die (1–6):
   - Add your movement modifier from your profile to the die result.
   - Move that many perimeter spaces in the chosen direction (wraps around).
3. Resolve any immediate tile effects (barriers, special tiles).
4. If adjacent to or sharing a tile with an opponent, combat occurs automatically.
5. Optionally draw a game card if the game logic triggers a draw.
6. End your turn; apply end-of-turn effects (e.g., Stone/Plant regen).

Movement & Board
• Movement is strictly along the board perimeter. The perimeter path is computed
  clockwise starting at the top-left corner and continues around the grid.
• Corners are considered special starting points and can host multiple players.
• Barriers are indicated visually; they are never placed on perimeter tiles at setup.

Combat
• Combat is resolved when players are adjacent (Manhattan distance ≤ 1) or on the same tile.
• Attacker rolls attack (1–6) + attack modifier. Defender rolls defense (1–6) + defense modifier.
• If attack > defense: damage = (attack - defense) + global damageMultiplier (incremented on eliminations).
  Additional effects (flame cards, stone card, etc.) may alter damage.
• If defender health ≤ 0, defender is eliminated; the winner is checked after each elimination.

Cards & Effects
• Game cards are drawn from a pool and include effects such as Heal, Buff Attack, and Shift Map.
• Shift Map swaps tiles on the board; the implementation avoids breaking perimeter accessibility.
• Some cards are consumable (e.g., Flame cards) and will decrement when used.

Winning
• The last player remaining (all others eliminated) wins.
• Some variants may use objectives or emblem counts instead of elimination — adjust rules as desired.

House Rules & Notes
• Movement modifiers, attack/defense values, and special abilities are profile-driven and editable in the Character Editor.
• The game code supports a number of convenience hooks (card draw, stone blocking) for tuning balance.
• If you want a variant (e.g., non-perimeter movement), the GameViewModel contains helpers to adapt movement logic.

Accessibility
• The board and tiles include accessibility labels describing tile coordinates and players present.
• Die and UI elements include accessible descriptions for screen readers.

Have fun! Tweak profile stats and card effects in the Character Editor to balance your custom games.
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Optional brand banner for consistent look
                HStack {
                    Spacer()
                    Image("Element8Title")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 420, maxHeight: 96)
                        .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
                    Spacer()
                }
                .padding(.top, 14)

                Text("Game Rules")
                    // Heading uses Caribbean font per your instructions
                    .font(Font.custom("Caribbean", size: 26))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Rules body
                Text(rulesText)
                    .font(Font.custom("Caribbean", size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .padding(8)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(10)

                // Quick actions
                HStack {
                    Spacer()
                    Button(action: {
                        // Dismiss view and return to Home
                        dismiss()
                    }) {
                        Text("Done")
                            // Button labels use Norse font
                            .font(Font.custom("Norse", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .padding(16)
        }
        .navigationTitle("Game Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GameRules()
    }
}