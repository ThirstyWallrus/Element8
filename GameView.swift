//
//  GameView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/1/25.
//


//
// GameView.swift
// Separated from Element8Game.swift on 2025-12-01 so the main game view can be edited independently.
//
// This view depends on GameViewModel, Player, Direction, and CharacterRegistry which live in Element8Game.swift.
//

import SwiftUI

// Main Game View (accepts CharacterProfile array)
struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var rollResult: Int?
    private let profiles: [CharacterProfile]
    
    init(profiles: [CharacterProfile]) {
        self.profiles = profiles
    }
    
    var body: some View {
        VStack {
            ScrollView {
                Text(viewModel.gameMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Map Grid — you can replace this with BoardView(viewModel: viewModel)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 2) {
                ForEach(0..<10, id: \.self) { row in
                    ForEach(0..<10, id: \.self) { col in
                        ZStack {
                            Rectangle()
                                .fill(viewModel.mapGrid[row][col])
                                .frame(height: 30)
                                .border(Color.black.opacity(0.08), width: 0.25)
                            
                            // Show player(s) on this tile — show first non-eliminated player found
                            if let player = viewModel.players.first(where: { !$0.isEliminated && $0.position.row == row && $0.position.col == col }) {
                                Circle()
                                    .fill(player.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text(String(player.displayName.prefix(1)))
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                }
            }
            .padding()
            
            // Direction Selection
            if !viewModel.isGameOver && viewModel.selectedDirection == nil {
                HStack(spacing: 10) {
                    ForEach(Direction.allCases, id: \.self) { dir in
                        Button(action: {
                            viewModel.selectedDirection = dir
                            let roll = viewModel.rollDice()
                            rollResult = roll
                            viewModel.move(in: dir, spaces: roll)
                            viewModel.checkForCombat()
                            // Optional draw card
                            if Bool.random() {
                                viewModel.drawGameCard()
                            }
                            viewModel.endTurn()
                        }) {
                            Text(dir.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(minWidth: 64)
                                .background(Color.blue.opacity(0.85))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.bottom, 6)
            } else if viewModel.isGameOver {
                Text(viewModel.winner?.displayName ?? "Game Over")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding(.bottom, 6)
            }
            
            if let roll = rollResult {
                Text("Rolled: \(roll)")
                    .padding(.bottom, 8)
            }
            
            // Player Status
            List {
                ForEach(viewModel.players) { player in
                    HStack {
                        Text(player.displayName)
                            .foregroundColor(player.color)
                            .bold()
                        Spacer()
                        Text("HP: \(player.health)")
                            .foregroundColor(.primary)
                        if player.isEliminated {
                            Text("Eliminated")
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .frame(maxHeight: 220)
        }
        .onAppear {
            // Only start the game when the view appears and when players are not yet initialized
            if viewModel.players.isEmpty {
                // Guard that profiles array has at least 2 entries; otherwise set defaults
                let profilesToUse = profiles.isEmpty ? [CharacterRegistry.shared.profile(forKey: "fire") ?? CharacterProfile(key: "fire", displayName: "Fire", description: "Default Fire", baseHealth: 10, color: .red, elementCase: .fire, attackModifier: 2)] : profiles
                viewModel.startGame(with: profilesToUse)
            }
        }
        .navigationTitle("Element 8 - Game")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview for GameView
#if DEBUG
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            // Build sample profiles for preview
            let pFire = CharacterProfile(key: "fire", displayName: "Fire", description: "Fierce attacker", baseHealth: 12, color: .red, elementCase: .fire, attackModifier: 2)
            let pWater = CharacterProfile(key: "water", displayName: "Water", description: "Defensive", baseHealth: 11, color: .blue, elementCase: .water, defenseModifier: 1)
            GameView(profiles: [pFire, pWater])
        }
    }
}
#endif