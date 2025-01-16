import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var isLoggedin = false
    
    let db = Firestore.firestore() // Firestore reference

    var body: some View {
        Group {
            if isLoggedin {
                TabsView(isLoggedIn: $isLoggedin)
                    .onAppear {
                        checkAndCreateWordsCollection() // Ensure the collection is checked/created only when logged in
                    }
            } else {
                AuthenticationView(isLoggedIn: $isLoggedin)
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
    }
    
    func checkAndCreateWordsCollection() {
        let collectionRef = db.collection("words") // Reference to "words" collection
        
        collectionRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking collection: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.isEmpty {
                print("Collection does not exist. Creating and populating it...")
                populateWordsCollection()
            } else {
                print("Collection already exists.")
            }
        }
    }
    
    func populateWordsCollection() {
        let words = ["love", "time", "life", "hope", "calm", "kind", "brav", "idea", "fire", "blue",
                     "tree", "star", "plan", "goal", "view", "walk", "bird", "play", "song", "wave"]
        
        let batch = db.batch()
        
        for (index, word) in words.enumerated() {
            let docRef = db.collection("words").document("word\(index + 1)")
            batch.setData(["word": word], forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error adding words to Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully added 20 four-letter words to Firestore.")
            }
        }
    }

    private func checkAuthenticationState() {
        isLoggedin = Auth.auth().currentUser != nil
    }
}

#Preview {
    ContentView()
}

