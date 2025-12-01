//
//  ContentView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//  Updated by Copilot on 2025-12-01 to use global Sepia background, increase title size, and refine layout.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // No per-view full-screen background here — the app's global Sepia background is applied in Element8App.
                VStack {
                    Spacer()
                    
                    // Central logo / title image (increased size for stronger branding)
                    Image("Element8")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 640, maxHeight: 260) // increased size
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Enter button to proceed into HomeView for continuity
                    NavigationLink(destination: HomeView()) {
                        Text("Enter")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 36)
                            .background(.black.opacity(0.6))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    }
                    .padding(.bottom, 36)
                }
                
                // Decorative '8' badge in the lower-right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("8")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 84, height: 84)
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
                            .padding(16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    // For preview, show ContentView alone — previews won't include Element8App's global background.
    ContentView()
}
