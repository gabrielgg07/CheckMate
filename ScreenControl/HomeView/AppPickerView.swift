//
//  HomeViews.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/9/25.
//

import SwiftUI
import FamilyControls

struct AppPickerView: View {
    @ObservedObject var manager = ScreenTimeManager.shared
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Button("Select Apps to Limit") {
                isPresented = true
            }
            .familyActivityPicker(isPresented: $isPresented,
                                  selection: $manager.selection)

            Button("Block Selected Apps") {
                manager.applyShield()
            }
            .buttonStyle(.borderedProminent)

            Button("Unblock All") {
                manager.removeShield()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}
