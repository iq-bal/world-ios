//
//  AuthenticationView.swift
//  final
//
//  Created by Iqbal Mahamud on 16/1/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthenticationView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = "" // Added name field
    @State private var errorMessage = ""
    @State private var showError = false

    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text(isLoginMode ? "Welcome Back!" : "Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(spacing: 15) {
                    if !isLoginMode {
                        TextField("Name", text: $name) // Name field
                            .autocapitalization(.words)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }

                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 1)
                        )

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }

                Button(action: handleAuthentication) {
                    Text(isLoginMode ? "Login" : "Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.blue)
                        .font(.headline)
                }

                Button(action: {
                    isLoginMode.toggle()
                }) {
                    Text(isLoginMode ? "Don’t have an account? Register" : "Already have an account? Login")
                        .font(.footnote)
                        .foregroundColor(.white)
                }

                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(15)
            .padding()
        }
    }

    private func handleAuthentication() {
        if isLoginMode {
            loginUser()
        } else {
            registerUser()
        }
    }

    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                showError = true
                errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }

            showError = false
            isLoggedIn = true
            print("User logged in successfully.")
        }
    }

    
    private func registerUser() {
        if name.isEmpty {
            showError = true
            errorMessage = "Please enter your name."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                showError = true
                errorMessage = "Registration failed: \(error.localizedDescription)"
                return
            }

            guard let user = authResult?.user else {
                showError = true
                errorMessage = "Failed to retrieve user information."
                return
            }

            // Update the user's display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    showError = true
                    errorMessage = "Failed to set display name: \(error.localizedDescription)"
                    return
                }

                // Initialize user data
                let db = Firestore.firestore()
                let initialRating: [String: Any] = [
                    "rating": 1000.0,
                    "attempts": 0,
                    "solveTime": 0.0,
                    "success": true,
                    "timestamp": Timestamp(),
                    "word": "N/A"
                ]

                let userData: [String: Any] = [
                    "id": user.uid,
                    "email": email,
                    "name": name,
                    "solvedDetails": [], // Start with an empty array
                    "dailySolveCount": [:], // Start with an empty dictionary
                    "ratingHistory": [initialRating], // Start with an initial rating
                    "failedAttempts": 0, // Initialize with 0
                    "createdAt": Timestamp()
                ]

                // Save to Firestore
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        showError = true
                        errorMessage = "Failed to save user data: \(error.localizedDescription)"
                        return
                    }

                    showError = false
                    isLoggedIn = true
                    print("User registered and saved to Firestore successfully.")
                }
            }
        }
    }
}
