//
//  PetScreen.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import SwiftUI

struct PetScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your HealthGotchi")
                .font(.largeTitle)
                .bold()
            
            Text("Level \(viewModel.pet.level)")
                .font(.headline)
            
            // Pet appearance based on health
            Text(petEmoji(for: viewModel.pet.health, level: viewModel.pet.level))
                .font(.system(size: 96))
            
            // Health bar
            VStack(alignment: .leading) {
                Text("Health")
                    .font(.subheadline)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(height: 20)
                        .opacity(0.2)
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: CGFloat(viewModel.pet.health) * 200,
                               height: 20)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text("Overall health: \(Int(viewModel.pet.health * 100))%")
                Text("XP: \(Int(viewModel.pet.experience * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(petMessage())
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    func petEmoji(for health: Double, level: Int) -> String {
        if health >= 0.8 {
            return level >= 2 ? "🦊" : "😊"
        } else if health >= 0.5 {
            return "😐"
        } else {
            return "😵"
        }
    }
    
    func petMessage() -> String {
        let h = viewModel.pet.health
        
        switch h {
        case 0.8...1.0:
            return "I'm feeling amazing! Keep those steps and meals coming 😄"
        case 0.5..<0.8:
            return "I'm doing okay, but we can do even better today 💪"
        case 0.3..<0.5:
            return "I’m a bit sluggish… maybe a short walk and a healthy snack? 🥗"
        default:
            return "Help… I need movement and better meals 😵‍💫"
        }
    }
}

#Preview {
    PetScreen()
        .environmentObject(HealthPetViewModel())
}
