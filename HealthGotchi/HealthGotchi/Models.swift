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
    
    // Activity
    var steps: Int
    var distanceKm: Double       // walking + running distance for the day
    var flights: Int             // flights climbed
    
    // Lifestyle
    var healthyMeals: Int
    var junkMeals: Int
    var sleepHours: Double       // last night’s sleep
    
    // Body
    var bodyWeightKg: Double?    // latest body mass
    var bodyHeightM: Double?     // height in meters
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        steps: Int = 0,
        distanceKm: Double = 0.0,
        flights: Int = 0,
        healthyMeals: Int = 0,
        junkMeals: Int = 0,
        sleepHours: Double = 0.0,
        bodyWeightKg: Double? = nil,
        bodyHeightM: Double? = nil
    ) {
        self.id = id
        self.date = date.startOfDay()
        self.steps = steps
        self.distanceKm = distanceKm
        self.flights = flights
        self.healthyMeals = healthyMeals
        self.junkMeals = junkMeals
        self.sleepHours = sleepHours
        self.bodyWeightKg = bodyWeightKg
        self.bodyHeightM = bodyHeightM
    }
}

struct PetState: Codable {
    var name: String
    
    /// Overall health (0...1)
    var health: Double
    
    /// Pet level (based on long-term health/xp)
    var level: Int
    
    /// XP (0...1) – used for leveling
    var experience: Double
    
    /// Hunger/fullness (0...1). 0 = starving (skull), 1 = well-fed.
    var hunger: Double
    
    /// Energy (0...1). 0 = exhausted, 1 = fully rested.
    var energy: Double
    
    /// Mood (0...1). 0 = miserable, 1 = very happy.
    var mood: Double
    
    var lastUpdated: Date
    
    static let `default` = PetState(
        name: "Tamo",
        health: 0.7,
        level: 1,
        experience: 0.0,
        hunger: 0.7,
        energy: 0.7,
        mood: 0.7,
        lastUpdated: Date()
    )
}

// Helper: normalize dates to midnight for comparing "today"
extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}
