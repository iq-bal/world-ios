import SwiftUI
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var players: [Player] = [] // Players fetched from Firestore
    private let db = Firestore.firestore() // Firestore reference

    var body: some View {
        NavigationView {
            VStack {
                // Title Section
                VStack {
                    Text("Leaderboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    Text("Top players competing for the best scores!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .background(LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(15)
                .padding()

                // Player List
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(players.sorted(by: { $0.rating > $1.rating })) { player in
                            LeaderboardCard(player: player)
                        }
                    }
                    .padding()
                }
                .onAppear(perform: fetchLeaderboardData)
            }
            .navigationTitle("Leaderboard")
            .background(Color(.systemBackground).ignoresSafeArea())
        }
    }

    private func fetchLeaderboardData() {
        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching leaderboard data: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No users found.")
                return
            }

            self.players = documents.compactMap { doc -> Player? in
                let data = doc.data()
                guard
                    let name = data["name"] as? String,
                    let solvedDetails = data["solvedDetails"] as? [[String: Any]],
                    let failedAttempts = data["failedAttempts"] as? Int,
                    let userId = data["userId"] as? String
                else {
                    return nil
                }

                let solvedWords = solvedDetails.compactMap { $0["word"] as? String }
                let solveTimes = solvedDetails.compactMap { $0["solveTime"] as? Double }
                let fastestSolveTime = solveTimes.min() ?? 0.0
                let accuracy = solveTimes.isEmpty ? 0.0 : Double(solvedWords.count) / Double(solvedWords.count + failedAttempts)
                let consistency = data["dailySolveCount"] as? [String: Int] ?? [:]
                let totalConsistency = consistency.values.reduce(0, +)

                let rating = calculateRating(
                    solvedCount: solvedWords.count,
                    fastestTime: fastestSolveTime,
                    accuracy: accuracy,
                    consistency: totalConsistency,
                    failedAttempts: failedAttempts
                )

                return Player(
                    id: userId,
                    name: name,
                    solvedWords: solvedWords,
                    fastestSolveTime: String(format: "%.2f sec", fastestSolveTime),
                    accuracy: accuracy,
                    rating: rating
                )
            }
        }
    }

    private func calculateRating(solvedCount: Int, fastestTime: Double, accuracy: Double, consistency: Int, failedAttempts: Int) -> Double {
        let maxSolveTime = 300.0 // Assume 5 minutes as max time for normalization
        let solveScore = Double(solvedCount) / 100.0 // Normalize by an assumed max solves of 100
        let timeScore = 1.0 - min(fastestTime / maxSolveTime, 1.0)
        let accuracyScore = accuracy
        let consistencyScore = Double(consistency) / 30.0 // Normalize by an assumed max of 30 days streak
        let penalty = Double(failedAttempts) / 50.0 // Normalize by an assumed max of 50 attempts

        return (solveScore * 0.4) + (timeScore * 0.3) + (accuracyScore * 0.2) + (consistencyScore * 0.1) - penalty
    }
}

struct LeaderboardCard: View {
    let player: Player

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(player.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 10) {
                    Text("Words Solved: \(player.solvedWords.count)")
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    Text("Best Time: \(player.fastestSolveTime)")
                        .font(.subheadline)
                        .foregroundColor(.green)

                    Text(String(format: "Accuracy: %.2f%%", player.accuracy * 100))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Circle()
                .strokeBorder(LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 3)
                .background(Circle().fill(Color.white))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(format: "%.0f", player.rating * 100))
                        .font(.headline)
                        .foregroundColor(.primary)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

struct Player: Identifiable {
    var id: String
    var name: String
    var solvedWords: [String]
    var fastestSolveTime: String
    var accuracy: Double
    var rating: Double
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}

