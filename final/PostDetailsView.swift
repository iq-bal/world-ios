import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PostDetailsView: View {
    let post: CommunityPost
    @State private var comments: [Comment] = [] // Dynamic comments fetched from Firestore
    @State private var newComment: String = "" // New comment input
    private let db = Firestore.firestore()
    @State private var currentUsername: String = "Unknown User"

    var body: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(post.username)
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(post.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(post.message)
                    .font(.body)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(comments) { comment in
                        CommentCard(comment: comment)
                    }
                }
                .padding()
            }

            HStack {
                TextField("Add a comment...", text: $newComment)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Button(action: postNewComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationTitle("Post Details")
        .onAppear {
            fetchComments()
            fetchUsername()
        }
    }

    private func fetchUsername() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User is not authenticated.")
            return
        }

        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
                return
            }

            if let document = document, let username = document.data()?["name"] as? String {
                self.currentUsername = username
                print("Fetched username: \(username)")
            } else {
                print("Username not found.")
            }
        }
    }

    private func fetchComments() {
        db.collection("posts").document(post.id).collection("comments").order(by: "timestamp", descending: false).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching comments: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            self.comments = documents.compactMap { doc -> Comment? in
                let data = doc.data()
                guard
                    let username = data["username"] as? String,
                    let message = data["message"] as? String,
                    let timestamp = data["timestamp"] as? Timestamp
                else {
                    return nil
                }
                return Comment(
                    id: doc.documentID,
                    username: username,
                    message: message,
                    timestamp: timestamp.dateValue()
                )
            }
        }
    }

    private func postNewComment() {
        guard !newComment.isEmpty else { return }

        let commentData: [String: Any] = [
            "username": currentUsername,
            "message": newComment,
            "timestamp": Timestamp()
        ]

        db.collection("posts").document(post.id).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error.localizedDescription)")
            } else {
                print("Comment added successfully.")
                newComment = ""
            }
        }
    }
}
