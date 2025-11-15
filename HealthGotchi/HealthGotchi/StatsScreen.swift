//
//  StatsScreen.swift
//  HealthGotchi
//
//  Created by Neil Shrestha on 11/15/25.
//
import SwiftUI

struct StatsScreen: View {
    @EnvironmentObject var viewModel: HealthPetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Stats")
                .font(.title2)
                .bold()
            
            Text("Last 7 days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            List {
                ForEach(viewModel.sortedRecentLogs()) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateString(log.date))
                                .font(.headline)
                            Text("Steps: \(log.steps)")
                                .font(.subheadline)
                            Text("Healthy: \(log.healthyMeals) · Junk: \(log.junkMeals)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.top)
    }
    
    func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        return df.string(from: date)
    }
}

#Preview {
    StatsScreen()
        .environmentObject(HealthPetViewModel())
}
