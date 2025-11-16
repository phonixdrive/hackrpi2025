// PetAIModel.swift
// HealthGotchi
//
// Shared Gemini client for daily coaching + pet chat.

import Foundation

final class PetAIModel {
    static let shared = PetAIModel()
    
    private init() {}
    
    private let modelName = "gemini-2.5-flash"
    
    // MARK: - Daily Advice
    
    /// Generates a short retro-style daily summary & suggestion.
    func generateDailyAdvice(
        steps: Int,
        sleepHours: Double,
        distanceKm: Double,
        flights: Int,
        health: Double,
        energy: Double,
        mood: Double,
        hunger: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let apiKey = Secrets.geminiApiKey
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent") else {
            completion(.failure(NSError(
                domain: "PetAIModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Bad URL"]
            )))
            return
        }
        
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
        
        let prompt = """
        You are a retro virtual pet coach living in a pixel Tamagotchi-like app.

        The user's day summary:
        - Steps: \(steps)
        - Sleep hours: \(String(format: "%.1f", sleepHours))
        - Distance walked: \(String(format: "%.2f", distanceKm)) km
        - Flights climbed: \(flights)
        - Pet health (0-1): \(String(format: "%.2f", health))
        - Pet energy (0-1): \(String(format: "%.2f", energy))
        - Pet mood (0-1): \(String(format: "%.2f", mood))
        - Pet hunger/fullness (0-1): \(String(format: "%.2f", hunger))

        In 2 short sentences, speak as the pet and:
        1) Briefly summarize how the day went.
        2) Give one practical suggestion for tomorrow.

        Style: old-school console text, positive, supportive, no emojis, no markdown.
        Respond with plain text only.
        """
        
        let body = GeminiRequest(
            contents: [
                .init(parts: [.init(text: prompt)])
            ],
            generationConfig: .init(
                temperature: 0.5,
                topP: 0.9,
                topK: 40
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // network fail
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(
                    domain: "PetAIModel",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "No data"]
                )))
                return
            }
            
            // HTTP error
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                print("PetAIModel daily advice HTTP \(http.statusCode): \(bodyString)")
                completion(.failure(NSError(
                    domain: "PetAIModel",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )))
                return
            }
            
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
                    let text = candidate.content.parts.first?.text
                else {
                    throw NSError(
                        domain: "PetAIModel",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "No candidates/text in response"]
                    )
                }
                completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            } catch {
                print("PetAIModel daily advice decode error:", error)
                if let body = String(data: data, encoding: .utf8) {
                    print("Raw body:", body)
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Pet Chat
    
    /// Generates a short supportive reply from the pet based on user message + pet status.
    func generateChatReply(
        pet: PetState,
        userMessage: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let apiKey = Secrets.geminiApiKey
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent") else {
            completion(.failure(NSError(
                domain: "PetAIModel",
                code: -10,
                userInfo: [NSLocalizedDescriptionKey: "Bad URL"]
            )))
            return
        }
        
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
        
        let prompt = """
        You are a tiny virtual pet in a retro Tamagotchi-style app.
        Your status:
        - Health: \(String(format: "%.2f", pet.health)) (0-1)
        - Energy: \(String(format: "%.2f", pet.energy)) (0-1)
        - Mood: \(String(format: "%.2f", pet.mood)) (0-1)
        - Hunger/fullness: \(String(format: "%.2f", pet.hunger)) (0-1)
        - Level: \(pet.level)

        The human just said:
        "\(userMessage)"

        Reply in 1–2 short sentences as the pet:
        - Acknowledge how they feel.
        - Give a tiny piece of encouragement or a small, realistic suggestion.
        Style: simple, warm, like old game dialogue. No emojis, no markdown.
        Respond with plain text only.
        """
        
        let body = GeminiRequest(
            contents: [
                .init(parts: [.init(text: prompt)])
            ],
            generationConfig: .init(
                temperature: 0.6,
                topP: 0.9,
                topK: 40
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(
                    domain: "PetAIModel",
                    code: -11,
                    userInfo: [NSLocalizedDescriptionKey: "No data"]
                )))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
                print("PetAIModel chat HTTP \(http.statusCode): \(bodyString)")
                completion(.failure(NSError(
                    domain: "PetAIModel",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )))
                return
            }
            
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
                    let text = candidate.content.parts.first?.text
                else {
                    throw NSError(
                        domain: "PetAIModel",
                        code: -12,
                        userInfo: [NSLocalizedDescriptionKey: "No candidates/text in response"]
                    )
                }
                completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            } catch {
                print("PetAIModel chat decode error:", error)
                if let body = String(data: data, encoding: .utf8) {
                    print("Raw body:", body)
                }
                completion(.failure(error))
            }
        }.resume()
    }
}
