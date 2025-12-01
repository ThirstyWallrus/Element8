//
//  HomeView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 11/30/25.
//  Updated by Copilot on 2025-12-01 to use Sepia, Element8, and 8 assets.
//

import SwiftUI

struct HomeView: View {
    // Custom colors inspired by the Element 8 game theme: parchment browns, vibrant element accents
    let parchmentColor = Color(red: 0.82, green: 0.65, blue: 0.47) // kept as a fallback accent
    let accentColor = Color.orange // For buttons and highlights
    let textColor = Color.black // For readability on light backgrounds
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Use the Sepia asset as the preferred menu/background texture
                Image("Sepia")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                // Optional subtle overlay for contrast (keeps readability)
                Color.black.opacity(0.06)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Brand image for consistent look
                    Image("Element8")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                        .padding(.top, 36)
                    
                    // Decorative hero symbol (use bundled '8' image)
                    Image("8")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    // Brief description matching website vibe
                    Text("Harness the power of the elements in this epic adventure board game!")
                        .font(.title3)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Navigation buttons with themed styling
                    NavigationLink(destination: AboutView()) {
                        Text("About Element 8")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(accentColor)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                    .padding(.horizontal, 40)
                    
                    NavigationLink(destination: ShopView()) {
                        Text("Shop")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue) // Element-inspired color
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                    .padding(.horizontal, 40)
                    
                    NavigationLink(destination: RulesView()) {
                        Text("Game Rules")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green) // Element-inspired color
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true) // Hide default nav bar for custom look
        }
    }
}

// Placeholder views for navigation (expand as needed)
struct AboutView: View {
    var body: some View {
        ZStack {
            Image("Sepia")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Text("About Page")
                .font(.title)
                .padding()
        }
    }
}

struct ShopView: View {
    var body: some View {
        ZStack {
            Image("Sepia")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Text("Shop Page")
                .font(.title)
                .padding()
        }
    }
}

struct RulesView: View {
    var body: some View {
        ZStack {
            Image("Sepia")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Text("Rules Page")
                .font(.title)
                .padding()
        }
    }
}

#Preview {
    HomeView()
}
