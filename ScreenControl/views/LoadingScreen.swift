//
//  LoadingScreen.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/12/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.9), .gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )

                Text("Checking your session...")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 8)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingView()
}
