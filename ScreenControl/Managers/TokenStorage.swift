//
//  TokenStorage.swift
//  ScreenControl
//
//  Created by Gabriel Gonzalez on 11/14/25.
//

import FamilyControls
import SwiftUI
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

struct TokenStorage {

    static let suite = UserDefaults(suiteName: "group.com.yourcompany.screencontrol")!

    static func save(tokens: Set<ApplicationToken>) {
        let data = try! JSONEncoder().encode(tokens)
        suite.set(data, forKey: "savedTokens")
    }

    static func loadTokens() -> Set<ApplicationToken> {
        guard let data = suite.data(forKey: "savedTokens"),
              let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data)
        else { return [] }

        return tokens
    }
}
