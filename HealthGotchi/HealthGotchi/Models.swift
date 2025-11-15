//
//  Models.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import Foundation

struct DayLog: Identifiable, Codable {
    let id: UUID
    var date: Date
    var steps: Int
    var healthyMeals: Int
    var junkMeals: Int
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         steps: Int = 0,
         healthyMeals: Int = 0,
         junkMeals: Int = 0) {
        self.id = id
        self.date = date.startOfDay()
        self.steps = steps
        self.healthyMeals = healthyMeals
        self.junkMeals = junkMeals
    }
}

struct PetState: Codable {
    var name: String
    var health: Double   // 0.0 to 1.0
    var level: Int
    var experience: Double  // 0.0 to 1.0
    var lastUpdated: Date
    
    static let `default` = PetState(
        name: "Tamo",
        health: 0.6,
        level: 1,
        experience: 0.0,
        lastUpdated: Date()
    )
}

// Helper: normalize dates to midnight for comparing "today"
extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}
