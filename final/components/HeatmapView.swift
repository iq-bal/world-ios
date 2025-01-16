//
//  HeatmapView.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//

import SwiftUI

struct HeatmapView: View {
    let solvedDates: Set<Date>
    private let cellSize: CGFloat = 8
    private let spacing: CGFloat = 2
    private let monthLabelHeight: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month labels
            MonthLabels()
                .frame(height: monthLabelHeight)
                .padding(.leading, 20)
            
            HStack(alignment: .top, spacing: spacing) {
                // Day labels
                DayLabels(cellSize: cellSize)
                    .padding(.top, spacing)
                
                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(getWeeks().reversed(), id: \.startDate) { week in
                            WeekColumn(week: week, solvedDates: solvedDates, cellSize: cellSize)
                        }
                    }
                    .padding(.vertical, spacing)
                }
                .padding(.trailing, AppSpacing.md)
            }
        }
    }
    
    private func getWeeks() -> [Week] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -364, to: endDate)! // -364 to include today
        
        var weeks: [Week] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekDates = (0..<7).compactMap { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: currentDate)
                return date?.timeIntervalSince1970 ?? 0 <= endDate.timeIntervalSince1970 ? date : nil
            }.compactMap { $0 } // Remove nil values
            
            if !weekDates.isEmpty {
                weeks.append(Week(dates: weekDates, startDate: currentDate))
            }
            
            if let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate),
               nextWeek <= endDate {
                currentDate = nextWeek
            } else {
                break
            }
        }
        
        return weeks
    }
}

struct Week {
    let dates: [Date]
    let startDate: Date
}

struct WeekColumn: View {
    let week: Week
    let solvedDates: Set<Date>
    let cellSize: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(week.dates.reversed(), id: \.self) { date in
                ContributionCell(date: date, solvedDates: solvedDates)
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }
}

struct ContributionCell: View {
    let date: Date
    let solvedDates: Set<Date>
    
    var body: some View {
        let count = getContributionCount(for: date)
        RoundedRectangle(cornerRadius: 1)
            .fill(colorForContributions(count))
    }
    
    private func getContributionCount(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return solvedDates.contains(startOfDay) ? 1 : 0
    }
    
    private func colorForContributions(_ count: Int) -> Color {
        if count > 0 {
            return Color(red: 64/255, green: 196/255, blue: 99/255)
        }
        return Color(red: 235/255, green: 237/255, blue: 240/255)
    }
}

struct MonthLabels: View {
    var body: some View {
        HStack(spacing: 20) {
            ForEach(getMonthLabels(), id: \.self) { month in
                Text(month)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func getMonthLabels() -> [String] {
        let months = Calendar.current.shortMonthSymbols
        let currentMonth = Calendar.current.component(.month, from: Date())
        var orderedMonths: [String] = []
        
        for i in (0..<12).reversed() {
            let index = (currentMonth - i - 1 + 12) % 12
            orderedMonths.append(months[index])
        }
        
        return orderedMonths.reversed()
    }
}

struct DayLabels: View {
    let days = ["", "Mon", "", "Wed", "", "Fri", ""]
    let cellSize: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .frame(width: 20, alignment: .leading)
                    .frame(height: cellSize + 2)
            }
        }
        .padding(.top, 2)
    }
}

// Preview
struct HeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapView(solvedDates: Set([Date(), Date().addingTimeInterval(-86400)]))
            .frame(height: 200)
            .padding()
    }
}
