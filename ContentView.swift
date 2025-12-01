//
//  ContentView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//  Updated by Copilot on 2025-12-01 to use CompassBG, Element8, and 8 assets and add entry navigation.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Primary app background (preferred for main app shell)
                Image("CompassBG")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Central logo / title image
                    Image("Element8")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 480, maxHeight: 200)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Enter button to proceed into HomeView for continuity
                    NavigationLink(destination: HomeView()) {
                        Text("Enter")
                            .font(.headline)
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
    ContentView()
}
