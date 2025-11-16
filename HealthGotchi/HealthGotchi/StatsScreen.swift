//
//  StatsScreen.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import SwiftUI

struct StatsScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    
    private var themeColor: Color {
        color(for: viewModel.themeColorName)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.05, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("RECENT STATS")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(themeColor)
                        .padding(.top, 20)
                    
                    ForEach(viewModel.sortedRecentLogs()) { log in
                        statCard(for: log)
                            .retroCard(theme: themeColor)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private func statCard(for log: DayLog) -> some View {
        let df = DateFormatter()
        df.dateStyle = .short
        
        let bmiText: String
        if let w = log.bodyWeightKg, let h = log.bodyHeightM, h > 0 {
            let bmi = w / (h * h)
            bmiText = String(format: "BMI: %.1f", bmi)
        } else {
            bmiText = "BMI: --"
        }
        
        return VStack(alignment: .leading, spacing: 6) {
            Text(df.string(from: log.date))
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(themeColor)
            
            Text("Steps: \(log.steps)")
            Text(String(format: "Distance: %.2f km (%.2f mi)",
                        log.distanceKm,
                        log.distanceKm * 0.621371))
            Text("Flights: \(log.flights)")
            
            Text(String(format: "Sleep: %.1f hrs", log.sleepHours))
            Text("Healthy meals: \(log.healthyMeals) · Junk: \(log.junkMeals)")
            
            if let w = log.bodyWeightKg {
                Text(String(format: "Weight: %.1f kg (%.1f lbs)",
                            w,
                            w * 2.20462))
            }
            if let h = log.bodyHeightM {
                let cm = h * 100.0
                let totalInches = h * 39.3701
                let feet = Int(totalInches / 12.0)
                let inches = Int(round(totalInches.truncatingRemainder(dividingBy: 12.0)))
                Text(String(format: "Height: %.0f cm (%d ft %d in)", cm, feet, inches))
            }
            
            Text(bmiText)
        }
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(themeColor.opacity(0.9))
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
    StatsScreen()
        .environmentObject(HealthPetViewModel())
}
