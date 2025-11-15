//
//  ContentView.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    
    var body: some View {
        TabView {
            PetScreen()
                .tabItem {
                    Label("Pet", systemImage: "heart.circle.fill")
                }
            
            LogScreen()
                .tabItem {
                    Label("Log", systemImage: "square.and.pencil")
                }
            
            StatsScreen()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthPetViewModel())
}
