//
//  HomeView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 11/30/25.
//  Updated by Copilot on 2025-12-01 to use global Sepia background and sand/script themed menu colors.
//  Modified on 2025-12-01 to add "Play Game" navigation link to GameSetupView and "Edit Characters" to open the in-app editor.
//  Updated on 2025-12-04: apply Caribbean for headings and Norse for all button labels.
//

import SwiftUI

struct HomeView: View {
    // Sand / script themed palette
    let sandLight = Color(red: 0.97, green: 0.94, blue: 0.86) // very light sand (can be used for subtle buttons)
    let sandMid = Color(red: 0.91, green: 0.82, blue: 0.66)   // mid sand (neutral)
    let sandDark = Color(red: 0.74, green: 0.58, blue: 0.38)  // rich sand / parchment brown for primary buttons
    let scriptText = Color(red: 0.35, green: 0.22, blue: 0.12) // deep brown used for text and outlines
    
    var body: some View {
        NavigationStack {
            ZStack {
                // No per-view background here — Sepia is applied globally in Element8App.
                // Optional subtle overlay to ensure contrast with elements on top.
                Color.black.opacity(0.04)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Brand image for consistent look (increased size)
                    Image("Element8Title")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110) // increased title size
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                        .padding(.top, 36)
                    
                    
                    // Brief description matching website vibe
                    Text("Coming Soon")
                        // HEADING: use Caribbean for prominent heading text
                        .font(Font.custom("Caribbean", size: 20))
                        .foregroundColor(scriptText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // New: Play Game navigation link (integrates the new game views)
                    NavigationLink(destination: GameSetupView()) {
                        Text("Play Game")
                            // BUTTON LABEL: use Norse
                            .font(Font.custom("Norse", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(sandDark)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)
                    
                    // Edit Characters (open in-app editor)
                    NavigationLink(destination: CharacterEditorView()) {
                        Text("Edit Characters")
                            // BUTTON LABEL: use Norse
                            .font(Font.custom("Norse", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.60, green: 0.48, blue: 0.30))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)
                    
                    // Navigation buttons with sand/script themed styling
                    NavigationLink(destination: AboutView()) {
                        Text("About Element 8")
                            // BUTTON LABEL: use Norse
                            .font(Font.custom("Norse", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(sandDark)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)
                    
                    NavigationLink(destination: ShopView()) {
                        Text("Shop")
                            // BUTTON LABEL: use Norse
                            .font(Font.custom("Norse", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.83, green: 0.67, blue: 0.44)) // warm amber / sand tone
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)
                    
                    NavigationLink(destination: RulesView()) {
                        Text("Game Rules")
                            // BUTTON LABEL: use Norse
                            .font(Font.custom("Norse", size: 16))
                            .foregroundColor(scriptText) // darker text on lighter sand
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(sandMid)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(scriptText.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true) // Hide default nav bar for custom look
        }
    }
}

// Placeholder views for navigation (they inherit the global Sepia background)
struct AboutView: View {
    var body: some View {
        VStack {
            Text("About Page")
                .font(.title)
                .padding()
        }
        .navigationTitle("About")
    }
}

struct ShopView: View {
    var body: some View {
        VStack {
            Text("Shop Page")
                .font(.title)
                .padding()
        }
        .navigationTitle("Shop")
    }
}

struct RulesView: View {
    var body: some View {
        VStack {
            Text("Rules Page")
                .font(.title)
                .padding()
        }
        .navigationTitle("Rules")
    }
}

#Preview {
    // Preview won't include Element8App's global background, so preview views may look different here.
    HomeView()
}
