//
//  RequestsView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/12/25.
//

import SwiftUI

struct RequestsView: View {
    @StateObject private var friendManager = FriendManager()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // 🔍 Search Bar
                VStack(spacing: 0) {
                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                        TextField("Search friends...", text: $friendManager.searchText)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .autocorrectionDisabled(true)
                                    }
                                    .padding(10)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .padding(.top, 12)

                    if friendManager.isSearching {
                        ProgressView("Searching...")
                            .padding()
                    } else if !friendManager.searchResults.isEmpty {
                        List(friendManager.searchResults) { user in
                            HStack(spacing: 12) {
                                AsyncImage(url: user.profileImageURL) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                                Text(user.name)
                                    .font(.headline)
                                Spacer()
                                Button {
                                    print("Send request to \(user.name)")
                                    // TODO: implement /relationships/request
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 22))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                    }
                }

                
                // 🔄 Pending Requests Section
                if !friendManager.pendingRequests.isEmpty {
                    SectionHeader(title: "Pending Requests")
                    List(friendManager.pendingRequests, id: \.id) { req in
                        PendingRequestCell(request: req) {
                            friendManager.acceptRequest(req)
                        } onDecline: {
                            friendManager.declineRequest(req)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No pending requests right now")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding(.top, 80)
                }
                
                Spacer()
            }
            .navigationTitle("Requests")
            .background(.white)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct PendingRequestCell: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: request.profileImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 45, height: 45)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(request.name)
                    .font(.headline)
                Text("wants to \(request.type == .unlock ? "unlock" : "limit") screen time")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            HStack(spacing: 10) {
                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 22))
                }
                Button {
                    onDecline()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 22))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
    }
}


#Preview {
    RequestsView()
}
