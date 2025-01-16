import SwiftUI

struct TabsView: View {
    
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        TabView {
            GameView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }

            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }
            DictionaryView()
                .tabItem {
                    Label("Dictionary", systemImage: "book")
                }
            LeaderboardView()
                .tabItem {
                    Label("Dictionary", systemImage: "book")
                }
        }
        .accentColor(.blue)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Wordlee!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}


#Preview {
    TabsView(isLoggedIn: .constant(true))
}
