//
//  HeatmapView.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//

import SwiftUI



struct HeatmapView: View {
    let solvedDates: Set<Date>

    var body: some View {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: Date()), month: 1, day: 1))!
        let allDates = (0..<365).compactMap { calendar.date(byAdding: .day, value: $0, to: yearStart) }
        let columns = 27 // 27 columns (14 rows * 27 columns = 378 slots, sufficient for 365 days)
        let rows = 14 // Adjusted to 14 rows for better screen fit

        let grid = generateGrid(from: allDates, rows: rows, columns: columns)

        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<columns, id: \.self) { col in
                        if let date = grid[row][col] {
                            Circle()
                                .fill(solvedDates.contains(date) ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 10, height: 10)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func generateGrid(from dates: [Date], rows: Int, columns: Int) -> [[Date?]] {
        var grid = Array(repeating: Array(repeating: nil as Date?, count: columns), count: rows)
        for (index, date) in dates.enumerated() {
            let row = index % rows
            let column = index / rows
            if column < columns {
                grid[row][column] = date
            }
        }
        return grid
    }
}
