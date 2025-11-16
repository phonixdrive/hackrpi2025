//
//  HealthManager.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import Foundation
import HealthKit

struct HealthSnapshot {
    var steps: Int
    var distanceKm: Double
    var flights: Int
    var sleepHours: Double
    var bodyWeightKg: Double?
    var bodyHeightM: Double?
}

class HealthManager {
    private let healthStore = HKHealthStore()
    
    private var stepType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .stepCount)
    }
    
    private var distanceType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
    }
    
    private var flightsType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .flightsClimbed)
    }
    
    private var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }
    
    private var bodyMassType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .bodyMass)
    }
    
    private var heightType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .height)
    }
    
    func isHealthDataAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        var readTypes = Set<HKObjectType>()
        
        if let stepType = stepType { readTypes.insert(stepType) }
        if let distanceType = distanceType { readTypes.insert(distanceType) }
        if let flightsType = flightsType { readTypes.insert(flightsType) }
        if let sleepType = sleepType { readTypes.insert(sleepType) }
        if let bodyMassType = bodyMassType { readTypes.insert(bodyMassType) }
        if let heightType = heightType { readTypes.insert(heightType) }
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit auth error:", error)
            }
            completion(success)
        }
    }
    
    func fetchTodaySnapshot(completion: @escaping (HealthSnapshot?) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        var dayEndComponents = DateComponents()
        dayEndComponents.day = 1
        dayEndComponents.second = -1
        let endOfDay = calendar.date(byAdding: dayEndComponents, to: startOfDay) ?? now
        
        let dayPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Last night’s sleep: previous day start → today start
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        let sleepPredicate = HKQuery.predicateForSamples(
            withStart: startOfYesterday,
            end: startOfDay,
            options: .strictStartDate
        )
        
        let group = DispatchGroup()
        
        var stepsValue: Double = 0
        var distanceValue: Double = 0
        var flightsValue: Double = 0
        var sleepSeconds: Double = 0
        var bodyWeightKg: Double?
        var bodyHeightM: Double?
        
        // Steps
        if let stepType = stepType {
            group.enter()
            let q = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: dayPredicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Steps query error:", error)
                }
                if let sum = result?.sumQuantity() {
                    stepsValue = sum.doubleValue(for: HKUnit.count())
                }
                group.leave()
            }
            healthStore.execute(q)
        }
        
        // Distance (km)
        if let distanceType = distanceType {
            group.enter()
            let q = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: dayPredicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Distance query error:", error)
                }
                if let sum = result?.sumQuantity() {
                    let meters = sum.doubleValue(for: HKUnit.meter())
                    distanceValue = meters / 1000.0
                }
                group.leave()
            }
            healthStore.execute(q)
        }
        
        // Flights climbed
        if let flightsType = flightsType {
            group.enter()
            let q = HKStatisticsQuery(
                quantityType: flightsType,
                quantitySamplePredicate: dayPredicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Flights query error:", error)
                }
                if let sum = result?.sumQuantity() {
                    flightsValue = sum.doubleValue(for: HKUnit.count())
                }
                group.leave()
            }
            healthStore.execute(q)
        }
        
        // Sleep (last night)
        if let sleepType = sleepType {
            group.enter()
            let q = HKSampleQuery(
                sampleType: sleepType,
                predicate: sleepPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("Sleep query error:", error)
                }
                
                if let samples = samples as? [HKCategorySample] {
                    for sample in samples {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        sleepSeconds += duration
                    }
                }
                group.leave()
            }
            healthStore.execute(q)
        }
        
        // Body weight (latest)
        if let bodyMassType = bodyMassType {
            group.enter()
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    print("Body mass query error:", error)
                }
                if let s = samples?.first as? HKQuantitySample {
                    let kg = s.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                    bodyWeightKg = kg
                }
                group.leave()
            }
            healthStore.execute(q)
        }
        
        // Height (latest)
        if let heightType = heightType {
            group.enter()
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    print("Height query error:", error)
                }
                if let s = samples?.first as? HKQuantitySample {
                    let meters = s.quantity.doubleValue(for: HKUnit.meter())
                    bodyHeightM = meters
                }
                group.leave()
            }
            healthStore.execute(q)
        }
        
        group.notify(queue: .main) {
            let snapshot = HealthSnapshot(
                steps: Int(stepsValue),
                distanceKm: distanceValue,
                flights: Int(flightsValue),
                sleepHours: sleepSeconds / 3600.0,
                bodyWeightKg: bodyWeightKg,
                bodyHeightM: bodyHeightM
            )
            completion(snapshot)
        }
    }
}
