//
//  HealthGotchiApp.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//

import SwiftUI

@main
struct HealthGotchiApp: App {
    @StateObject private var viewModel = HealthPetViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
