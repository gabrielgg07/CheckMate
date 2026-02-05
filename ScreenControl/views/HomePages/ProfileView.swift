//
//  ProfileView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/14/25.
//


import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var appState: AppState
    
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
                Text(appState.debugMessage)
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
