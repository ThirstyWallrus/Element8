//
// Element8Game.swift
// Game models and view-model for Element8
//
// Split on 2025-12-01: moved GameSetupView and GameView into their own files to make per-view editing easier.
// This file now contains enums, Player model, GameViewModel, and registry observer convenience.
//

import SwiftUI

// Enum for Directions
enum Direction: String, CaseIterable {
    case north = "North"
    case south = "South"
    case east = "East"
    case west = "West"
    
    func offset() -> (row: Int, col: Int) {
        switch self {
        case .north: return (-1, 0)
        case .south: return (1, 0)
        case .east: return (0, 1)
        case .west: return (0, -1)
        }
    }
}

// Enum for Elemental Characters with Powers (kept for compatibility; profiles can map to these)
// MADE PUBLIC to match the public CharacterProfile that references it.
public enum ElementCharacter: String, CaseIterable {
    case fire = "Fire" // Power: +2 attack in combat
    case water = "Water" // Power: +1 defense
    case earth = "Earth" // Power: +1 health regen per turn
    case wind = "Wind" // Power: +2 movement
    case lightning = "Lightning" // Power: Stun chance (skip enemy turn)
    case ice = "Ice" // Power: Freeze (reduce enemy movement)
    case metal = "Metal" // Power: +2 defense
    case wood = "Wood" // Power: Heal on card draw
    
    func offset() -> (row: Int, col: Int) {
        // not used here, but kept for compatibility if needed
        (0, 0)
    }
    
    var startingPosition: (row: Int, col: Int) {
        // Assume corners: Bottom-left, bottom-right, top-left, top-right
        // Paired: Fire/Lightning bottom-left, Water/Ice bottom-right, Earth/Wood top-left, Wind/Metal top-right
        switch self {
        case .fire, .lightning: return (9, 0)
        case .water, .ice: return (9, 9)
        case .earth, .wood: return (0, 0)
        case .wind, .metal: return (0, 9)
        }
    }
}

// Game Card Enum (Simplified)
enum GameCard: String, CaseIterable {
    case shiftMap = "Shift Map" // Swap two positions
    case heal = "Heal +2"
    case buffAttack = "Attack +1"
    // Add more types as desired
}

// Player Model (profile-driven)
class Player: Identifiable, ObservableObject {
    let id = UUID()
    
    /// The profile backing this player. This is the canonical source of display name,
    /// color, base health, and per-profile modifiers.
    let profile: CharacterProfile
    
    @Published var position: (row: Int, col: Int)
    @Published var health: Int
    @Published var isEliminated: Bool = false
    @Published var emblems: [String] = [] // e.g., "square", "triangle"
    
    init(profile: CharacterProfile, initialPosition: (Int, Int) = (0,0)) {
        self.profile = profile
        self.position = initialPosition
        self.health = profile.baseHealth
    }
    
    // Convenience properties to reduce refactor friction:
    var displayName: String { profile.displayName }
    var color: Color { profile.color }
    var movementModifier: Int { profile.movementModifier }
    var attackModifier: Int { profile.attackModifier }
    var defenseModifier: Int { profile.defenseModifier }
    var healModifier: Int { profile.healModifier }
}

