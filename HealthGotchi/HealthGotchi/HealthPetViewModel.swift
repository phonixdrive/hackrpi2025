//
//  HealthPetViewModel.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//

import Foundation
import Combine

class HealthPetViewModel: ObservableObject {
    @Published var pet: PetState
    @Published var logs: [DayLog]
    
    // Simulated "today" for the app (so we can advance days)
    @Published var currentDate: Date
    
    // App-wide settings
    @Published var difficulty: Double      // 0.5 = easy, 1 = normal, 2 = hard
    @Published var themeColorName: String  // "green", "red", "blue", "purple"
    
    private let petKey = "pet_state_v1"
    private let logsKey = "day_logs_v1"
    private let difficultyKey = "difficulty_multiplier_v1"
    private let themeColorKey = "theme_color_v1"
    private let currentDateKey = "current_date_v1"
    
    init() {
        self.pet = PetState.default
        self.logs = []
        
        let defaults = UserDefaults.standard
        
        let savedDifficulty = defaults.object(forKey: difficultyKey) as? Double ?? 1.0
        let savedTheme = defaults.string(forKey: themeColorKey) ?? "green"
        
        self.difficulty = savedDifficulty
        self.themeColorName = savedTheme
        
        if let ts = defaults.object(forKey: currentDateKey) as? TimeInterval {
            self.currentDate = Date(timeIntervalSince1970: ts).startOfDay()
        } else {
            self.currentDate = Date().startOfDay()
        }
        
        load()
        recalculateHealth()
    }
    
    // MARK: - Persistence
    
    func load() {
        let defaults = UserDefaults.standard
        
        if let petData = defaults.data(forKey: petKey),
           let decodedPet = try? JSONDecoder().decode(PetState.self, from: petData) {
            self.pet = decodedPet
        }
        
        if let logsData = defaults.data(forKey: logsKey),
           let decodedLogs = try? JSONDecoder().decode([DayLog].self, from: logsData) {
            self.logs = decodedLogs
        }
    }
    
    func save() {
        let defaults = UserDefaults.standard
        
        if let petData = try? JSONEncoder().encode(pet) {
            defaults.set(petData, forKey: petKey)
        }
        
        if let logsData = try? JSONEncoder().encode(logs) {
            defaults.set(logsData, forKey: logsKey)
        }
        
        // persist simulated current date
        defaults.set(currentDate.timeIntervalSince1970, forKey: currentDateKey)
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(difficulty, forKey: difficultyKey)
        defaults.set(themeColorName, forKey: themeColorKey)
    }
    
    func setDifficulty(_ value: Double) {
        difficulty = value
        saveSettings()
        recalculateHealth()
    }
    
    func setThemeColor(name: String) {
        themeColorName = name
        saveSettings()
    }
    
    // Reset everything back to "today" with a fresh pet
    func resetAllData() {
        logs.removeAll()
        pet = PetState.default
        currentDate = Date().startOfDay()
        save()
        recalculateHealth()
    }
    
    // Advance the simulated "today" to the next day
    func advanceToNextDay() {
        let cal = Calendar.current
        if let next = cal.date(byAdding: .day, value: 1, to: currentDate.startOfDay()) {
            currentDate = next
            recalculateHealth()
            save()
        }
    }
    
    // MARK: - Logs / Updates
    
    func logForToday() -> DayLog {
        let today = currentDate.startOfDay()
        if let existing = logs.first(where: { $0.date == today }) {
            return existing
        } else {
            let new = DayLog(date: today)
            logs.append(new)
            return new
        }
    }
    
    func updateToday(
        steps: Int? = nil,
        healthyMeals: Int? = nil,
        junkMeals: Int? = nil,
        sleepHours: Double? = nil,
        distanceKm: Double? = nil,
        flights: Int? = nil,
        bodyWeightKg: Double? = nil,
        bodyHeightM: Double? = nil
    ) {
        let today = currentDate.startOfDay()
        
        if let index = logs.firstIndex(where: { $0.date == today }) {
            var log = logs[index]
            if let s = steps { log.steps = max(0, s) }
            if let h = healthyMeals { log.healthyMeals = max(0, h) }
            if let j = junkMeals { log.junkMeals = max(0, j) }
            if let sh = sleepHours { log.sleepHours = max(0.0, sh) }
            if let d = distanceKm { log.distanceKm = max(0.0, d) }
            if let f = flights { log.flights = max(0, f) }
            if let w = bodyWeightKg { log.bodyWeightKg = w }
            if let ht = bodyHeightM { log.bodyHeightM = ht }
            logs[index] = log
        } else {
            var log = DayLog(date: today)
            if let s = steps { log.steps = max(0, s) }
            if let h = healthyMeals { log.healthyMeals = max(0, h) }
            if let j = junkMeals { log.junkMeals = max(0, j) }
            if let sh = sleepHours { log.sleepHours = max(0.0, sh) }
            if let d = distanceKm { log.distanceKm = max(0.0, d) }
            if let f = flights { log.flights = max(0, f) }
            if let w = bodyWeightKg { log.bodyWeightKg = w }
            if let ht = bodyHeightM { log.bodyHeightM = ht }
            logs.append(log)
        }
        
        recalculateHealth()
        save()
    }
    
