//
//  GameView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/2/25.
//
//
//  - Switched to BoardView for map rendering.
//  - Added on-screen live dice rolling overlay (DieView).
//  - Ensures the entire board is visible while rolling by computing tile height to fit the available board area.
//  - Disables input while rolling and animates the die with randomized faces and rotation.
//  - 2025-12-01 update: Forward/Backward movement on perimeter path (Monopoly-style).
//

import SwiftUI

// Main Game View (accepts CharacterProfile array)
struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var rollResult: Int?
    @State private var isRolling: Bool = false
    @State private var showDie: Bool = false
    @State private var dieFace: Int = 1
    @State private var dieRotation: Double = 0
    @State private var dieScale: CGFloat = 1.0
    @State private var navigateAfterRoll: Bool = false
    
    private let profiles: [CharacterProfile]
    
    init(profiles: [CharacterProfile]) {
        self.profiles = profiles
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Top: game message
            ScrollView(.vertical, showsIndicators: false) {
                Text(viewModel.gameMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            .frame(minHeight: 44, maxHeight: 88)
            
            // Board area — we use GeometryReader to compute tile size so we can
            // guarantee the whole board is visible during rolls.
            GeometryReader { geo in
                ZStack {
                    // Compute tile size that fits the available geometry.
                    // We subtract a little padding to avoid hugging system edges.
                    let padding: CGFloat = 24
                    let availWidth = max(geo.size.width - padding, 10)
                    let availHeight = max(geo.size.height - padding, 10)
                    // Number of cells per row/col is based on the viewModel's mapGrid
                    let gridCount = CGFloat(viewModel.mapGrid.count)
                    // Tile size that fits the full perimeter grid inside available area.
                    let tileSizeToFit = min(availWidth / gridCount, availHeight / gridCount)
                    // Normal tile size: keep tiles reasonably large but never exceed the fit size.
                    let normalTileSize = min(44, tileSizeToFit)
                    // When rolling, force the tile size to the fit size so the entire board is visible.
                    let tileHeight = isRolling ? tileSizeToFit : normalTileSize
                    
                    // BoardView handles rendering and player display.
                    BoardView(viewModel: viewModel,
                              tileHeight: tileHeight,
                              showsGridLines: true,
                              onTileTap: { r, c in
                                  // Small convenience: show tile info in message
                                  viewModel.gameMessage = "Tile tapped: \(r),\(c)"
                              })
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                        .animation(.easeInOut(duration: 0.18), value: tileHeight)
                        .disabled(isRolling) // disable interactions of the board while rolling
                    
                    // Die overlay: appears centered over the board while rolling
                    if showDie {
                        DieView(face: dieFace)
                            .frame(width: 96, height: 96)
                            .rotation3DEffect(.degrees(dieRotation), axis: (x: 1, y: 1, z: 0))
                            .scaleEffect(dieScale)
                            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 6)
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(1)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(minHeight: 320, maxHeight: 520)
            .padding(.horizontal, 8)
            
            // Controls — forward/backward buttons (perimeter movement)
            if !viewModel.isGameOver {
                HStack(spacing: 10) {
                    ForEach(Direction.allCases, id: \.self) { dir in
                        Button(action: {
                            // Start the animated dice roll sequence on tap.
                            Task {
                                await performLiveRoll(direction: dir)
                            }
                        }) {
                            Text(dir.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .frame(minWidth: 64)
                                .background(Color.blue.opacity(0.85))
                                .cornerRadius(8)
                        }
                        .disabled(isRolling || viewModel.selectedDirection != nil || viewModel.players.isEmpty)
                        .opacity((isRolling || viewModel.selectedDirection != nil || viewModel.players.isEmpty) ? 0.6 : 1.0)
                    }
                }
                .padding(.bottom, 6)
            } else {
                // Game over banner
                Text(viewModel.winner?.displayName ?? "Game Over")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding(.bottom, 6)
            }
            
            // Show the raw roll result (movement spaces including modifiers)
            if let roll = rollResult {
                Text("Moved \(roll) spaces")
                    .padding(.bottom, 4)
            }
            
            // Player status list
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
                let profilesToUse = profiles.isEmpty ? [
                    CharacterRegistry.shared.profile(forKey: "fire")
                    ?? CharacterProfile(key: "fire", displayName: "Fire", description: "Default Fire", baseHealth: 10, color: .red, elementCase: .fire, attackModifier: 2)
                ] : profiles
                viewModel.startGame(with: profilesToUse)
            }
        }
        .navigationTitle("Element 8 - Game")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Dice Animation & Game Sequence
    
    /// Performs a live dice roll animation and then applies the game effects (movement, combat, card draw, end turn).
    private func performLiveRoll(direction: Direction) async {
        guard !isRolling, !viewModel.isGameOver, !viewModel.players.isEmpty else { return }
        isRolling = true
        showDie = true
        dieRotation = 0
        dieScale = 1.0
        
        // Animate dice: quickly change faces and rotate/scale for the "live" effect.
        // We'll run a short series of random updates.
        let updates = 12
        for i in 0..<updates {
            // Random face and small rotation tweak
            await MainActor.run {
                dieFace = Int.random(in: 1...6)
                dieRotation += Double(Int.random(in: 30...120))
                // subtle scale bounce on alternating iterations
                dieScale = (i % 2 == 0) ? 1.06 : 0.94
            }
            try? await Task.sleep(nanoseconds: UInt64(80_000_000)) // 80ms
        }
        
        // Final face
        let finalFace = Int.random(in: 1...6)
        await MainActor.run {
            dieFace = finalFace
            dieRotation += 180
            dieScale = 1.12
        }
        try? await Task.sleep(nanoseconds: 220_000_000) // pause to show final
        
        // Compute movement using player's movement modifier (we don't call viewModel.rollDice to keep displayed face consistent)
        let raw = finalFace
        let movementModifier = viewModel.currentPlayer().movementModifier
        let totalSpaces = raw + movementModifier
        
        // Apply movement and game logic on main actor
        await MainActor.run {
            // Update visual reported roll and selected direction
            rollResult = totalSpaces
            viewModel.selectedDirection = direction
            // Move along perimeter
            viewModel.move(in: direction, spaces: totalSpaces)
            viewModel.checkForCombat()
            // Optional draw card (existing random chance logic kept from previous implementation)
            if Bool.random() {
                viewModel.drawGameCard()
            }
            viewModel.endTurn()
        }
        
        // Hide die and re-enable input (animate out)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.28)) {
                dieScale = 0.8
                dieRotation += 60
                showDie = false
            }
        }
        // Small delay to let animation finish before clearing roll state
        try? await Task.sleep(nanoseconds: 160_000_000)
        await MainActor.run {
            isRolling = false
            // clear selectedDirection (game loop expects this)
            viewModel.selectedDirection = nil
        }
    }
}

// MARK: - DieView: simple stylized die face to show on-screen
fileprivate struct DieView: View {
    let face: Int // 1..6
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color(white: 0.92)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            
            // Numeric face with subtle emboss
            Text("\(face)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .shadow(color: Color.white.opacity(0.6), radius: 0.6, x: -0.5, y: -0.5)
                .shadow(color: Color.black.opacity(0.18), radius: 2, x: 1, y: 2)
        }
    }
}

// MARK: - Preview

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
