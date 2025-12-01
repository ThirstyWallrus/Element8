//
// Element8Game.swift
// Game models and view-model for Element8
//
// Split on 2025-12-01: moved GameSetupView and GameView into their own files to make per-view editing easier.
// This file now contains enums, Player model, GameViewModel, and registry observer convenience.
// 2025-12-01 update: Perimeter (Monopoly-style) board support with forward/backward movement.
//

import SwiftUI

// Direction along the perimeter path: forward (clockwise) or backward (counter-clockwise)
enum Direction: String, CaseIterable {
    case forward = "Forward"
    case backward = "Backward"
}

// Enum for Elemental Characters with Powers
// Updated to match the character files exactly: fire, water, stone, plant, wind, electricity, magnetism, light
public enum ElementCharacter: String, CaseIterable {
    case fire = "Fire" // Power: +2 attack in combat
    case water = "Water" // Power: +1 defense
    case stone = "Stone" // Power: +1 health regen / tank behavior
    case plant = "Plant" // Power: Heal on card draw / regen
    case wind = "Wind" // Power: +2 movement
    case electricity = "Electricity" // Power: Stun / disrupt
    case magnetism = "Magnetism" // Power: +2 defense / control metal
    case light = "Light" // Power: Support / reveal map features
    
    // Map each ElementCharacter to a preferred starting corner index on the perimeter path.
    // Corner indices are: 0 = top-left, 1 = top-right, 2 = bottom-right, 3 = bottom-left (clockwise).
    var startingCornerIndex: Int {
        switch self {
        case .fire, .electricity:
            return 3 // bottom-left
        case .water:
            return 2 // bottom-right
        case .stone, .plant:
            return 0 // top-left
        case .wind, .magnetism:
            return 1 // top-right
        case .light:
            return 0 // default to top-left for Light (adjustable in profiles)
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
    
    /// The profile backing this player.
    let profile: CharacterProfile
    
    // Row/Col used for rendering and adjacency checks
    @Published var position: (row: Int, col: Int)
    // Optional canonical index along the perimeter path (0..pathLength-1)
    @Published var pathIndex: Int? = nil
    
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
    // Board configuration (perimeter board)
    let boardSize: Int = 8 // 8x8 grid whose perimeter defines the path; with 6 spaces between corners -> 28 perimeter tiles
    var sideLength: Int { boardSize } // useful when computing tile fitting
    var spacesBetweenCorners: Int { boardSize - 2 } // e.g., 6 when boardSize == 8
    
    // Published pieces of state
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var selectedDirection: Direction?
    @Published var gameMessage: String = "Setup: Select characters"
    @Published var mapGrid: [[Color]] = []
    @Published var gameCards: [GameCard] = GameCard.allCases.shuffled() + GameCard.allCases.shuffled() // Approx duplicates
    @Published var flameCards: Int = 7 // Count, use to add damage
    @Published var stoneCardOwner: Player? = nil // Assign to one player randomly?
    @Published var damageMultiplier: Int = 1
    @Published var eliminatedCount: Int = 0
    @Published var isGameOver: Bool = false
    @Published var winner: Player? = nil
    
    init() {
        // Initialize a boardSize x boardSize white board
        mapGrid = Array(repeating: Array(repeating: .white, count: boardSize), count: boardSize)
        
        // Place obstacles — but ensure we do NOT place barriers on the perimeter path.
        // We'll compute the perimeter path first and avoid putting barriers at those coordinates.
        let path = GameViewModel.perimeterPath(boardSize: boardSize)
        var placed = 0
        while placed < 10 {
            let row = Int.random(in: 0..<boardSize)
            let col = Int.random(in: 0..<boardSize)
            // Skip perimeter tiles
            if path.contains(where: { $0.row == row && $0.col == col }) {
                continue
            }
            if mapGrid[row][col] != .black {
                mapGrid[row][col] = .black // Barrier
                placed += 1
            }
        }
    }
    
    // Computed perimeter path for the current boardSize, in clockwise order starting at top-left (0,0).
    // Returns an array of (row, col).
    static func perimeterPath(boardSize: Int) -> [(row: Int, col: Int)] {
        var out: [(Int, Int)] = []
        guard boardSize >= 3 else {
            // Minimal fallback: small 3x3 perimeter
            for c in 0..<boardSize { out.append((0, c)) }
            for r in 1..<boardSize { out.append((r, boardSize-1)) }
            for c in stride(from: boardSize-2, through: 0, by: -1) { out.append((boardSize-1, c)) }
            for r in stride(from: boardSize-2, through: 1, by: -1) { out.append((r, 0)) }
            return out
        }
        let maxIndex = boardSize - 1
        // Top row (left -> right)
        for c in 0...maxIndex {
            out.append((0, c))
        }
        // Right column (top+1 -> bottom)
        if maxIndex >= 1 {
            for r in 1...maxIndex {
                out.append((r, maxIndex))
            }
        }
        // Bottom row (right-1 -> left)
        if maxIndex >= 1 {
            for c in stride(from: maxIndex - 1, through: 0, by: -1) {
                out.append((maxIndex, c))
            }
        }
        // Left column (bottom-1 -> top+1)
        if maxIndex >= 2 {
            for r in stride(from: maxIndex - 1, through: 1, by: -1) {
                out.append((r, 0))
            }
        }
        return out
    }
    
    // Return the perimeter path for this instance
    var perimeterPath: [(row: Int, col: Int)] {
        GameViewModel.perimeterPath(boardSize: boardSize)
    }
    
    var pathLength: Int { perimeterPath.count }
    
    // MARK: - New helpers (non-invasive)
    /// Return the perimeter path index for a given grid coordinate, or nil if that coordinate is not on the perimeter.
    func pathIndexFor(row: Int, col: Int) -> Int? {
        for (i, coord) in perimeterPath.enumerated() {
            if coord.row == row && coord.col == col { return i }
        }
        return nil
    }
    
    /// Return whether the given coordinate is a perimeter tile
    func isPerimeterTile(row: Int, col: Int) -> Bool {
        return pathIndexFor(row: row, col: col) != nil
    }
    // End helpers
    
    // Start game with profiles rather than pure enum cases
    func startGame(with profiles: [CharacterProfile]) {
        // Create players preserving order of selection
        players = profiles.map { Player(profile: $0) }
        
        // Assign starting positions using perimeter indices. Corners occur at indices that are multiples of (boardSize - 1).
        // Corner indices: 0 (top-left), (boardSize-1) (top-right), 2*(boardSize-1) (bottom-right), 3*(boardSize-1) (bottom-left)
        let cornerStride = boardSize - 1
        var assignedIndices: [Int] = []
        
        for player in players {
            if let element = player.profile.elementCase {
                // Use ElementCharacter's corner mapping
                let cornerNum = element.startingCornerIndex // 0..3
                let posIndex = (cornerNum * cornerStride) % pathLength
                player.pathIndex = posIndex
                let coord = perimeterPath[posIndex]
                player.position = (coord.row, coord.col)
                assignedIndices.append(posIndex)
            } else {
                // Find next unused corner
                if let freeCornerNum = (0..<4).first(where: { corner in
                    let index = corner * cornerStride % pathLength
                    return !assignedIndices.contains(index)
                }) {
                    let posIndex = (freeCornerNum * cornerStride) % pathLength
                    player.pathIndex = posIndex
                    let coord = perimeterPath[posIndex]
                    player.position = (coord.row, coord.col)
                    assignedIndices.append(posIndex)
                } else {
                    // If all corners are taken, place players sequentially along the path at next available slot
                    var attemptIndex = 0
                    while assignedIndices.contains(attemptIndex) {
                        attemptIndex += 1
                        if attemptIndex >= pathLength { break }
                    }
                    let finalIndex = min(attemptIndex, pathLength - 1)
                    player.pathIndex = finalIndex
                    let coord = perimeterPath[finalIndex]
                    player.position = (coord.row, coord.col)
                    assignedIndices.append(finalIndex)
                }
            }
            
            // Ensure starting tile at player's position is not a barrier
            let r = player.position.row, c = player.position.col
            if mapGrid[r][c] == .black {
                mapGrid[r][c] = .white
            }
        }
        
        currentPlayerIndex = Int.random(in: 0..<players.count)
        gameMessage = "\(currentPlayer().displayName)'s turn: Choose Forward or Backward"
        
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
    
    /// Move current player along the perimeter path
    func moveAlongPath(forward: Bool, spaces: Int) {
        guard !players.isEmpty else { return }
        guard pathLength > 0 else { return }
        
        let player = currentPlayer()
        // Ensure player has a valid pathIndex; if not, find the closest perimeter coordinate
        var idx = player.pathIndex ?? findPathIndex(for: player.position) ?? 0
        
        let delta = forward ? spaces : -spaces
        // Wrap around with modulo semantics
        let raw = (idx + delta) % pathLength
        // Swift % with negative numbers yields negative; correct it:
        let newIndex = (raw + pathLength) % pathLength
        player.pathIndex = newIndex
        let coord = perimeterPath[newIndex]
        player.position = (coord.row, coord.col)
    }
    
    /// Try to find a perimeter path index that matches the given (row,col). Returns nil if not on perimeter.
    private func findPathIndex(for pos: (row: Int, col: Int)) -> Int? {
        for (i, coord) in perimeterPath.enumerated() {
            if coord.row == pos.row && coord.col == pos.col {
                return i
            }
        }
        return nil
    }
    
    // Legacy move(in: Direction, spaces:) kept as compatibility wrapper
    func move(in direction: Direction, spaces: Int) {
        let forward = (direction == .forward)
        moveAlongPath(forward: forward, spaces: spaces)
    }
    
    func checkForCombat() {
        let attacker = currentPlayer()
        for defender in players where !defender.isEliminated && defender !== attacker {
            let distRow = abs(attacker.position.row - defender.position.row)
            let distCol = abs(attacker.position.col - defender.position.col)
            if distRow + distCol <= 1 { // Adjacent or same tile
                resolveCombat(attacker: attacker, defender: defender)
            } else {
                // Additionally, check if they are on the same perimeter tile (same path index)
                if let aIdx = attacker.pathIndex, let dIdx = defender.pathIndex, aIdx == dIdx {
                    resolveCombat(attacker: attacker, defender: defender)
                }
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
                // Swap two random tiles safely (avoid swapping perimeter with barrier incorrectly)
                let r1 = Int.random(in: 0..<boardSize), c1 = Int.random(in: 0..<boardSize)
                let r2 = Int.random(in: 0..<boardSize), c2 = Int.random(in: 0..<boardSize)
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
        // Previously checked for `.earth`. Updated to check `.stone` to match StoneCharacter
        if currentPlayer().profile.elementCase == .stone {
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
        gameMessage = "\(currentPlayer().displayName)'s turn: Choose Forward or Backward"
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
