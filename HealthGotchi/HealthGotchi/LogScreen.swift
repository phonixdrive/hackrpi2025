//
//  LogScreen.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import SwiftUI

struct LogScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    @State private var healthManager = HealthManager()
    
    @State private var stepsText: String = ""
    @State private var healthyMeals: Int = 0
    @State private var junkMeals: Int = 0
    
    @State private var sleepHours: Double = 0
    @State private var distanceKm: Double = 0
    @State private var flights: Int = 0
    @State private var bodyWeightKg: Double? = nil
    @State private var bodyHeightM: Double? = nil
    
    private var themeColor: Color {
        color(for: viewModel.themeColorName)
    }
    
    var body: some View {
        let todayLog = viewModel.logForToday()
        
        ZStack {
            // Retro background
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.15, blue: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("TODAY'S LOG")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(themeColor)
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        // Steps
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STEPS")
                                .font(.system(.headline, design: .monospaced))
                            
                            TextField("Enter steps", text: $stepsText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .foregroundColor(.black) // keep field readable
                            
                            Text("Current: \(todayLog.steps) steps")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(themeColor.opacity(0.7))
                            
                            Button("IMPORT FROM HEALTH APP") {
                                importFromHealth()
                            }
                            .font(.system(.caption, design: .monospaced))
                            .padding(.top, 4)
                        }
                        .retroCard(theme: themeColor)
                        
                        // Healthy meals
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("HEALTHY MEALS")
                                Spacer()
                                Text("\(healthyMeals)")
                            }
                            .font(.system(.headline, design: .monospaced))
                            
                            Stepper("Adjust", value: $healthyMeals, in: 0...10)
                                .labelsHidden()
                                .onChange(of: healthyMeals) { _, newValue in
                                    viewModel.updateToday(healthyMeals: newValue)
                                }
                        }
                        .retroCard(theme: themeColor)
                        
                        // Junk meals
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("JUNK MEALS")
                                Spacer()
                                Text("\(junkMeals)")
                            }
                            .font(.system(.headline, design: .monospaced))
                            
                            Stepper("Adjust", value: $junkMeals, in: 0...10)
                                .labelsHidden()
                                .onChange(of: junkMeals) { _, newValue in
                                    viewModel.updateToday(junkMeals: newValue)
                                }
                        }
                        .retroCard(theme: themeColor)
                        
                        // Health data summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HEALTH SUMMARY")
                                .font(.system(.headline, design: .monospaced))
                            
                            HStack {
                                Text("Sleep")
                                Spacer()
                                Text(String(format: "%.1f hrs", sleepHours))
                            }
                            
                            HStack {
                                Text("Distance")
                                Spacer()
                                Text(String(format: "%.2f km (%.2f mi)",
                                            distanceKm,
                                            distanceKm * 0.621371))
                            }
                            
                            HStack {
                                Text("Flights climbed")
                                Spacer()
                                Text("\(flights)")
                            }
                            
                            if let weight = bodyWeightKg {
                                HStack {
                                    Text("Weight")
                                    Spacer()
                                    Text(String(format: "%.1f kg (%.1f lbs)",
                                                weight,
                                                weight * 2.20462))
                                }
                            }
                            
                            if let heightM = bodyHeightM {
                                let cm = heightM * 100.0
                                let totalInches = heightM * 39.3701
                                let feet = Int(totalInches / 12.0)
                                let inches = Int(round(totalInches.truncatingRemainder(dividingBy: 12.0)))
                                
                                HStack {
                                    Text("Height")
                                    Spacer()
                                    Text(String(format: "%.0f cm (%d ft %d in)", cm, feet, inches))
                                }
                            }
                        }
                        .retroCard(theme: themeColor)
                        
                        // Manual tuning / debug
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MANUAL TUNING (DEBUG)")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(themeColor)
                            
                            // Sleep
                            Stepper(
                                value: $sleepHours,
                                in: 0...14,
                                step: 0.5
                            ) {
                                HStack {
                                    Text("Sleep")
                                    Spacer()
                                    Text(String(format: "%.1f hrs", sleepHours))
                                }
                            }
                            .onChange(of: sleepHours) { _, newValue in
                                viewModel.updateToday(sleepHours: newValue)
                            }
                            
                            // Distance
                            Stepper(
                                value: $distanceKm,
                                in: 0...20,
                                step: 0.5
                            ) {
                                HStack {
                                    Text("Distance")
                                    Spacer()
                                    Text(String(format: "%.1f km", distanceKm))
                                }
                            }
                            .onChange(of: distanceKm) { _, newValue in
                                viewModel.updateToday(distanceKm: newValue)
                            }
                            
                            // Flights
                            Stepper(
                                value: Binding(
                                    get: { Double(flights) },
                                    set: { flights = Int($0) }
                                ),
                                in: 0...50,
                                step: 1
                            ) {
                                HStack {
                                    Text("Flights climbed")
                                    Spacer()
                                    Text("\(flights)")
                                }
                            }
                            .onChange(of: flights) { _, newValue in
                                viewModel.updateToday(flights: newValue)
                            }
                            
                            // Weight
                            Stepper(
                                value: Binding(
                                    get: { bodyWeightKg ?? 70.0 },
                                    set: { bodyWeightKg = $0 }
                                ),
                                in: 40...200,
                                step: 1
                            ) {
                                HStack {
                                    Text("Weight")
                                    Spacer()
                                    Text(String(format: "%.0f kg", bodyWeightKg ?? 70.0))
                                }
                            }
                            .onChange(of: bodyWeightKg ?? 70.0) { _, newValue in
                                bodyWeightKg = newValue
                                viewModel.updateToday(bodyWeightKg: newValue)
                            }
                            
                            // Height
                            Stepper(
                                value: Binding(
                                    get: { bodyHeightM ?? 1.75 },
                                    set: { bodyHeightM = $0 }
                                ),
                                in: 1.4...2.1,
                                step: 0.01
                            ) {
                                let h = bodyHeightM ?? 1.75
                                let cm = h * 100.0
                                HStack {
                                    Text("Height")
                                    Spacer()
                                    Text(String(format: "%.0f cm", cm))
                                }
                            }
                            .onChange(of: bodyHeightM ?? 1.75) { _, newValue in
                                bodyHeightM = newValue
                                viewModel.updateToday(bodyHeightM: newValue)
                            }
                        }
                        .retroCard(theme: themeColor)
                        
                        Button(action: finishToday) {
                            Text("finish TODAY")
                                .font(.system(.headline, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeColor)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                        .padding(.bottom, 20)
                    }
                    .foregroundColor(themeColor)
                }
                .padding()
            }
        }
        .onAppear {
            // Sync UI with today’s current values
            let log = viewModel.logForToday()
            stepsText = log.steps > 0 ? String(log.steps) : ""
            healthyMeals = log.healthyMeals
            junkMeals = log.junkMeals
            sleepHours = log.sleepHours
            distanceKm = log.distanceKm
            flights = log.flights
            bodyWeightKg = log.bodyWeightKg
            bodyHeightM = log.bodyHeightM
        }
    }
    
    func saveToday() {
        let steps = Int(stepsText) ?? 0
        viewModel.updateToday(
            steps: steps,
            healthyMeals: healthyMeals,
            junkMeals: junkMeals,
            sleepHours: sleepHours,
            distanceKm: distanceKm,
            flights: flights,
            bodyWeightKg: bodyWeightKg,
            bodyHeightM: bodyHeightM
        )
    }
    func finishToday() {
        // 1) Save today's data to the current simulated day
        let steps = Int(stepsText) ?? 0
        viewModel.updateToday(
            steps: steps,
            healthyMeals: healthyMeals,
            junkMeals: junkMeals,
            sleepHours: sleepHours,
            distanceKm: distanceKm,
            flights: flights,
            bodyWeightKg: bodyWeightKg
        )
        
        // 2) Advance the app's "today" to the next day
        viewModel.advanceToNextDay()
        
        // 3) Reset today's editable fields for the new day
        let newLog = viewModel.logForToday()
        stepsText   = newLog.steps > 0 ? String(newLog.steps) : ""
        healthyMeals = newLog.healthyMeals
        junkMeals    = newLog.junkMeals
        sleepHours   = newLog.sleepHours
        distanceKm   = newLog.distanceKm
        flights      = newLog.flights
        bodyWeightKg = newLog.bodyWeightKg
    }
    
    func importFromHealth() {
        guard healthManager.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            return
        }
        
        healthManager.requestAuthorization { success in
            guard success else {
                print("Health auth not granted")
                return
            }
            
            healthManager.fetchTodaySnapshot { snapshot in
                guard let snapshot = snapshot else { return }
                
                DispatchQueue.main.async {
                    // Update UI
                    self.stepsText = String(snapshot.steps)
                    self.sleepHours = snapshot.sleepHours
                    self.distanceKm = snapshot.distanceKm
                    self.flights = snapshot.flights
                    self.bodyWeightKg = snapshot.bodyWeightKg
                    self.bodyHeightM = snapshot.bodyHeightM
                    
                    // Update today's log with all the pulled metrics
                    self.viewModel.updateToday(
                        steps: snapshot.steps,
                        healthyMeals: self.healthyMeals,
                        junkMeals: self.junkMeals,
                        sleepHours: snapshot.sleepHours,
                        distanceKm: snapshot.distanceKm,
                        flights: snapshot.flights,
                        bodyWeightKg: snapshot.bodyWeightKg,
                        bodyHeightM: snapshot.bodyHeightM
                    )
                }
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

fileprivate extension View {
    func retroCard(theme: Color) -> some View {
        self
            .padding()
            .background(Color.black.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme, lineWidth: 1.5)
            )
            .cornerRadius(12)
    }
}

#Preview {
    LogScreen()
        .environmentObject(HealthPetViewModel())
}
