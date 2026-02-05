//
//  AppState.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/13/25.
//

import Foundation

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isLocked: Bool = false
    @Published var unlockedUntil: Date? = nil
    @Published var lastAction: String? = nil
    @Published var debugMessage: String = ""
}
