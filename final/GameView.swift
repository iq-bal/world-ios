import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GameView: View {
    @State private var currentGuess = ""
    @State private var guesses: [[Character?]] = []
    @State private var wordToGuess = "" // Fetched word to guess
    @State private var currentRow = 0
    @State private var currentCol = 0
    @State private var message = ""
    @State private var solvedWords: [String] = [] // Solved words for the user
    @State private var userId: String? = Auth.auth().currentUser?.uid // Fetch userId from FirebaseAuth
    @State private var firstAttemptTime: Date? // First guess attempt time
    @State private var isFirstGuessMade = false // Tracks if the first guess has been made

    let db = Firestore.firestore() // Firestore database reference

    let keyboardRows = [
        "QWERTYUIOP",
        "ASDFGHJKL"
    ]

    let lastRowKeys = "ZXCVBNM"

    var body: some View {
        VStack(spacing: 20) {
            Text("Wordle")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text(message)
                .foregroundColor(.red)
                .font(.body)
                .padding(.bottom, 10)
            
            if wordToGuess.isEmpty {
                ProgressView("Fetching word...")
                    .padding()
            } else {
                // Guess Grid
                VStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<wordToGuess.count, id: \.self) { col in
                                Text(guesses[row][col]?.uppercased() ?? "")
                                    .frame(width: 50, height: 50)
                                    .background(getBackgroundColor(for: row, col: col))
                                    .cornerRadius(8)
                                    .font(.title)
                                    .bold()
                                    .border(Color.gray, width: 1)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Keyboard
                VStack(spacing: 10) {
                    ForEach(keyboardRows, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(row.map { String($0) }, id: \.self) { key in
                                Button(action: {
                                    handleKeyPress(key: key)
                                }) {
                                    Text(key)
                                        .frame(width: 35, height: 50)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(5)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }

                    // Enter, Last Row Keys, and Delete Row
                    HStack(spacing: 5) {
                        // Enter Button
                        Button(action: {
                            handleKeyPress(key: "ENTER")
                        }) {
                            Image(systemName: "return")
                                .frame(width: 50, height: 50)
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(8)
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        // Last Row Keys
                        ForEach(lastRowKeys.map { String($0) }, id: \.self) { key in
                            Button(action: {
                                handleKeyPress(key: key)
                            }) {
                                Text(key)
                                    .frame(width: 35, height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }

                        // Delete Button
                        Button(action: {
                            handleKeyPress(key: "DEL")
                        }) {
                            Image(systemName: "xmark.circle")
                                .frame(width: 50, height: 50)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom)
            }
        }
        .padding()
        .onAppear {
            loadSolvedWordsAndFetchNewWord()
        }
    }

    private func handleKeyPress(key: String) {
        if key == "ENTER" {
            if currentGuess.count == wordToGuess.count {
                submitGuess()
            } else {
                message = "Not enough letters!"
            }
        } else if key == "DEL" {
            if currentCol > 0 {
                currentCol -= 1
                guesses[currentRow][currentCol] = nil
                currentGuess.removeLast()
            }
        } else {
            if currentCol < wordToGuess.count {
                guesses[currentRow][currentCol] = Character(key.uppercased())
                currentGuess.append(key.uppercased())
                currentCol += 1
            }
        }
    }

    private func submitGuess() {
        guard currentCol == wordToGuess.count else {
            message = "Not enough letters!"
            return
        }

        guard currentRow < 6 else {
            message = "No more guesses!"
            return
        }

        // Set the first attempt time if this is the first guess
        if !isFirstGuessMade {
            firstAttemptTime = Date()
            isFirstGuessMade = true
        }

        if currentGuess.uppercased() == wordToGuess.uppercased() {
            message = "Congratulations! You guessed it!"
            storeSolvedWordAndTimeInDatabase()
            
            let solveTime = firstAttemptTime != nil ? Date().timeIntervalSince(firstAttemptTime!) : 0

            updateRating(isSuccess: true, solveTime: solveTime, attempts: currentRow + 1)
            
            loadSolvedWordsAndFetchNewWord()
            
        } else {
            currentRow += 1
            currentCol = 0
            currentGuess = ""

            if currentRow == 6 {
                // User failed to guess the word
                trackFailedAttempt()
                message = "Game Over! Word was \(wordToGuess)"
                
                let solveTime = firstAttemptTime != nil ? Date().timeIntervalSince(firstAttemptTime!) : 0
                    updateRating(isSuccess: false, solveTime: solveTime, attempts: 6)
                
            }
        }
    }


    private func getBackgroundColor(for row: Int, col: Int) -> Color {
        guard row < currentRow else { return Color.clear }
        guard let letter = guesses[row][col] else { return Color.clear }
        
        let target = Array(wordToGuess.uppercased())
        
        if target[col] == letter {
            return Color.green // Correct position
        } else if target.contains(letter) {
            return Color.yellow // Wrong position
        } else {
            return Color.gray // Not in word
        }
    }

    private func loadSolvedWordsAndFetchNewWord() {
        guard let userId = userId else {
            print("User is not logged in.")
            return
        }

        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching solved words: \(error.localizedDescription)")
                return
            }

            if let document = document, let solved = document.data()?["solved"] as? [String] {
                self.solvedWords = solved.map { $0.uppercased() } // Case insensitive comparison
                fetchNewWord()
            } else {
                print("No solved words found for the user.")
                fetchNewWord()
            }
        }
    }

    private func fetchNewWord() {
        guard let userId = userId else {
            print("User is not logged in.")
            return
        }

        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                return
            }

            // Extract solved words from the solvedDetails field
            var solvedWords: [String] = []
            if let document = document, let solvedDetails = document.data()?["solvedDetails"] as? [[String: Any]] {
                solvedWords = solvedDetails.compactMap { $0["word"] as? String }.map { $0.uppercased() }
            }

            // Fetch new words from the "words" collection
            let collectionRef = db.collection("words")
            collectionRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching word: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No words found in the database.")
                    return
                }

                // Exclude solved words and pick a random one
                let unsolvedWords = documents.compactMap { doc -> String? in
                    let word = doc.data()["word"] as? String
                    return word?.uppercased()
                }.filter { !solvedWords.contains($0) }

                if let randomWord = unsolvedWords.randomElement() {
                    wordToGuess = randomWord
                    print("Fetched word from database: \(wordToGuess)")
                    setupGuessesGrid(wordLength: wordToGuess.count)
                    isFirstGuessMade = false
                    firstAttemptTime = nil
                } else {
                    print("No unsolved words available.")
                    message = "No new words available!"
                }
            }
        }
    }


    private func setupGuessesGrid(wordLength: Int) {
        guesses = Array(repeating: Array(repeating: nil, count: wordLength), count: 6)
        currentRow = 0
        currentCol = 0
        currentGuess = ""
        message = ""
    }

    private func storeSolvedWordAndTimeInDatabase() {
        guard let userId = userId else {
            print("User is not logged in.")
            return
        }

        // Calculate solve time
        let endTime = Date()
        let solveTime = firstAttemptTime != nil ? endTime.timeIntervalSince(firstAttemptTime!) : 0
        let formattedSolveTime = String(format: "%.2f seconds", solveTime)

        // Details for the solved word
        let solvedDetail: [String: Any] = [
            "word": wordToGuess,
            "solveTime": solveTime,
            "timestamp": Timestamp(date: endTime),
            "attempts": currentRow + 1
        ]

        let userRef = db.collection("users").document(userId)
        let today = Calendar.current.startOfDay(for: Date()) // Today's date at midnight

        // Update user's solve stats
        userRef.updateData([
            "solvedDetails": FieldValue.arrayUnion([solvedDetail]),
            "dailySolveCount.\(today)": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating solved details and solve time: \(error.localizedDescription)")
            } else {
                print("Successfully added \(wordToGuess) to solved words with solve time \(formattedSolveTime).")
            }
        }
    }

    private func trackFailedAttempt() {
        guard let userId = userId else {
            print("User is not logged in.")
            return
        }

        let userRef = db.collection("users").document(userId)
        userRef.updateData([
            "failedAttempts": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error tracking failed attempt: \(error.localizedDescription)")
            } else {
                print("Failed attempt tracked successfully.")
            }
        }
    }
    
    
    private func updateRating(isSuccess: Bool, solveTime: TimeInterval, attempts: Int) {
        guard let userId = userId else { return }

        let userRef = db.collection("users").document(userId)

        // Fetch the last rating from Firestore
        userRef.getDocument { [self] document, error in
            if let error = error {
                print("Error fetching rating: \(error.localizedDescription)")
                return
            }

            // Extract the last rating
            let lastRating = getLastRating(from: document) ?? 1000

            // Calculate new rating
            let wordLength = wordToGuess.count
            let maxTime = Double(wordLength) * 5.0 // Max time for full points
            let timeScore = max(0.0, 1.0 - (solveTime / maxTime)) // Normalize time score
            let attemptScore = max(0.0, 1.0 - (Double(attempts - 1) / 5.0)) // Normalize attempts
            let successBonus = isSuccess ? 1.0 : -0.5 // Success adds, failure subtracts

            // Break down the calculation for clarity
            let averageScore = (timeScore + attemptScore) / 2.0
            let adjustedScore = averageScore + successBonus
            let kFactor = 32 // Sensitivity constant
            let expectedScore = 0.5 // Expected baseline
            let ratingDelta = Double(kFactor) * (adjustedScore - expectedScore)
            let newRating = Int(Double(lastRating) + ratingDelta)

            // Prepare rating detail dictionary
            let newRatingDetail = createRatingDetail(
                rating: newRating,
                isSuccess: isSuccess,
                solveTime: solveTime,
                attempts: attempts
            )

            // Update Firestore with the new rating
            saveNewRating(userRef: userRef, ratingDetail: newRatingDetail)
        }
    }


    private func getLastRating(from document: DocumentSnapshot?) -> Int {
        guard let document = document,
              let ratingHistory = document.data()?["ratingHistory"] as? [[String: Any]] else {
            return 1000 // Default rating if no history exists
        }
        return (ratingHistory.last?["rating"] as? Int) ?? 1000
    }

    private func calculateNewRating(lastRating: Int, isSuccess: Bool, solveTime: TimeInterval, attempts: Int) -> Int {
        let wordLength = wordToGuess.count
        let maxTime = Double(wordLength) * 5.0 // Max time for full points
        let timeScore = max(0.0, 1.0 - (solveTime / maxTime)) // Normalize time score
        let attemptScore = max(0.0, 1.0 - (Double(attempts - 1) / 5.0)) // Normalize attempts
        let successBonus = isSuccess ? 1.0 : -0.5 // Success adds, failure subtracts

        let averageScore = (timeScore + attemptScore) / 2.0
        let performanceScore = averageScore + successBonus
        let expectedScore = 0.5 // Expected baseline
        let kFactor = 32 // Sensitivity constant

        // Break down the expression
        let performanceDifference = performanceScore - expectedScore
        let weightedAdjustment = Double(kFactor) * performanceDifference
        let adjustedRating = Double(lastRating) + weightedAdjustment
        return Int(adjustedRating)
    }


    private func createRatingDetail(rating: Int, isSuccess: Bool, solveTime: TimeInterval, attempts: Int) -> [String: Any] {
        let endTime = Date()

        return [
            "rating": rating,
            "timestamp": Timestamp(date: endTime),
            "word": wordToGuess,
            "success": isSuccess,
            "solveTime": solveTime,
            "attempts": attempts
        ]
    }

    private func saveNewRating(userRef: DocumentReference, ratingDetail: [String: Any]) {
        userRef.updateData([
            "ratingHistory": FieldValue.arrayUnion([ratingDetail])
        ]) { error in
            if let error = error {
                print("Error updating rating: \(error.localizedDescription)")
            } else {
                print("New rating added successfully.")
            }
        }
    }
}
