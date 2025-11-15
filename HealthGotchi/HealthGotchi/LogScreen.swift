//
//  LogScreen.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import SwiftUI

struct LogScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    
    @State private var stepsText: String = ""
    @State private var healthyMeals: Int = 0
    @State private var junkMeals: Int = 0
    
    var body: some View {
        let todayLog = viewModel.logForToday()
        
        VStack(spacing: 16) {
            Text("Today’s Log")
                .font(.title2)
                .bold()
            
            // Steps
            VStack(alignment: .leading, spacing: 8) {
                Text("Steps")
                    .font(.headline)
                
                TextField("Enter steps", text: $stepsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
                Text("Current: \(todayLog.steps) steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Healthy meals
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Healthy meals")
                        .font(.headline)
                    Spacer()
                    Text("\(todayLog.healthyMeals)")
                        .font(.headline)
                }
                
                Stepper("Adjust", value: $healthyMeals, in: 0...10)
                    .labelsHidden()
            }
            
            // Junk meals
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Junk meals")
                        .font(.headline)
                    Spacer()
                    Text("\(todayLog.junkMeals)")
                        .font(.headline)
                }
                
                Stepper("Adjust", value: $junkMeals, in: 0...10)
                    .labelsHidden()
            }
            
            Button(action: saveToday) {
                Text("Save Today’s Log")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Sync UI with today’s current values
            let log = viewModel.logForToday()
            stepsText = log.steps > 0 ? String(log.steps) : ""
            healthyMeals = log.healthyMeals
            junkMeals = log.junkMeals
        }
    }
    
    func saveToday() {
        let steps = Int(stepsText) ?? 0
        viewModel.updateToday(
            steps: steps,
            healthyMeals: healthyMeals,
            junkMeals: junkMeals
        )
    }
}

#Preview {
    LogScreen()
        .environmentObject(HealthPetViewModel())
}
