//
//  HomeView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/10/25.
//
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject var screenTime = ScreenTimeManager.shared
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Welcome, \(auth.currentUser?.name ?? "Unknown") 👋")
                .font(.title2)
                .padding(.top, 40)

            // Request Screen Time access
            Button("Request ScreenTime Access") {
                Task { await screenTime.requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)

            if screenTime.authorized {
                Text("✅ Authorized to manage ScreenTime")
                    .font(.subheadline)
                    .foregroundColor(.green)

                Divider().padding(.vertical)

                // Show FamilyActivityPicker
                Button("Select Apps to Limit") {
                    showPicker = true
                }
                .familyActivityPicker(isPresented: $showPicker,
                                      selection: $screenTime.selection)

                // Apply or remove shields
                HStack(spacing: 20) {
                    Button("🛡️ Block Selected Apps") {
                        screenTime.applyShield()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("❌ Unblock All") {
                        Task {
                            await screenTime.requestAccess()
                        }
                    }
                    .foregroundColor(.red)
                }
            }

            Spacer()

            Button("Logout") {
                auth.logout()
            }
            .foregroundColor(.red)
            .padding(.bottom, 40)
        }
        .padding(.horizontal)
    }
}





struct StatsView: View {
    var body: some View {
        Text("📊 Your screen time analytics")
            .font(.title3)
            .padding()
    }
}

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    var body: some View {
        VStack(spacing: 20) {
            if let user = auth.currentUser {
                AsyncImage(url: user.profileImageURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())

                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Button("Logout") {
                auth.logout()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}
