import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if viewModel.isLoading {
                        LoadingView()
                            .onAppear { print("⏳ Showing loading view") }
                    } else if let error = viewModel.error {
                        ErrorView(message: error)
                            .onAppear { print("❌ Showing error: \(error)") }
                    } else if let user = viewModel.user {
                        VStack(spacing: AppSpacing.lg) {
                            ProfileHeader(user: user)
                                .onAppear { print("👤 Showing profile header") }
                            StatsGrid(user: user, viewModel: viewModel)
                                .onAppear { print("📊 Showing stats grid") }
                            ActivitySection(user: user, viewModel: viewModel)
                                .onAppear { print("📅 Showing activity section") }
                            RatingSection(user: user, viewModel: viewModel)
                                .onAppear { print("📈 Showing rating section") }
                            LogoutButton(isLoggedIn: $isLoggedIn, viewModel: viewModel)
                        }
                        .onAppear { print("✅ User data loaded successfully") }
                    } else {
                        ErrorView(message: "Unable to load profile")
                            .onAppear { print("⚠️ No user data available") }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.white.ignoresSafeArea())
            .onAppear {
                print("🔄 ProfileView appeared")
                viewModel.fetchUserData()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Subviews
struct ProfileHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primary)
                .background(
                    Circle()
                        .fill(AppColors.surface)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
                .padding(.top, AppSpacing.xl)
            
            VStack(spacing: AppSpacing.xs) {
                Text(user.name)
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

struct StatsGrid: View {
    let user: User
    let viewModel: ProfileViewModel
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            StatCard(title: "Games Played", value: "\(viewModel.totalGamesPlayed(user))")
            StatCard(title: "Win Rate", value: "\(String(format: "%.1f", viewModel.winPercentage(user)))%")
            StatCard(title: "Best Streak", value: "\(viewModel.longestStreak(user))")
            StatCard(title: "Avg Attempts", value: "\(String(format: "%.1f", viewModel.averageAttempts(user)))")
        }
        .padding(.horizontal)
    }
}

struct ActivitySection: View {
    let user: User
    let viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Activity")
            ScrollView(.horizontal, showsIndicators: false) {
                HeatmapView(solvedDates: viewModel.solvedDates(user))
                    .padding(AppSpacing.md)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(AppColors.surface)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
            }
        }
        .padding(.horizontal)
        .safeAreaInset(edge: .leading) { Color.clear.frame(width: AppSpacing.md) }
        .safeAreaInset(edge: .trailing) { Color.clear.frame(width: AppSpacing.md) }
    }
}

struct RatingSection: View {
    let user: User
    let viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Rating Progress")
            if !user.ratingHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    RatingGraphView(ratingHistory: viewModel.ratingHistory(user))
                        .frame(width: UIScreen.main.bounds.width - 40, height: 250)
                        .padding(AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .fill(AppColors.surface)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        )
                }
            } else {
                EmptyStateView(message: "No rating data available yet")
            }
        }
        .padding(.horizontal)
        .safeAreaInset(edge: .leading) { Color.clear.frame(width: AppSpacing.md) }
        .safeAreaInset(edge: .trailing) { Color.clear.frame(width: AppSpacing.md) }
    }
}

struct LogoutButton: View {
    @Binding var isLoggedIn: Bool
    let viewModel: ProfileViewModel
    
    var body: some View {
        Button {
            viewModel.logout { success in
                if success {
                    isLoggedIn = false
                }
            }
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(AppRadius.md)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(AppColors.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surface)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(AppColors.textPrimary)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
            Text("Loading profile...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear { print("⏳ LoadingView appeared") }
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textSecondary)
            Text(message)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
