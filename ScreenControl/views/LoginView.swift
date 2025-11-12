//
//  LoginView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    var body: some View {
        VStack {
            GoogleSignInButton {
                auth.signIn()
            }
            .frame(height: 50)
            .padding()
        }
    }


}

