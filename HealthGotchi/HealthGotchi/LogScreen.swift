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
    
    @FocusState private var stepsFieldIsFocused: Bool
    
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
                        // STEPS
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("STEPS")
                                    .font(.system(.headline, design: .monospaced))
                                Spacer()
                                // Local "DONE" to kill keyboard if toolbar fails
                                if stepsFieldIsFocused {
                                    Button("DONE") {
                                        stepsFieldIsFocused = false
                                    }
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(themeColor)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Enter steps", text: $stepsText)
                                    .keyboardType(.numberPad)
                                    .padding(8)
                                    .background(Color(white: 0.1)) // dark but visible
                                    .foregroundColor(themeColor)   // green/red/blue/purple text
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColor, lineWidth: 1.5)
                                    )
                                    .cornerRadius(8)
                                    .focused($stepsFieldIsFocused)
                                
                                Button {
                                    // Quick apply button if you want to force-save
                                    let steps = Int(stepsText) ?? 0
                                    viewModel.updateToday(steps: steps)
                                } label: {
                                    Text("APPLY")
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(themeColor)
                                        .foregroundColor(.black)
                                        .cornerRadius(6)
                                }
                            }
                            
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
                        
                        // HEALTHY MEALS
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
                        
                        // JUNK MEALS
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
                        
                        // HEALTH DATA SUMMARY
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
                                let inches = Int(round(
                                    totalInches.truncatingRemainder(dividingBy: 12.0)
                                ))
                                
                                HStack {
                                    Text("Height")
                                    Spacer()
                                    Text(String(format: "%.0f cm (%d ft %d in)", cm, feet, inches))
                                }
                            }
                        }
                        .retroCard(theme: themeColor)
                        
                        // MANUAL TUNING / DEBUG
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
                            Text("FINISH TODAY")
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
            stepsText   = log.steps > 0 ? String(log.steps) : ""
            healthyMeals = log.healthyMeals
            junkMeals    = log.junkMeals
            sleepHours   = log.sleepHours
            distanceKm   = log.distanceKm
            flights      = log.flights
            
            // For weight/height, prefer today's log; otherwise fall back to last known values
            if let w = log.bodyWeightKg {
                bodyWeightKg = w
            } else if let lastW = viewModel.logs.reversed().compactMap({ $0.bodyWeightKg }).first {
                bodyWeightKg = lastW
            }
            
            if let h = log.bodyHeightM {
                bodyHeightM = h
            } else if let lastH = viewModel.logs.reversed().compactMap({ $0.bodyHeightM }).first {
                bodyHeightM = lastH
            }
        }
        .toolbar {
            // Keyboard toolbar "Done" button (above number pad)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    stepsFieldIsFocused = false
                }
            }
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
            bodyWeightKg: bodyWeightKg,
            bodyHeightM: bodyHeightM
        )
        
        // 2) Advance the app's "today" to the next day
        viewModel.advanceToNextDay()
        
        // 3) Carry weight/height forward into the new day's log (they should be persistent)
        if let w = bodyWeightKg {
            viewModel.updateToday(bodyWeightKg: w)
        }
        if let h = bodyHeightM {
            viewModel.updateToday(bodyHeightM: h)
        }
        
        // 4) Reset today's editable fields for the new day.
        //    Sleep, distance, flights, meals start at 0 for *today*,
        //    but weight/height persist.
        sleepHours   = 0
        distanceKm   = 0
        flights      = 0
        healthyMeals = 0
        junkMeals    = 0
        stepsText    = ""
        
        let newLog = viewModel.logForToday()
        bodyWeightKg = newLog.bodyWeightKg ?? bodyWeightKg
        bodyHeightM  = newLog.bodyHeightM ?? bodyHeightM
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
                    // Update UI from HealthKit snapshot
                    self.stepsText    = String(snapshot.steps)
                    self.sleepHours   = snapshot.sleepHours
                    self.distanceKm   = snapshot.distanceKm
                    self.flights      = snapshot.flights
                    self.bodyWeightKg = snapshot.bodyWeightKg
                    self.bodyHeightM  = snapshot.bodyHeightM
                    
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
