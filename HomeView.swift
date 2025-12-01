//
//  HomeView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 11/30/25.
//


import SwiftUI

struct HomeView: View {
    // Custom colors inspired by the Element 8 game theme: parchment browns, vibrant element accents
    let parchmentColor = Color(red: 0.82, green: 0.65, blue: 0.47) // Approximate parchment background
    let accentColor = Color.orange // For buttons and highlights
    let textColor = Color.black // For readability on light backgrounds
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient to mimic parchment or treasure map style
                LinearGradient(
                    gradient: Gradient(colors: [parchmentColor, .brown.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Subtle parchment texture overlay using AsyncImage for web-loaded texture
                AsyncImage(url: URL(string: "https://media.istockphoto.com/id/1350825463/photo/seamless-tileable-vintage-parchment-paper-texture-background.jpg?s=612x612&w=0&k=20&c=CZUx51FKs__Ly6fhVJUnG5-1T1SvuTQfn5RYQNp6ylw=")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(0.3) // Adjust opacity for subtlety
                    } else if phase.error != nil {
                        Color.clear // Fallback if loading fails
                    } else {
                        Color.clear // Placeholder while loading
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo or title with fantasy style
                    Text("Element 8")
                        .font(.custom("Papyrus", size: 48)) // Use a script-like font if available; fallback to system
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                        .padding(.top, 50)
                    
                    // Hero image placeholder (replace with actual game image URL or asset)
                    Image(systemName: "star.circle.fill") // Placeholder for compass or element symbol
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(accentColor)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    // Brief description matching website vibe
                    Text("Harness the power of the elements in this epic adventure board game!")
                        .font(.title3)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
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
        Text("About Page")
    }
}

struct ShopView: View {
    var body: some View {
        Text("Shop Page")
    }
}

struct RulesView: View {
    var body: some View {
        Text("Rules Page")
    }
}

#Preview {
    HomeView()
}