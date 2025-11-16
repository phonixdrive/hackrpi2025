//
//  SettingsScreen.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    @Environment(\.dismiss) var dismiss
    
    private var themeColor: Color {
        Self.color(for: viewModel.themeColorName)
    }
    
    private static func color(for name: String) -> Color {
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        default: return .green
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("SETTINGS")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(themeColor)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Color scheme
                VStack(alignment: .leading, spacing: 12) {
                    Text("COLOR SCHEME")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(themeColor)
                    
                    HStack(spacing: 10) {
                        colorButton(name: "green", display: "GREEN", color: .green)
                        colorButton(name: "red", display: "RED", color: .red)
                    }
                    HStack(spacing: 10) {
                        colorButton(name: "blue", display: "BLUE", color: .blue)
                        colorButton(name: "purple", display: "PURPLE", color: .purple)
                    }
                }
                .retroCard(theme: themeColor)
                
                // Difficulty
                VStack(alignment: .leading, spacing: 12) {
                    Text("DIFFICULTY")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(themeColor)
                    
                    HStack(spacing: 10) {
                        difficultyButton(label: "EASY", value: 0.5)
                        difficultyButton(label: "NORMAL", value: 1.0)
                        difficultyButton(label: "HARD", value: 2.0)
                    }
                }
                .retroCard(theme: themeColor)
                
                // Reset data
                VStack(alignment: .leading, spacing: 12) {
                    Text("DATA")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(themeColor)
                    
                    Button(role: .destructive) {
                        viewModel.resetAllData()
                    } label: {
                        Text("RESET ALL DATA")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1.5)
                            )
                            .cornerRadius(8)
                    }
                }
                .retroCard(theme: themeColor)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func colorButton(name: String, display: String, color: Color) -> some View {
        let isSelected = viewModel.themeColorName == name
        
        return Button {
            viewModel.setThemeColor(name: name)
        } label: {
            Text(display)
                .font(.system(.caption, design: .monospaced))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? color : Color.black.opacity(0.7))
                .foregroundColor(isSelected ? .black : color)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: 1.5)
                )
                .cornerRadius(8)
        }
    }
    
    private func difficultyButton(label: String, value: Double) -> some View {
        let isSelected = abs(viewModel.difficulty - value) < 0.01
        
        return Button {
            viewModel.setDifficulty(value)
        } label: {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? themeColor : Color.black.opacity(0.7))
                .foregroundColor(isSelected ? .black : themeColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeColor, lineWidth: 1.5)
                )
                .cornerRadius(8)
        }
    }
}

fileprivate extension View {
    func retroCard(theme: Color) -> some View {
        self
            .padding()
            .background(Color.black.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme, lineWidth: 1.5)
            )
            .cornerRadius(12)
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(HealthPetViewModel())
}
