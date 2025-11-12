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


class FriendManager: ObservableObject {
    @Published var pendingRequests: [FriendRequest] = [
        FriendRequest(id: "1", name: "Sarah Kim", profileImageURL: URL(string: "https://randomuser.me/api/portraits/women/65.jpg")!, type: .unlock),
        FriendRequest(id: "2", name: "Alex Chen", profileImageURL: URL(string: "https://randomuser.me/api/portraits/men/52.jpg")!, type: .limit)
    ]
    @Published var searchResults: [FriendSearchResult] = []
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
    

    
    func acceptRequest(_ req: FriendRequest) {
        pendingRequests.removeAll { $0.id == req.id }
        print("✅ Accepted request from \(req.name)")
    }
    
    func declineRequest(_ req: FriendRequest) {
        pendingRequests.removeAll { $0.id == req.id }
        print("❌ Declined request from \(req.name)")
    }
}

struct FriendRequest {
    let id: String
    let name: String
    let profileImageURL: URL?
    let type: RequestType
}

enum RequestType {
    case unlock, limit
}
