////
////  DrawerView.swift
////  final
////
////  Created by Iqbal Mahamud on 16/1/25.
////
//
//
//
//struct DrawerView: View {
//    @Binding var isOpen: Bool
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Button(action: {
//                logout()
//                isOpen = false
//            }) {
//                Text("Logout")
//                    .font(.headline)
//            }
//            Divider()
//
//            Button(action: {
//                print("Option 1 tapped")
//                isOpen = false
//            }) {
//                Text("Option 1")
//                    .font(.headline)
//            }
//            Divider()
//
//            Button(action: {
//                print("Option 2 tapped")
//                isOpen = false
//            }) {
//                Text("Option 2")
//                    .font(.headline)
//            }
//            Spacer()
//        }
//        .padding()
//        .frame(maxWidth: 200, maxHeight: .infinity)
//        .background(Color.white)
//        .shadow(radius: 10)
//        .transition(.move(edge: .trailing))
//        .animation(.easeInOut, value: isOpen)
//    }
//
//    private func logout() {
//        do {
//            try Auth.auth().signOut()
//            print("User logged out.")
//        } catch {
//            print("Error logging out: \(error.localizedDescription)")
//        }
//    }
//}
