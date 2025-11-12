//
//  HomeView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LimitsView()
                .tabItem {
                    Label("Limits", systemImage: "hourglass.circle.fill")
                }

            RequestsView()
                .tabItem {
                    Label("Requests", systemImage: "bell.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.blue)
    }
}
