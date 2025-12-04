//
//  GameSetupView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 12/2/25.
//
// GameSetupView.swift
// Separated from Element8Game.swift on 2025-12-01 to make per-view editing easier.
//
// This view uses CharacterRegistry.shared for profile listing and GameView for navigation.
// Updated 2025-12-04 to apply Caribbean for the heading and Norse for button labels.
//

import SwiftUI

struct GameSetupView: View {
    @State private var selectedProfiles: [CharacterProfile] = []
    @State private var navigateToGame: Bool = false
    @ObservedObject private var registryObserver = CharacterRegistry.sharedObserver
    
    var body: some View {
        VStack {
            Text("Select 2-8 Characters")
                // VIEW TITLE: use Caribbean font per your instruction
                .font(Font.custom("Caribbean", size: 22))
                .padding(.top, 20)
            
            List {
                ForEach(CharacterRegistry.shared.profilesSortedByName, id: \.self) { profile in
                    Button(action: {
                        if selectedProfiles.contains(profile) {
                            selectedProfiles.removeAll { $0 == profile }
                        } else if selectedProfiles.count < 8 {
                            selectedProfiles.append(profile)
                        }
                    }) {
                        HStack {
                            // Optional sprite preview
                            if let sprite = profile.spriteName, !sprite.isEmpty {
                                Image(sprite)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .cornerRadius(4)
                            } else {
                                Circle()
                                    .fill(profile.color)
                                    .frame(width: 36, height: 36)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(profile.displayName)
                                    .foregroundColor(.primary)
                                Text(profile.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if selectedProfiles.contains(profile) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(profile.color)
                            }
                        }
                        .padding(.vertical, 6)
                        // BUTTON LABEL: ensure label text inside Button uses Norse (applies to tapping the row)
                        .font(Font.custom("Norse", size: 15))
                    }
                }
            }
            
            Spacer()
            
            NavigationLink(destination: GameView(profiles: selectedProfiles), isActive: $navigateToGame) {
                EmptyView()
            }
            
            Button(action: {
                if selectedProfiles.count >= 2 {
                    navigateToGame = true
                }
            }) {
                Text("Start Game")
                    // BUTTON LABEL: use Norse
                    .font(Font.custom("Norse", size: 16))
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

// Preview for GameSetupView
#if DEBUG
struct GameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GameSetupView()
        }
    }
}
#endif
