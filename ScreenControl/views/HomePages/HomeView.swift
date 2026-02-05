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
            if !screenTime.authorized {
                Button("Request ScreenTime Access") {
                    Task { await screenTime.requestAuthorization() }
                }
                .buttonStyle(.borderedProminent)
            }

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
                .onChange(of: screenTime.selection) { _ in
                    screenTime.saveSelection()
                }

                // Apply or remove shields
                HStack(spacing: 20) {
                    Button("🛡️ Block Selected Apps") {
                        screenTime.applyShield()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("❌ Unblock All") {
                        Task {
                            //screenTime.removeShield()
                        }
                    }
                    .foregroundColor(.red)
                }
            }

            Spacer()
            Button("30 Second Test Unlock") {
                //ScreenTimeManager.shared.test30SecondUnlock()
            }


            Button("Logout") {
                auth.logout()
            }
            .foregroundColor(.red)
            .padding(.bottom, 40)
        }
        .padding(.horizontal)
    }
}




