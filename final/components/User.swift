//
//  User.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//


import Foundation

struct User: Identifiable {
    var id: String // Unique user ID (Firebase UID)
    var email: String // User's email
    var name: String // User's display name
    var solvedDetails: [SolveDetail] // Array to store details of solved words
    var dailySolveCount: [String: Int] // Map of date (YYYY-MM-DD) to solve count
    var ratingHistory: [rating]
    var failedAttempts: Int

}

struct SolveDetail {
    var word: String // The word solved
    var solveTime: Double // Time taken to solve in seconds
    var attempts: Int // Number of attempts made
    var timestamp: Date // Date and time of solve
}

struct rating {
    var attempts: Int
    var rating: Double
    var solveTime: Double
    var success: Bool
    var timestamp: Date
    var word: String
}
