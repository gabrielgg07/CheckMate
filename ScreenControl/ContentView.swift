//
//  ContentView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var auth = AuthManager.shared


    var body: some View {
        VStack {
            if auth.isLoading{
                LoadingView()
            }
            else if auth.isAuthenticated {
               MainTabView()
                    .environmentObject(auth)
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
}

#Preview {
    ContentView()
}
