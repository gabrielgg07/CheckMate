//
//  FriendsManager.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/12/25.
//

import SwiftUI
import Foundation
import Combine

struct FriendSearchResult: Identifiable, Codable {
    let id: String
    let name: String
    let profileImageURL: URL?
}

@MainActor
class FriendManager: ObservableObject {
    @Published var pendingRequests: [FriendRequest] = []
    @Published var searchResults: [FriendSearchResult] = []
    @Published var friends: [FriendSearchResult] = []
    @Published var isSearching = false
    @Published var searchText = ""

        private var cancellables = Set<AnyCancellable>()

        init() {
            // 🕒 Debounce user typing before searching
            $searchText
                .removeDuplicates()
                .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
                .sink { [weak self] text in
                    guard let self = self else { return }
                    Task { await self.searchFriends(query: text) }
                }
                .store(in: &cancellables)
        }

        
        func searchFriends(query: String) async {
            guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                searchResults = []
                return
            }

            guard let url = URL(string: "\(APIConfig.baseURL)/relationships/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
                return
            }

            isSearching = true
            defer { isSearching = false }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    return
                }

                let results = try JSONDecoder().decode([FriendSearchResult].self, from: data)
                self.searchResults = results
            } catch {
                print("❌ Search failed:", error.localizedDescription)
            }
        }
    

    func sendFriendRequest(from fromUserId: String, to toUserId: String) async -> Bool {
        guard let url = URL(string: "\(APIConfig.baseURL)/relationships/add") else {
            print("❌ Invalid URL")
            return false
        }

        let body: [String: Any] = [
            "from_user_id": fromUserId,
            "to_user_id": toUserId
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }

            if http.statusCode == 201 {
                print("📨 Friend request sent!")
                return true
            } else {
                print("⚠️ Error sending request: \(String(data: data, encoding: .utf8) ?? "")")
                return false
            }

        } catch {
            print("❌ Network error:", error.localizedDescription)
            return false
        }
    }


    func acceptFriendRequest(friendshipId: String) async -> Bool {
        guard let url = URL(string: "\(APIConfig.baseURL)/relationships/accept") else {
            return false
        }

        let body: [String: Any] = [
            "friendship_id": friendshipId
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }

            if http.statusCode == 200 {
                print("🤝 Friend request accepted")
                return true
            } else {
                print("⚠️ Error accepting:", String(data: data, encoding: .utf8) ?? "")
                return false
            }

        } catch {
            print("❌ Network error:", error.localizedDescription)
            return false
        }
    }

    
    func loadPendingRequests() async {
        guard let user = AuthManager.shared.currentUser else { return }

        let url = URL(string: "\(APIConfig.baseURL)/relationships/pending/\(user.id)")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode([FriendRequest].self, from: data)
            self.pendingRequests = decoded 

        } catch {
            print("❌ Failed to load pending:", error.localizedDescription)
        }
    }
    
    func fetchFriends(for userId: String) async {
        guard let url = URL(string: "\(APIConfig.baseURL)/relationships/friends/\(userId)") else {
            print("❌ Invalid friends URL")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("❌ Failed to load friends")
                return
            }

            let friends = try JSONDecoder().decode([FriendSearchResult].self, from: data)
            self.friends = friends  // or make `friends: [Friend]` published
        } catch {
            print("❌ fetchFriends error:", error)
        }
    }




    
    func declineRequest(_ req: FriendRequest) {
        //pendingRequests.removeAll { $0.id == req.id }
        print("❌ Declined request from \(req.name)")
    }
}

struct FriendRequest: Identifiable, Codable {
    let id: String                   // maps from friendship_id
    let name: String                 // sender name
    let profileImageURL: URL?        // maps from profile_image_url
    let type: RequestType = .unlock  // default since backend sends no type
    let fromUserId: String           // sender user id

    enum CodingKeys: String, CodingKey {
        case id = "friendship_id"
        case name
        case profileImageURL = "profile_image_url"
        case fromUserId = "from_user_id"
    }
}


enum RequestType {
    case unlock, limit
}
