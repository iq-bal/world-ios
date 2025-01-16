import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @State private var user: User? // Store user data dynamically
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView { // Added ScrollView for scrollable content
                VStack {
                    if let user = user {
                        // Profile Picture
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .padding(.top, 30)

                        // User Info
                        Text(user.name) // Display user name
                            .font(.headline)
                            .padding(.top, 10)
                        Text(user.email) // Display user email
                            .foregroundColor(.gray)

                        // Personal Stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Stats")
                                .font(.subheadline)
                                .padding(.top, 20)

                            StatRow(title: "Total Games Played", value: "\(totalGamesPlayed(user))")
                            StatRow(title: "Win Percentage", value: "\(String(format: "%.1f", winPercentage(user)))%")
                            StatRow(title: "Longest Streak", value: "\(longestStreak(user))")
                            StatRow(title: "Average Attempts", value: "\(String(format: "%.2f", averageAttempts(user)))")
                        }
                        .padding()

                        // Heatmap
                        VStack {
                            Text("Activity Heatmap")
                                .font(.subheadline)
                                .padding(.top, 20)

                            HeatmapView(solvedDates: solvedDates(user))
                        }
                        .padding()

                        // Rating Graph View
                        VStack {
                            Text("Your Rating Progress")
                                .font(.subheadline)
                                .padding(.top, 20)

                            if !user.ratingHistory.isEmpty {
                                RatingGraphView(ratingHistory: ratingHistory(user))
                                    .frame(height: 300) // Set a fixed height for the chart
                            } else {
                                Text("No rating data available.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 10)
                            }
                        }
                        .padding()

                        Spacer()

                        // Logout Button
                        Button(action: logout) {
                            Text("Log Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    } else {
                        // Loading State
                        ProgressView("Loading profile...")
                            .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: fetchUserData)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }

    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            if let document = document, let data = document.data() {
                self.user = parseUserData(id: document.documentID, data: data)
                print("User data fetched: \(String(describing: self.user))")
            }
        }
    }

    private func parseUserData(id: String, data: [String: Any]) -> User {
        let email = data["email"] as? String ?? "Unknown Email"
        let name = data["name"] as? String ?? "Unknown Name"
        let failedAttempts = data["failedAttempts"] as? Int ?? 0

        let solvedDetails: [SolveDetail] = (data["solvedDetails"] as? [[String: Any]] ?? []).compactMap { detail in
            guard let word = detail["word"] as? String,
                  let solveTime = detail["solveTime"] as? Double,
                  let attempts = detail["attempts"] as? Int,
                  let timestamp = detail["timestamp"] as? Timestamp else { return nil }
            return SolveDetail(word: word, solveTime: solveTime, attempts: attempts, timestamp: timestamp.dateValue())
        }

        let ratingHistory: [rating] = (data["ratingHistory"] as? [[String: Any]] ?? []).compactMap { entry in
            guard let attempts = entry["attempts"] as? Int,
                  let ratingValue = entry["rating"] as? Double,
                  let solveTime = entry["solveTime"] as? Double,
                  let success = entry["success"] as? Bool,
                  let timestamp = entry["timestamp"] as? Timestamp,
                  let word = entry["word"] as? String else { return nil }
            return rating(attempts: attempts, rating: ratingValue, solveTime: solveTime, success: success, timestamp: timestamp.dateValue(), word: word)
        }

        let dailySolveCount = data["dailySolveCount"] as? [String: Int] ?? [:]

        return User(id: id, email: email, name: name, solvedDetails: solvedDetails, dailySolveCount: dailySolveCount, ratingHistory: ratingHistory, failedAttempts: failedAttempts)
    }

    // Derived metrics
    private func totalGamesPlayed(_ user: User) -> Int {
        return user.solvedDetails.count + user.failedAttempts
    }

    private func winPercentage(_ user: User) -> Double {
        let wins = user.solvedDetails.count
        let total = totalGamesPlayed(user)
        return total > 0 ? (Double(wins) / Double(total)) * 100 : 0
    }

    private func longestStreak(_ user: User) -> Int {
        // Placeholder: Implement streak calculation if needed
        return user.dailySolveCount.values.max() ?? 0
    }

    private func averageAttempts(_ user: User) -> Double {
        guard !user.solvedDetails.isEmpty else { return 0.0 }
        let totalAttempts = user.solvedDetails.reduce(0) { $0 + $1.attempts }
        return Double(totalAttempts) / Double(user.solvedDetails.count)
    }

    private func solvedDates(_ user: User) -> Set<Date> {
        return Set(user.solvedDetails.map { Calendar.current.startOfDay(for: $0.timestamp) })
    }

    private func ratingHistory(_ user: User) -> [(Date, Int)] {
        return user.ratingHistory.map { ($0.timestamp, Int($0.rating)) }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.horizontal)
    }
}