    // MARK: - Health Logic (health + hunger + energy + mood)
    
    private func clamp01(_ x: Double) -> Double {
        max(0.0, min(1.0, x))
    }
    
    func recalculateHealth() {
        let today = currentDate.startOfDay()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: today)!.startOfDay()
        
        let recentLogs = logs.filter { $0.date >= sevenDaysAgo && $0.date <= today }
        
        // If no logs at all, set baseline
        guard !recentLogs.isEmpty else {
            pet.health = 0.6
            pet.experience = 0.0
            pet.hunger = 0.7
            pet.energy = 0.7
            pet.mood = 0.0
            return
        }
        
        var healthScores: [Double] = []
        var todaysHunger: Double = pet.hunger
        var todaysEnergy: Double = pet.energy
        
        // --- HEALTH / HUNGER / ENERGY from last 7 days ---
        for (idx, log) in recentLogs.enumerated() {
            // -------- Inputs --------
            let stepsRatio = clamp01(Double(log.steps) / 8_000.0)
            let distanceRatio = clamp01(log.distanceKm / 5.0)          // 5 km ~ "full"
            let flightsRatio = clamp01(Double(log.flights) / 10.0)     // 10 flights ~ "full"
            
            // Sleep: linear 0–8h → 0–1
            let sleepHours = max(0.0, log.sleepHours)
            let sleepFactor = clamp01(sleepHours / 8.0)                // 4h = 0.5
            
            // Food
            let totalMeals = log.healthyMeals + log.junkMeals
            let healthyNorm = clamp01(Double(log.healthyMeals) / 3.0)
            let junkNorm = clamp01(Double(log.junkMeals) / 3.0)
            
            // -------- Hunger (fullness) --------
            // 0 meals = 0, 1 = 1/3, 2 = 2/3, 3+ = 1
            var hungerFullness = Double(totalMeals) / 3.0
            hungerFullness = clamp01(hungerFullness)
            
            // -------- Energy --------
            // Only depends on sleep for now, resets daily
            let energyScore = sleepFactor
            
            // -------- BMI / body health --------
            var bmiScore = 0.5
            if let w = log.bodyWeightKg, let h = log.bodyHeightM, h > 0 {
                let bmi = w / (h * h)
                if bmi >= 18.5 && bmi <= 25 {
                    bmiScore = 1.0
                } else {
                    let diff = min(abs(bmi - 18.5), abs(bmi - 25.0))
                    bmiScore = clamp01(1.0 - diff / 10.0)
                }
            }
            
            // -------- Base physical health (no difficulty) --------
            var dailyBase = 0.0
            dailyBase += 0.25 * stepsRatio
            dailyBase += 0.20 * distanceRatio
            dailyBase += 0.10 * flightsRatio
            dailyBase += 0.20 * sleepFactor
            dailyBase += 0.15 * healthyNorm
            dailyBase += 0.10 * bmiScore
            dailyBase -= 0.10 * junkNorm
            dailyBase = clamp01(dailyBase)
            
            // -------- Apply difficulty to HEALTH ONLY --------
            let diffMult = max(0.1, difficulty)
            var dailyHealth = dailyBase / diffMult
            dailyHealth = clamp01(dailyHealth)
            
            healthScores.append(dailyHealth)
            
            // Capture TODAY’s hunger / energy from the last entry
            if idx == recentLogs.count - 1 {
                todaysHunger = hungerFullness
                todaysEnergy = energyScore
            }
        }
        
        // Overall health = avg of recent health scores
        let healthAverage = healthScores.reduce(0.0, +) / Double(healthScores.count)
        pet.health = healthAverage
        
        // -------- Mood (cumulative over ALL days) --------
        // mood = sum of contributions from every log, then clamped 0–1
        var moodRaw = 0.0
        for log in logs {
            let moodFromDistance = log.distanceKm * 0.01            // 1 km = 1%
            let moodFromFlights  = Double(log.flights) * 0.002      // 1 flight = 0.2%
            let moodFromSteps    = Double(log.steps) * 0.000002     // 500 steps = 0.1%
            
            moodRaw += moodFromDistance + moodFromFlights + moodFromSteps
        }
        pet.mood = clamp01(moodRaw)
        
        // -------- XP & levels (no cap) --------
        let daysLogged = Double(logs.count)
        let xp = healthAverage * 100.0 * daysLogged
        
        pet.experience = xp  // XP is an absolute number
        
        // Levels at XP thresholds: 100, 500, 2500, 5000, 10000
        if xp >= 10_000 {
            pet.level = 6
        } else if xp >= 5_000 {
            pet.level = 5
        } else if xp >= 2_500 {
            pet.level = 4
        } else if xp >= 500 {
            pet.level = 3
        } else if xp >= 100 {
            pet.level = 2
        } else {
            pet.level = 1
        }
        
        // -------- Hunger / Energy from TODAY only --------
        pet.hunger = todaysHunger
        pet.energy = todaysEnergy
        
        pet.lastUpdated = Date()
        save()
    }
    
    // MARK: - Helpers
    
    func sortedRecentLogs(limit: Int = 7) -> [DayLog] {
        let sorted = logs.sorted { $0.date > $1.date }
        return Array(sorted.prefix(limit)).sorted { $0.date < $1.date }
    }
}