// Game State ViewModel (profile-driven)
@MainActor class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var selectedDirection: Direction?
    @Published var gameMessage: String = "Setup: Select characters"
    @Published var mapGrid: [[Color]] = Array(repeating: Array(repeating: .white, count: 10), count: 10) // Simple grid, white = open
    @Published var gameCards: [GameCard] = GameCard.allCases.shuffled() + GameCard.allCases.shuffled() // Approx duplicates
    @Published var flameCards: Int = 7 // Count, use to add damage
    @Published var stoneCardOwner: Player? = nil // Assign to one player randomly?
    @Published var damageMultiplier: Int = 1
    @Published var eliminatedCount: Int = 0
    @Published var isGameOver: Bool = false
    @Published var winner: Player? = nil
    
    init() {
        // Add obstacles to map (random barriers), but avoid placing barriers on corner starting positions
        // We don't yet know players; startGame will ensure clearing start tiles.
        var placed = 0
        while placed < 10 {
            let row = Int.random(in: 0..<10)
            let col = Int.random(in: 0..<10)
            if mapGrid[row][col] != .black {
                mapGrid[row][col] = .black // Barrier
                placed += 1
            }
        }
    }
    
    // Start game with profiles rather than pure enum cases
    func startGame(with profiles: [CharacterProfile]) {
        // Create players preserving order of selection
        players = profiles.map { Player(profile: $0) }
        
        // Assign starting positions:
        // If profile.elementCase exists, use its canonical starting position.
        // Otherwise assign available corner positions and then fallback positions.
        let corners: [(Int, Int)] = [
            (9, 0), // bottom-left
            (9, 9), // bottom-right
            (0, 0), // top-left
            (0, 9)  // top-right
        ]
        var assignedPositions: [(Int, Int)] = []
        
        for player in players {
            if let mapped = player.profile.elementCase {
                // Use ElementCharacter startingPosition if available
                let pos = mapped.startingPosition
                player.position = pos
                assignedPositions.append(pos)
            } else {
                // Find the next unused corner in a type-safe way.
                if let freeCorner = corners.first(where: { corner in
                    // check assignedPositions does NOT already contain this corner
                    !assignedPositions.contains(where: { $0 == corner })
                }) {
                    player.position = freeCorner
                    assignedPositions.append(freeCorner)
                } else {
                    // All corners taken — place near center at a pseudo-random offset
                    player.position = (Int.random(in: 3..<7), Int.random(in: 3..<7))
                }
            }
            
            // Ensure starting tile is not a barrier
            let r = player.position.row, c = player.position.col
            if mapGrid[r][c] == .black {
                mapGrid[r][c] = .white
            }
        }
        
        // If somehow positions still coincide in a way we dislike, we leave them — the engine supports multiple players on a tile.
        currentPlayerIndex = Int.random(in: 0..<players.count)
        gameMessage = "\(currentPlayer().displayName)'s turn: Choose direction"
        
        // Assign stone card randomly
        stoneCardOwner = players.randomElement()
    }
    
    func currentPlayer() -> Player {
        players[currentPlayerIndex]
    }
    
    func rollDice() -> Int {
        let roll = Int.random(in: 1...6)
        return roll + currentPlayer().movementModifier
    }
    
    func move(in direction: Direction, spaces: Int) {
        var newRow = currentPlayer().position.row
        var newCol = currentPlayer().position.col
        let offset = direction.offset()
        
        for _ in 0..<spaces {
            let tempRow = newRow + offset.row
            let tempCol = newCol + offset.col
            if tempRow >= 0 && tempRow < 10 && tempCol >= 0 && tempCol < 10 && mapGrid[tempRow][tempCol] != .black {
                newRow = tempRow
                newCol = tempCol
            } else {
                break // Hit barrier or edge
            }
        }
        currentPlayer().position = (newRow, newCol)
    }
    
    func checkForCombat() {
        let attacker = currentPlayer()
        for defender in players where !defender.isEliminated && defender !== attacker {
            let distRow = abs(attacker.position.row - defender.position.row)
            let distCol = abs(attacker.position.col - defender.position.col)
            if distRow + distCol <= 1 { // Adjacent or same
                resolveCombat(attacker: attacker, defender: defender)
            }
        }
    }
    
    func resolveCombat(attacker: Player, defender: Player) {
        let attackRoll = Int.random(in: 1...6) + attacker.attackModifier
        let defenseRoll = Int.random(in: 1...6) + defender.defenseModifier
        
        gameMessage += "\nCombat: \(attacker.displayName) vs \(defender.displayName)"
        
        if attackRoll > defenseRoll {
            var damage = (attackRoll - defenseRoll) + damageMultiplier
            if flameCards > 0 && Bool.random() { // Simulate using flame
                damage += 1
                flameCards -= 1
            }
            if defender === stoneCardOwner && Bool.random() { // Use stone to block
                damage = 0
                stoneCardOwner = nil
                gameMessage += "\nStone Card blocked!"
            }
            defender.health -= damage
            gameMessage += "\n\(defender.displayName) takes \(damage) damage"
            if defender.health <= 0 {
                defender.isEliminated = true
                eliminatedCount += 1
                damageMultiplier += 1
                gameMessage += "\n\(defender.displayName) eliminated!"
                checkForWin()
            }
        } else {
            gameMessage += "\nAttack was defended."
        }
    }
    
    func drawGameCard() {
        if let card = gameCards.popLast() {
            // Apply effect (simplified)
            switch card {
            case .heal:
                currentPlayer().health += 2 + currentPlayer().healModifier
            case .buffAttack:
                // Temporary buff — left as no-op in this simplified build
                break
            case .shiftMap:
                // Swap two random tiles safely
                let r1 = Int.random(in: 0..<10), c1 = Int.random(in: 0..<10)
                let r2 = Int.random(in: 0..<10), c2 = Int.random(in: 0..<10)
                let temp = mapGrid[r1][c1]
                mapGrid[r1][c1] = mapGrid[r2][c2]
                mapGrid[r2][c2] = temp
            }
            gameMessage += "\nDrew: \(card.rawValue)"
        } else {
            gameMessage += "\nNo more cards."
        }
    }
    
    func endTurn() {
        // Optional: Heal or other powers
        if currentPlayer().profile.elementCase == .earth {
            currentPlayer().health += currentPlayer().healModifier
        }
        // Next player
        if players.allSatisfy({ $0.isEliminated }) {
            isGameOver = true
            gameMessage += "\nAll players eliminated."
            return
        }
        repeat {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        } while currentPlayer().isEliminated
        selectedDirection = nil
        gameMessage = "\(currentPlayer().displayName)'s turn: Choose direction"
        // Random map shift (10% chance)
        if Double.random(in: 0...1) < 0.1 {
            drawGameCard() // Simulate shift via card
        }
    }
    
    func checkForWin() {
        let activePlayers = players.filter { !$0.isEliminated }
        if activePlayers.count == 1 {
            isGameOver = true
            winner = activePlayers.first
            gameMessage = "\(winner!.displayName) wins!"
        }
    }
}

// A small convenience to observe registry updates in UI (CharacterRegistry is value-backed)
extension CharacterRegistry {
    // Provide a lightweight ObservableObject wrapper to notify views when registry changes
    static var sharedObserver: CharacterRegistryObserver {
        CharacterRegistryObserver.shared
    }
}

final class CharacterRegistryObserver: ObservableObject {
    static let shared = CharacterRegistryObserver()
    @Published var tick: Int = 0
    private init() {
        // Intentionally minimal — consumers will call CharacterRegistry.shared when needed.
        // If you want live push updates for registry changes, register notifications here.
    }
}
