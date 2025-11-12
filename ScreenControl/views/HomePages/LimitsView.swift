//
//  LimitsView.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/10/25.
//

import SwiftUI
import FamilyControls

struct LimitsView: View {
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Selected Apps")
                .font(.headline)
                .padding(.top, 20)

            if screenTime.selectedAppNames.isEmpty {
                Text("No apps selected yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(screenTime.selectedAppNames, id: \.self) { app in
                    Text("• \(app)")
                        .font(.body)
                }
            }

            Button("Select Apps to Limit") {
                showPicker = true
            }
            .buttonStyle(.borderedProminent)
            .familyActivityPicker(isPresented: $showPicker,
                                  selection: $screenTime.selection)
            // When picker closes, save and refresh
            .onChange(of: showPicker) { shown in
                if !shown {
                    screenTime.updateSelectedApps()
                    screenTime.saveSelection()
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            screenTime.loadSelection()
        }
    }
}

