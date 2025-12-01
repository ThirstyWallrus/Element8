
// Element8Game.swift
// Game model, setup view, and game view for Element8
//
// Added on 2025-12-01 to integrate the Elemental board game screens.
// This file contains Views and ViewModel only — it does NOT declare a new @main App,
// so it is safe to add to the existing app and will inherit the global Sepia background
// defined in Element8App.swift.
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

// Enum for Elemental Characters with Powers
enum ElementCharacter: String, CaseIterable {
    case fire = "Fire" // Power: +2 attack in combat
    case water = "Water" // Power: +1 defense
    case earth = "Earth" // Power: +1 health regen per turn
    case wind = "Wind" // Power: +2 movement
    case lightning = "Lightning" // Power: Stun chance (skip enemy turn)
    case ice = "Ice" // Power: Freeze (reduce enemy movement)
    case metal = "Metal" // Power: +2 defense
    case wood = "Wood" // Power: Heal on card draw
    
    var color: Color {
        switch self {
        case .fire: return .red
        case .water: return .blue
        case .earth: return .green
        case .wind: return .cyan
        case .lightning: return .yellow
        case .ice: return .mint
        case .metal: return .gray
        case .wood: return .brown
        }
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
    
    func powerModifier(for type: PowerType) -> Int {
        switch type {
        case .movement:
            return self == .wind ? 2 : 0
        case .attack:
            return self == .fire ? 2 : 0
        case .defense:
            return (self == .water || self == .metal) ? 1 : 0
        case .heal:
            return self == .wood ? 1 : 0
        }
    }
}

enum PowerType {
    case movement, attack, defense, heal
}

// Game Card Enum (Simplified)
enum GameCard: String, CaseIterable {
    case shiftMap = "Shift Map" // Swap two positions
    case heal = "Heal +2"
    case buffAttack = "Attack +1"
    // Add more types as desired
}

// Player Model
class Player: Identifiable, ObservableObject {
    let id = UUID()
    let character: ElementCharacter
    @Published var position: (row: Int, col: Int)
    @Published var health: Int = 10
    @Published var isEliminated: Bool = false
    @Published var emblems: [String] = [] // e.g., "square", "triangle"
    
    init(character: ElementCharacter) {
        self.character = character
        self.position = character.startingPosition
    }
}

// Game State ViewModel
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
        var placed = 0
        while placed < 10 {
            let row = Int.random(in: 0..<10)
            let col = Int.random(in: 0..<10)
            // Skip if it is a starting corner
            let isStartingCorner = [
                (9, 0), (9, 9), (0, 0), (0, 9)
            ].contains { $0 == (row, col) }
            if !isStartingCorner && mapGrid[row][col] != .black {
                mapGrid[row][col] = .black // Barrier
                placed += 1
            }
        }
    }
    
    func startGame(with characters: [ElementCharacter]) {
        players = characters.map { Player(character: $0) }
        // Ensure players' starting positions are not barriers
        for p in players {
            let r = p.position.row, c = p.position.col
            if mapGrid[r][c] == .black {
                mapGrid[r][c] = .white
            }
        }
        currentPlayerIndex = Int.random(in: 0..<players.count)
        gameMessage = "\(currentPlayer().character.rawValue)'s turn: Choose direction"
        // Assign stone card randomly
        stoneCardOwner = players.randomElement()
    }
    
    func currentPlayer() -> Player {
        players[currentPlayerIndex]
    }
    
    func rollDice() -> Int {
        let roll = Int.random(in: 1...6)
        return roll + currentPlayer().character.powerModifier(for: .movement)
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
        let attackRoll = Int.random(in: 1...6) + attacker.character.powerModifier(for: .attack)
        let defenseRoll = Int.random(in: 1...6) + defender.character.powerModifier(for: .defense)
        
        gameMessage += "\nCombat: \(attacker.character.rawValue) vs \(defender.character.rawValue)"
        
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
            gameMessage += "\n\(defender.character.rawValue) takes \(damage) damage"
            if defender.health <= 0 {
                defender.isEliminated = true
                eliminatedCount += 1
                damageMultiplier += 1
                gameMessage += "\n\(defender.character.rawValue) eliminated!"
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
                currentPlayer().health += 2 + currentPlayer().character.powerModifier(for: .heal)
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
        if currentPlayer().character == .earth {
            currentPlayer().health += currentPlayer().character.powerModifier(for: .heal)
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
        gameMessage = "\(currentPlayer().character.rawValue)'s turn: Choose direction"
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
            gameMessage = "\(winner!.character.rawValue) wins!"
        }
    }
}

// Setup View to Select Characters
struct GameSetupView: View {
    @State private var selectedCharacters: [ElementCharacter] = []
    @State private var navigateToGame: Bool = false
    
    var body: some View {
        VStack {
            Text("Select 2-8 Characters")
                .font(.title)
                .padding(.top, 20)
            
            List(ElementCharacter.allCases, id: \.self) { char in
                Button(action: {
                    if selectedCharacters.contains(char) {
                        selectedCharacters.removeAll { $0 == char }
                    } else if selectedCharacters.count < 8 {
                        selectedCharacters.append(char)
                    }
                }) {
                    HStack {
                        Text(char.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCharacters.contains(char) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(char.color)
                        }
                    }
                }
            }
            
            Spacer()
            
            NavigationLink(destination: GameView(characters: selectedCharacters), isActive: $navigateToGame) {
                EmptyView()
            }
            
            Button(action: {
                if selectedCharacters.count >= 2 {
                    navigateToGame = true
                }
            }) {
                Text("Start Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Play")
    }
}

// Main Game View
struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var rollResult: Int?
    private let characters: [ElementCharacter]
    
    init(characters: [ElementCharacter]) {
        self.characters = characters
        // StateObject is initialized above; we'll call startGame in onAppear
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
            
            // Map Grid
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
                                    .fill(player.character.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text(String(player.character.rawValue.prefix(1)))
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
                Text(viewModel.winner?.character.rawValue ?? "Game Over")
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
                        Text(player.character.rawValue)
                            .foregroundColor(player.character.color)
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
                // Guard that characters array has at least 2 entries; otherwise set defaults
                let charsToUse = characters.isEmpty ? [ElementCharacter.fire, ElementCharacter.water] : characters
                viewModel.startGame(with: charsToUse)
            }
        }
        .navigationTitle("Element 8 - Game")
        .navigationBarTitleDisplayMode(.inline)
    }
}
