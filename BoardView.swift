
//  Element8BoardView.swift
//  Element8
//
//  Created by Copilot on 2025-12-01.
//  Purpose: Reusable board view for the Element8 game.
//  This view is compatible with GameViewModel defined in Element8Game.swift.
//  Add this file to the project and optionally replace inline map rendering
//  in GameView with BoardView(viewModel: viewModel).
//

import SwiftUI

/// A reusable board view that renders a 2D tile map from GameViewModel.mapGrid,
/// shows players on tiles, optionally handles tile taps, and supports light customization.
struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel
    
    /// Fixed tile height if provided; otherwise falls back to a sensible default (30).
    var tileHeight: CGFloat? = 30
    
    /// When true, draws a subtle border between tiles.
    var showsGridLines: Bool = true
    
    /// Optional callback that is invoked when a tile is tapped with (row, col).
    var onTileTap: ((Int, Int) -> Void)? = nil
    
    /// Maximum number of small player dots to show inside a tile.
    /// If there are more players than this, a numeric badge is shown instead.
    var maxPlayerDots: Int = 3
    
    var body: some View {
        // Guard for irregular grids; we assume rectangular grid
        let rowCount = viewModel.mapGrid.count
        let colCount = viewModel.mapGrid.first?.count ?? 0
        
        // Use LazyVGrid with flexible columns so it scales with container width.
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: colCount), spacing: 2) {
            ForEach(0..<rowCount, id: \.self) { row in
                ForEach(0..<colCount, id: \.self) { col in
                    TileView(row: row, col: col)
                        .frame(height: tileHeight ?? 30)
                        .contentShape(Rectangle()) // make full tile tappable
                        .onTapGesture {
                            onTileTap?(row, col)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(accessibilityLabelForTile(row: row, col: col))
                }
            }
        }
    }
    
    /// Compose an accessibility label describing a tile, its type, and players present.
    private func accessibilityLabelForTile(row: Int, col: Int) -> String {
        let color = viewModel.mapGrid[row][col]
        // Describe barriers as "Barrier" for screen reader clarity.
        let tileDescription: String
        if color == .black {
            tileDescription = "Barrier"
        } else {
            // Attempt to derive a simple description from color components where possible.
            tileDescription = "Open"
        }
        
        let playersHere = viewModel.players.filter { !$0.isEliminated && $0.position.row == row && $0.position.col == col }
        if playersHere.isEmpty {
            return "Tile \(row), column \(col). \(tileDescription). No players."
        } else {
            let names = playersHere.map { $0.character.rawValue }
            return "Tile \(row), column \(col). \(tileDescription). Players: \(names.joined(separator: ", "))."
        }
    }
    
    /// A single tile cell view
    @ViewBuilder
    private func TileView(row: Int, col: Int) -> some View {
        ZStack {
            // Base tile color comes directly from the viewModel's mapGrid. This allows
            // the game logic to encode tile types as colors (e.g., .black = barrier).
            Rectangle()
                .fill(viewModel.mapGrid[row][col])
                .overlay(
                    // Optional subtle grid line
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.black.opacity(showsGridLines ? 0.06 : 0), lineWidth: showsGridLines ? 0.5 : 0)
                )
            
            // If this tile is a barrier, add a visual mark (diagonal stripes).
            if viewModel.mapGrid[row][col] == .black {
                // A lightweight barrier indicator
                BarrierOverlay()
                    .clipShape(Rectangle())
                    .opacity(0.28)
            }
            
            // Players on this tile
            let playersHere = viewModel.players.filter { !$0.isEliminated && $0.position.row == row && $0.position.col == col }
            
            if playersHere.count > 0 {
                if playersHere.count <= maxPlayerDots {
                    // Show small stacked/arranged dots for each player
                    HStack(spacing: 4) {
                        ForEach(Array(playersHere.enumerated()), id: \.element.id) { (index, player) in
                            ZStack {
                                Circle()
                                    .fill(player.character.color)
                                    .frame(width: 16, height: 16)
                                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                                Text(String(player.character.rawValue.prefix(1)))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                // Small elimination indicator if present (shouldn't show as we filtered eliminated)
                                EmptyView()
                            )
                        }
                    }
                } else {
                    // Too many players — show a single small badge with count
                    Text("\(playersHere.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
        }
        .cornerRadius(4)
        .padding(0)
    }
    
    /// Lightweight diagonal stripes used as barrier decoration
    private func BarrierOverlay() -> some View {
        GeometryReader { geo in
            // Draw thin diagonal lines across tile
            let step: CGFloat = 6
            Path { path in
                var x: CGFloat = -geo.size.height
                while x < geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + geo.size.height, y: geo.size.height))
                    x += step
                }
            }
            .stroke(Color.black.opacity(0.18), lineWidth: 1)
        }
    }
}

// MARK: - Preview

struct Element8BoardView_Previews: PreviewProvider {
    static var previews: some View {
        // Build a small test viewModel
        let vm = GameViewModel()
        // Force a predictable map for preview: clear then add some barriers
        vm.mapGrid = Array(repeating: Array(repeating: Color.white, count: 10), count: 10)
        vm.mapGrid[2][3] = .black
        vm.mapGrid[1][1] = .black
        vm.mapGrid[6][7] = .black
        
        // Add a couple of demo players (using the Player class)
        vm.players = [
            Player(character: .fire),
            Player(character: .water),
            Player(character: .earth),
            Player(character: .wind)
        ]
        // Place them manually for preview clarity
        vm.players[0].position = (row: 3, col: 3)
        vm.players[1].position = (row: 3, col: 3) // two players on same tile
        vm.players[2].position = (row: 0, col: 0)
        vm.players[3].position = (row: 9, col: 9)
        
        return VStack {
            Text("BoardView Preview")
                .font(.headline)
            BoardView(viewModel: vm, tileHeight: 36, onTileTap: { r, c in
                vm.gameMessage = "Preview tapped \(r),\(c)"
            })
            .padding()
            .background(Color(white: 0.95))
            .cornerRadius(8)
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
