// FoodAIModel.swift
// HealthGotchi
//
// A tiny Gemini client that takes a meal description
// and returns health/energy/mood impact.

import Foundation

// MARK: - Public model you can use in the rest of the app

struct FoodEffect: Codable {
    let healthDelta: Double   // -0.3 ... +0.3
    let energyDelta: Double   // -0.3 ... +0.3
    let moodDelta: Double     // -0.3 ... +0.3
    let explanation: String
}

// MARK: - Gemini client

final class FoodAIModel {
    static let shared = FoodAIModel()
    
    private init() {}
    
    // Use a currently-supported model
    private let modelName = "gemini-2.5-flash"
    
    /// Call this with the meal text, like "big mac, fries, large coke"
    func analyzeMeal(
        _ mealDescription: String,
        completion: @escaping (Result<FoodEffect, Error>) -> Void
    ) {
        let apiKey = Secrets.geminiApiKey
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent") else {
            completion(.failure(NSError(
                domain: "FoodAIModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Bad URL"]
            )))
            return
        }
        
        // Gemini request body structure
        struct GeminiRequest: Encodable {
            struct Content: Encodable {
                struct Part: Encodable {
                    let text: String
                }
                let parts: [Part]
            }
            
            let contents: [Content]
            let generationConfig: GenerationConfig
            
            struct GenerationConfig: Encodable {
                let temperature: Double
                let topP: Double
                let topK: Int
            }
        }
        
        let systemPrompt = """
        You are a nutrition assistant for a health Tamagotchi app.
        The user will give you a description of a meal.

        You must respond ONLY with valid JSON in this exact format:
        {
          "health_delta": number between -0.3 and 0.3,
          "energy_delta": number between -0.3 and 0.3,
          "mood_delta": number between -0.3 and 0.3,
          "explanation": "short explanation"
        }

        "health_delta" reflects long-term health impact (negative for unhealthy, positive for very healthy).
        "energy_delta" reflects short-term physical energy after the meal.
        "mood_delta" reflects pleasure/satisfaction/comfort from the meal.

        Do NOT wrap the JSON in markdown code fences like ```json or ```; just return raw JSON.
        Do NOT add any extra text, comments, or explanation outside the JSON.
        """
        
        let userPrompt = "Meal: \(mealDescription)"
        
        let body = GeminiRequest(
            contents: [
                .init(
                    parts: [.init(text: systemPrompt + "\n\n" + userPrompt)]
                )
            ],
            generationConfig: .init(
                temperature: 0.4,
                topP: 0.9,
                topK: 40
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Auth via header
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Network error
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(
                    domain: "FoodAIModel",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "No data"]
                )))
                return
            }
            
            // Check HTTP status code first
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                print("Gemini HTTP error \(http.statusCode): \(bodyString)")
                
                // Try to surface a human-readable error
                if
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let errorDict = json["error"] as? [String: Any],
                    let message = errorDict["message"] as? String
                {
                    completion(.failure(NSError(
                        domain: "FoodAIModel",
                        code: http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini error: \(message)"]
                    )))
                } else {
                    completion(.failure(NSError(
                        domain: "FoodAIModel",
                        code: http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini HTTP \(http.statusCode): \(bodyString)"]
                    )))
                }
                return
            }
            
            // Response schema (success case)
            struct GeminiResponse: Decodable {
                struct Candidate: Decodable {
                    struct Content: Decodable {
                        struct Part: Decodable {
                            let text: String?
                        }
                        let parts: [Part]
                    }
                    let content: Content
                }
                let candidates: [Candidate]?
            }
            
            do {
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                guard
                    let candidate = decoded.candidates?.first,
                    let rawText = candidate.content.parts.first?.text
                else {
                    throw NSError(
                        domain: "FoodAIModel",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "No candidates or text in Gemini response"]
                    )
                }
                
                // Strip markdown fences if the model ignored our instructions
                let cleanedText = Self.stripCodeFences(from: rawText)
                
                let jsonData = Data(cleanedText.utf8)
                
                struct RawFoodEffect: Decodable {
                    let health_delta: Double
                    let energy_delta: Double
                    let mood_delta: Double
                    let explanation: String
                }
                
                let raw = try JSONDecoder().decode(RawFoodEffect.self, from: jsonData)
                
                let effect = FoodEffect(
                    healthDelta: raw.health_delta,
                    energyDelta: raw.energy_delta,
                    moodDelta: raw.mood_delta,
                    explanation: raw.explanation
                )
                
                completion(.success(effect))
            } catch {
                print("FoodAIModel decode error: \(error)")
                if let bodyString = String(data: data, encoding: .utf8) {
                    print("Raw Gemini body:", bodyString)
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Helpers
    
    /// Removes ```json / ``` fences and trims whitespace.
    private static func stripCodeFences(from text: String) -> String {
        var result = text
        
        // Common patterns the model might use
        result = result.replacingOccurrences(of: "```json", with: "")
        result = result.replacingOccurrences(of: "```JSON", with: "")
        result = result.replacingOccurrences(of: "```", with: "")
        
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extra safety: if it still has junk around the JSON, try to grab the substring
        // from the first '{' to the last '}'.
        if let firstBrace = result.firstIndex(of: "{"),
           let lastBrace = result.lastIndex(of: "}") {
            let range = firstBrace...lastBrace
            result = String(result[range])
        }
        
        return result
    }
}
