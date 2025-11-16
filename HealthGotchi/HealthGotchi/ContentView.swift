//
//  ContentView.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    @State private var showSettings = false
    
    private var themeColor: Color {
        color(for: viewModel.themeColorName)
    }
    
    var body: some View {
        NavigationStack {
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
            .tint(themeColor)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(themeColor)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsScreen()
                    .environmentObject(viewModel)
            }
        }
    }
    
    private func color(for name: String) -> Color {
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        default: return .green
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthPetViewModel())
}
