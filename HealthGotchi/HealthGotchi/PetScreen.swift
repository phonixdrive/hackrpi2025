import SwiftUI

struct PetScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    
    private var themeColor: Color {
        color(for: viewModel.themeColorName)
    }
    
    var body: some View {
        ZStack {
            // Retro background (fake CRT)
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 12) {     // ⬅ was 24 — reduced spacing

                Text("HEALTHGOTCHI")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(themeColor)
                    .padding(.top, 10)
                
                Text("LEVEL \(viewModel.pet.level)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(themeColor.opacity(0.9))
                
                // Pixel Sprite
                pixelPetView()
                    .retroCard(theme: themeColor)
                    .padding(.top, 4)        // NEW slight bump up
                
                // MAIN HEALTH BAR
                VStack(alignment: .leading, spacing: 8) {
                    Text("HEALTH")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(themeColor)
                    
                    statBar(value: viewModel.pet.health)
                    
                    HStack {
                        Text(String(format: "%3d%%", Int(viewModel.pet.health * 100)))
                        Spacer()
                        Text(String(format: "XP %d", Int(viewModel.pet.experience)))
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(themeColor.opacity(0.9))
                }
                .retroCard(theme: themeColor)
                .padding(.top, 4)        // NEW
                
                // HUNGER / ENERGY / MOOD
                VStack(alignment: .leading, spacing: 10) {
                    Text("STATS")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(themeColor)
                    
                    labeledStatBar(label: "HUNGER", value: viewModel.pet.hunger)
                    labeledStatBar(label: "ENERGY", value: viewModel.pet.energy)
                    labeledStatBar(label: "MOOD", value: viewModel.pet.mood)
                }
                .retroCard(theme: themeColor)
                .padding(.top, 4)        // NEW
                
                // STATUS / SPEECH BUBBLE
                Text(petMessage())
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(themeColor.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .retroCard(theme: themeColor)
                    .padding(.bottom, 20)    // ⬅ gives breathing room above bottom buttons
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Pixel Pet
    
    @ViewBuilder
    private func pixelPetView() -> some View {
        let spriteName = petSpriteName()
        
        VStack(spacing: 8) {
            if UIImage(named: spriteName) != nil {
                Image(spriteName)
                    .resizable()
                    .interpolation(.none) // important for pixel look
                    .scaledToFit()
                    .frame(width: 160, height: 160)
            } else {
                Text("Missing sprite: \(spriteName)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(themeColor)
                    .frame(width: 120, height: 120)
            }
            
            Text(petMoodLabel())
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(themeColor.opacity(0.85))
        }
    }
    
    private func petSpriteName() -> String {
        let h = viewModel.pet.health
        let hunger = viewModel.pet.hunger
        let energy = viewModel.pet.energy
        let mood = viewModel.pet.mood
        
        if hunger <= 0.05 {
            return "dead"
        }
        if h < 0.35 {
            return "sick"
        }
        if hunger < 0.3 {
            return "hungry"
        }
        if h >= 0.75 && energy >= 0.7 && mood >= 0.7 {
            return "happy"
        }
        if h >= 0.5 && energy >= 0.4 && mood >= 0.4 {
            return "okay"
        }
        return "sad"
    }
    
    private func petMoodLabel() -> String {
        let hunger = viewModel.pet.hunger
        let energy = viewModel.pet.energy
        let mood = viewModel.pet.mood
        
        if hunger <= 0.05 {
            return "STATUS: STARVED"
        } else if hunger < 0.3 {
            return "STATUS: HUNGRY"
        }
        
        if mood >= 0.8 && energy >= 0.7 {
            return "STATUS: VERY HAPPY"
        } else if mood >= 0.6 {
            return "STATUS: CONTENT"
        } else if mood >= 0.4 {
            return "STATUS: MEH"
        } else if energy < 0.3 {
            return "STATUS: EXHAUSTED"
        } else {
            return "STATUS: SAD"
        }
    }
    
    private func petMessage() -> String {
        let h = viewModel.pet.health
        let hunger = viewModel.pet.hunger
        let energy = viewModel.pet.energy
        let mood = viewModel.pet.mood
        
        if hunger <= 0.05 {
            return "I'M OUT OF FUEL.\nFEED ME OR I FADE AWAY..."
        }
        
        if h < 0.35 {
            return "I FEEL SICK.\nTOO MUCH JUNK OR NOT ENOUGH\nMOVEMENT. LET'S FIX THAT."
        }
        
        if hunger < 0.3 {
            return "I'M REALLY HUNGRY.\nA BALANCED MEAL WOULD HELP\nMY HEALTH AND MOOD."
        }
        
        if energy < 0.4 {
            return "I'M TIRED.\nSOME CONSISTENT SLEEP WOULD\nRESTORE MY ENERGY."
        }
        
        if mood < 0.4 {
            return "I'M FEELING DOWN.\nA WALK, GOOD SLEEP,\nAND DECENT FOOD COULD HELP."
        }
        
        if h >= 0.75 && energy >= 0.7 && mood >= 0.7 {
            return "I FEEL GREAT.\nKEEP UP THE SLEEP, STEPS,\nAND MOSTLY CLEAN EATING!"
        }
        
        return "I'M DOING OKAY.\nA FEW MORE STEPS AND A LITTLE\nLESS JUNK WOULD BE PERFECT."
    }
    
    // MARK: - Bars
    
    private func statBar(value: Double) -> some View {
        GeometryReader { geo in
            let clamped = max(0.0, min(1.0, value))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeColor.opacity(0.15))
                    .frame(height: 18)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeColor)
                    .frame(width: max(4, geo.size.width * clamped),
                           height: 18)
            }
        }
        .frame(height: 18)
    }
    
    private func labeledStatBar(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%3d%%", Int(max(0.0, min(1.0, value)) * 100)))
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(themeColor.opacity(0.9))
            
            statBar(value: value)
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
    PetScreen()
        .environmentObject(HealthPetViewModel())
}
