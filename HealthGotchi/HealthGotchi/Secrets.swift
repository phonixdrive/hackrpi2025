//
//  Secrets.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/16/25.
//
// Secrets.swift
import Foundation

enum Secrets {
    static var geminiApiKey: String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = plist["GEMINI_API_KEY"] as? String
        else {
            fatalError("GEMINI_API_KEY not found in Secrets.plist")
        }
        return key
    }
}
