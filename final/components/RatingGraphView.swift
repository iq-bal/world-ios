//
//  RatingGraphView.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//


import SwiftUI
import Charts

struct RatingGraphView: View {
    let ratingHistory: [(Date, Int)] // Array of (Date, Rating) tuples

    var body: some View {
        VStack {
            Text("Rating Progress")
                .font(.headline)
                .padding(.bottom, 10)

            Chart {
                ForEach(ratingHistory, id: \.0) { entry in
                    LineMark(
                        x: .value("Date", entry.0),
                        y: .value("Rating", entry.1)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", entry.0),
                        y: .value("Rating", entry.1)
                    )
                    .foregroundStyle(.yellow)
                }
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel() // Display the rating values
                }
            }
            .frame(height: 300)
        }
        .padding()
    }
}

struct RatingGraphView_Previews: PreviewProvider {
    static var previews: some View {
        RatingGraphView(ratingHistory: mockRatingHistory)
    }
}

// Mock Data
let mockRatingHistory: [(Date, Int)] = {
    let calendar = Calendar.current
    var data: [(Date, Int)] = []
    let startDate = calendar.date(byAdding: .year, value: -1, to: Date())!

    for i in 0..<365 {
        let date = calendar.date(byAdding: .day, value: i, to: startDate)!
        let rating = 800 + Int.random(in: -100...100)
        data.append((date, rating))
    }

    return data
}()
