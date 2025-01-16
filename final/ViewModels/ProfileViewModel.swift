import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var error: String?
    @Published var viewState: String = "initial"
    
    private let db = Firestore.firestore()
    
    init() {
        fetchUserData()
    }
    
    func fetchUserData() {
        self.viewState = "loading"
        isLoading = true
        print("📱 Starting to fetch user data (State: \(self.viewState))")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            self.viewState = "error-no-user"
            self.error = "No user logged in"
            self.isLoading = false
            print("⚠️ No user ID found (State: \(self.viewState))")
            return
        }
        
        print("🔍 Fetching data for user: \(userId)")
        
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { [weak self] document, error in
            guard let self = self else { 
                print("⚠️ Self is nil in closure")
                return 
            }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    print("❌ Error fetching user data: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document else {
                    self.error = "Document is nil"
                    self.isLoading = false
                    print("⚠️ Document is nil")
                    return
                }
                
                guard document.exists else {
                    self.error = "User document not found"
                    self.isLoading = false
                    print("⚠️ Document does not exist")
                    return
                }
                
                guard let data = document.data() else {
                    self.error = "No data in document"
                    self.isLoading = false
                    print("⚠️ Document has no data")
                    return
                }
                
                print("📄 Raw document data: \(data)")
                
                self.user = self.parseUserData(id: document.documentID, data: data)
                self.isLoading = false
                
                if self.user != nil {
                    self.viewState = "loaded"
                    print("✅ User data parsed successfully (State: \(self.viewState))")
                } else {
                    self.viewState = "error-parse"
                    self.error = "Failed to parse user data"
                    print("⚠️ Failed to parse user data (State: \(self.viewState))")
                }
            }
        }
    }
    
    func logout(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            self.error = error.localizedDescription
            completion(false)
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - Stats Calculations
    
    func totalGamesPlayed(_ user: User) -> Int {
        return user.solvedDetails.count + user.failedAttempts
    }
    
    func winPercentage(_ user: User) -> Double {
        let wins = user.solvedDetails.count
        let total = totalGamesPlayed(user)
        return total > 0 ? (Double(wins) / Double(total)) * 100 : 0
    }
    
    func longestStreak(_ user: User) -> Int {
        return user.dailySolveCount.values.max() ?? 0
    }
    
    func averageAttempts(_ user: User) -> Double {
        guard !user.solvedDetails.isEmpty else { return 0.0 }
        let totalAttempts = user.solvedDetails.reduce(0) { $0 + $1.attempts }
        return Double(totalAttempts) / Double(user.solvedDetails.count)
    }
    
    func solvedDates(_ user: User) -> Set<Date> {
        return Set(user.solvedDetails.map { Calendar.current.startOfDay(for: $0.timestamp) })
    }
    
    func ratingHistory(_ user: User) -> [(Date, Int)] {
        return user.ratingHistory.map { ($0.timestamp, Int($0.rating)) }
    }
} 