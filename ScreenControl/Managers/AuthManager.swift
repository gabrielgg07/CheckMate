//
//  AuthManager.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//
import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Security

struct GoogleUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let givenName: String?
    let familyName: String?
    let profileImageURL: URL?
    let accessToken: String?
    let idToken: String?
}

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: GoogleUser? = nil
    @Published var health: Bool = false
    @Published var isLoading: Bool = false

    private let tokenKey = "jwt_token"

    init() {
        Task {
            await self.restoreSession()
        }
    }

    // MARK: - LOGIN FLOW

    func signIn() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first else {
            print("❌ No rootViewController found")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "172460374843-dllgb5kk8c2cb559b9tqjon03qo4u2c1.apps.googleusercontent.com"
        )

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("❌ Sign-in failed:", error.localizedDescription)
                return
            }

            guard let user = result?.user else { return }

            let googleUser = GoogleUser(
                id: user.userID ?? UUID().uuidString,
                name: user.profile?.name ?? "",
                email: user.profile?.email ?? "",
                givenName: user.profile?.givenName,
                familyName: user.profile?.familyName,
                profileImageURL: user.profile?.imageURL(withDimension: 200),
                accessToken: user.accessToken.tokenString,
                idToken: user.idToken?.tokenString
            )

            Task {
                await self.authenticateWithBackend(googleUser)
            }
        }
    }

    // MARK: - BACKEND LOGIN / REGISTER
    func authenticateWithBackend(_ user: GoogleUser) async {
        await MainActor.run { self.isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } } // always clears loading even if error
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/google") else {
            print("❌ Invalid backend URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any?] = [
            "idToken": user.idToken,
            "accessToken": user.accessToken,
            "email": user.email
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode == 200 {
                struct ServerAuthResponse: Codable {
                    let message: String
                    let token: String
                    let user: ServerUser
                }

                struct ServerUser: Codable {
                    let id: String
                    let name: String
                    let email: String
                    let profile_image_url: String?
                }

                let result = try JSONDecoder().decode(ServerAuthResponse.self, from: data)

                // ✅ Save JWT securely
                saveToken(result.token)

                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }

                print("✅ Authenticated as:", result.user.name)
            } else {
                print("❌ Backend returned status:", httpResponse.statusCode)
            }
        } catch {
            print("❌ Network error:", error.localizedDescription)
        }
    }

    // MARK: - SESSION PERSISTENCE
    func restoreSession() async {
        await MainActor.run { self.isLoading = true }
        // 1️⃣ Try to load JWT first
        if let token = loadToken() {
            print("🪪 Found existing JWT: \(token.prefix(12))...")

            // 2️⃣ Validate JWT with backend
            let isValid = await self.validateJWT()
            if isValid {
                await MainActor.run { self.isAuthenticated = true }
                print("✅ JWT still valid")
            } else {
                print("⚠️ JWT expired or invalid, clearing token")
                deleteToken()
            }
        }

        // 3️⃣ Try silent Google sign-in if available
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            do {
                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                let googleUser = GoogleUser(
                    id: user.userID ?? UUID().uuidString,
                    name: user.profile?.name ?? "",
                    email: user.profile?.email ?? "",
                    givenName: user.profile?.givenName,
                    familyName: user.profile?.familyName,
                    profileImageURL: user.profile?.imageURL(withDimension: 200),
                    accessToken: user.accessToken.tokenString,
                    idToken: user.idToken?.tokenString
                )
                await self.authenticateWithBackend(googleUser)
                await MainActor.run {
                    self.currentUser = googleUser
                    self.isAuthenticated = true
                    // 🔁 Refresh backend JWT
                    

                }
                
                print("✅ Restored Google session for \(googleUser.name)")
            } catch {
                print("⚠️ Failed to restore Google session:", error.localizedDescription)
            }
        }
        await MainActor.run { self.isLoading = false }
    }



    func logout() {
        GIDSignIn.sharedInstance.signOut()
        deleteToken()
        isAuthenticated = false
        currentUser = nil
        print("👋 Logged out.")
    }

    // MARK: - HEALTH CHECK

    func checkHealth() async {
        guard let url = URL(string: "\(APIConfig.baseURL)/health") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.health = false
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String, status == "ok" {
                self.health = true
                print("✅ Backend healthy")
            } else {
                self.health = false
            }
        } catch {
            print("❌ Health check error:", error.localizedDescription)
            self.health = false
        }
    }
    
    //tester rn
    func validateJWT() async -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "jwt_token"),
              let url = URL(string: "\(APIConfig.baseURL)/protected") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Token valid")
                return true
            } else {
                print("⚠️ Token invalid or expired")
                return false
            }
        } catch {
            print("❌ Token validation failed:", error.localizedDescription)
            return false
        }
    }



    // MARK: - SECURE TOKEN STORAGE

    private func saveToken(_ token: String) {
        KeychainHelper.standard.save(token, service: "ScreenControl", account: tokenKey)
    }

    private func loadToken() -> String? {
        KeychainHelper.standard.read(service: "ScreenControl", account: tokenKey)
    }

    private func deleteToken() {
        KeychainHelper.standard.delete(service: "ScreenControl", account: tokenKey)
    }
}
