// PetChatScreen.swift
// HealthGotchi
//
// Simple retro chat with your pet, backed by Gemini.

import SwiftUI

private struct ChatMessage: Identifiable {
    let id = UUID()
    let isPet: Bool
    let text: String
}

struct PetChatScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @FocusState private var inputFocused: Bool
    
    private var themeColor: Color {
        color(for: viewModel.themeColorName)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.07, green: 0.05, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("TALK TO YOUR PET")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(themeColor)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Chat log
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isPet {
                                    Text("PET:")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(themeColor)
                                    Text(msg.text)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(themeColor.opacity(0.9))
                                    Spacer()
                                } else {
                                    Spacer()
                                    Text(msg.text)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(8)
                            .background(
                                msg.isPet ?
                                Color.black.opacity(0.9) :
                                Color.white.opacity(0.05)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(msg.isPet ? themeColor : Color.gray.opacity(0.4), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Input bar
                HStack(alignment: .center, spacing: 8) {
                    TextField("Tell your pet how you feel...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)
                        .padding(8)
                        .background(Color(white: 0.12))
                        .foregroundColor(themeColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeColor, lineWidth: 1.5)
                        )
                        .cornerRadius(8)
                        .focused($inputFocused)
                    
                    Button {
                        sendMessage()
                    } label: {
                        HStack(spacing: 4) {
                            if isSending {
                                ProgressView()
                            }
                            Text("SEND")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(themeColor)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            setupInitialMessage()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    inputFocused = false
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private func setupInitialMessage() {
        // First line: question based on current pet state (no AI needed).
        let pet = viewModel.pet
        let opening: String
        
        if pet.hunger < 0.3 {
            opening = "I feel pretty hungry… have you been eating okay today?"
        } else if pet.energy < 0.4 {
            opening = "I’m really low on energy. Are you feeling tired lately too?"
        } else if pet.mood < 0.4 {
            opening = "I’ve been a bit down. Has your mood been rough recently?"
        } else if pet.health < 0.5 {
            opening = "My health feels off. Are you taking care of yourself alright?"
        } else {
            opening = "I’m feeling pretty good. What’s been on your mind today?"
        }
        
        messages = [
            ChatMessage(isPet: true, text: opening)
        ]
    }
    
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        inputFocused = false
        isSending = true
        
        // Add user message
        messages.append(ChatMessage(isPet: false, text: trimmed))
        inputText = ""
        
        // Ask AI for pet's reply
        let pet = viewModel.pet
        PetAIModel.shared.generateChatReply(pet: pet, userMessage: trimmed) { result in
            DispatchQueue.main.async {
                self.isSending = false
                switch result {
                case .success(let text):
                    self.messages.append(ChatMessage(isPet: true, text: text))
                    
                    // Small mood boost for opening up
                    func clamp(_ x: Double) -> Double { max(0.0, min(1.0, x)) }
                    self.viewModel.pet.mood = clamp(self.viewModel.pet.mood + 0.05)
                    self.viewModel.save()
                    
                case .failure(let error):
                    self.messages.append(ChatMessage(isPet: true, text: "Hmm… I’m having trouble thinking right now (\(error.localizedDescription))."))
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

#Preview {
    PetChatScreen()
        .environmentObject(HealthPetViewModel())
}
