//
//  RatingGraphView.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//


import SwiftUI
import Charts

struct RatingGraphView: View {
    let ratingHistory: [(Date, Int)]
    
    private var yAxisValues: [Int] {
        guard let minRating = ratingHistory.map({ $0.1 }).min(),
              let maxRating = ratingHistory.map({ $0.1 }).max() else {
            return [800, 900, 1000, 1100, 1200] // Default values
        }
        
        let step = 100
        let minValue = (minRating / step) * step // Round down to nearest hundred
        let maxValue = ((maxRating + step) / step) * step // Round up to nearest hundred
        
        return stride(from: minValue, through: maxValue, by: step).map { $0 }
    }
    
    var body: some View {
        Chart {
            ForEach(ratingHistory, id: \.0) { entry in
                LineMark(
                    x: .value("Date", entry.0),
                    y: .value("Rating", entry.1)
                )
                .foregroundStyle(AppColors.primary.gradient)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", entry.0),
                    y: .value("Rating", entry.1)
                )
                .foregroundStyle(AppColors.accent)
                .symbolSize(50)
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: .month)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(preset: .aligned, values: yAxisValues.map { Double($0) }) { value in
                AxisValueLabel {
                    Text("\(value.index)")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: 10))
                }
                AxisGridLine()
            }
        }
        .padding(.vertical, AppSpacing.md)
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
