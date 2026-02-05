//
//  ContentView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var auth = AuthManager.shared
    @EnvironmentObject var screen: ScreenTimeManager
    
    var body: some View {
        VStack {
            if auth.isLoading || screen.isLoading{
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
