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
    
    private let petKey = "pet_state_v1"
    private let logsKey = "day_logs_v1"
    
    private let stepsGoal = 8000
    private let healthyWeight = 0.2
    private let junkWeight = 0.25
    private let stepsWeight = 0.55
    
    init() {
        self.pet = PetState.default
        self.logs = []
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
    }
    
    // MARK: - Logs / Updates
    
    func logForToday() -> DayLog {
        let today = Date().startOfDay()
        if let existing = logs.first(where: { $0.date == today }) {
            return existing
        } else {
            let new = DayLog(date: today)
            logs.append(new)
            return new
        }
    }
    
    func updateToday(steps: Int? = nil,
                     healthyMeals: Int? = nil,
                     junkMeals: Int? = nil) {
        let today = Date().startOfDay()
        
        if let index = logs.firstIndex(where: { $0.date == today }) {
            var log = logs[index]
            if let s = steps { log.steps = max(0, s) }
            if let h = healthyMeals { log.healthyMeals = max(0, h) }
            if let j = junkMeals { log.junkMeals = max(0, j) }
            logs[index] = log
        } else {
            var log = DayLog(date: today)
            if let s = steps { log.steps = max(0, s) }
            if let h = healthyMeals { log.healthyMeals = max(0, h) }
            if let j = junkMeals { log.junkMeals = max(0, j) }
            logs.append(log)
        }
        
        recalculateHealth()
        save()
    }
    
    // MARK: - Health Logic
    
    func recalculateHealth() {
        // Look at the last 7 days
        let today = Date().startOfDay()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: today)!.startOfDay()
        
        let recentLogs = logs.filter { $0.date >= sevenDaysAgo && $0.date <= today }
        guard !recentLogs.isEmpty else {
            pet.health = 0.6
            pet.experience = 0.0
            return
        }
        
        var scores: [Double] = []
        
        for log in recentLogs {
            let stepRatio = min(1.0, Double(log.steps) / Double(stepsGoal))
            
            // Cap meals at 2+ for scoring so it doesn't explode
            let healthyScore = min(2.0, Double(log.healthyMeals)) / 2.0   // 0.0–1.0
            let junkScore = min(2.0, Double(log.junkMeals)) / 2.0         // 0.0–1.0
            
            var daily = 0.0
            daily += stepsWeight * stepRatio
            daily += healthyWeight * healthyScore
            daily -= junkWeight * junkScore
            
            // Clamp between 0 and 1
            daily = max(0.0, min(1.0, daily))
            scores.append(daily)
        }
        
        let average = scores.reduce(0.0, +) / Double(scores.count)
        pet.health = average
        
        // Simple “XP” as moving average of last 3 days
        let lastThree = Array(scores.suffix(3))
        let xp = lastThree.reduce(0.0, +) / Double(lastThree.count)
        pet.experience = xp
        
        // Level logic
        if pet.health >= 0.8 && pet.experience >= 0.7 {
            pet.level = max(pet.level, 2)
        } else if pet.health >= 0.9 && pet.experience >= 0.85 {
            pet.level = max(pet.level, 3)
        } else if pet.health < 0.4 {
            pet.level = 1
        }
        
        pet.lastUpdated = Date()
        
        save()
    }
    
    // MARK: - Helpers
    
    func sortedRecentLogs(limit: Int = 7) -> [DayLog] {
        let sorted = logs.sorted { $0.date > $1.date }
        return Array(sorted.prefix(limit)).sorted { $0.date < $1.date }
    }
}
