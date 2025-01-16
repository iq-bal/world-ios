import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommunityView: View {
    @State private var posts: [CommunityPost] = [] // Posts fetched from Firestore
    @State private var newMessage: String = "" // New post input
    @State private var currentUsername: String = "Unknown User" // Dynamic username
    private let db = Firestore.firestore() // Firestore reference

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // Community Feed
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PostDetailsView(post: post)) {
                                CommunityPostCard(post: post)
                            }
                            .buttonStyle(PlainButtonStyle()) // Removes button styling for a clean look
                        }
                    }
                    .padding()
                }

                // New Post Input
                HStack {
                    TextField("Share something...", text: $newMessage)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    Button(action: postNewMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .navigationTitle("Community")
            .background(Color(.systemBackground).ignoresSafeArea())
            .onAppear {
                fetchPosts()
                fetchUsername()
            }
        }
    }

    private func fetchUsername() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
                return
            }

            if let document = document, let username = document.data()?["name"] as? String {
                self.currentUsername = username
            }
        }
    }

    private func fetchPosts() {
        db.collection("communityPosts").order(by: "timestamp", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No posts found.")
                return
            }

            self.posts = documents.compactMap { doc -> CommunityPost? in
                let data = doc.data()
                guard
                    let username = data["username"] as? String,
                    let message = data["message"] as? String,
                    let timestamp = data["timestamp"] as? Timestamp
                else {
                    return nil
                }
                return CommunityPost(
                    id: doc.documentID,
                    username: username,
                    message: message,
                    timestamp: timestamp.dateValue()
                )
            }
        }
    }

    private func postNewMessage() {
        guard !newMessage.isEmpty else { return }

        let newPost: [String: Any] = [
            "username": currentUsername,
            "message": newMessage,
            "timestamp": Timestamp()
        ]

        db.collection("communityPosts").addDocument(data: newPost) { error in
            if let error = error {
                print("Error adding post: \(error.localizedDescription)")
            } else {
                print("Post added successfully.")
                newMessage = ""
            }
        }
    }
}
