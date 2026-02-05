//
//  ShieldConfigurationExtension.swift
//  ShieldConfig
//
//  Created by Gabriel Gonzalez on 11/16/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield as needed for applications.
        return ShieldConfiguration(
                    backgroundBlurStyle: .systemUltraThinMaterialDark,
                    icon: UIImage(systemName: "lock.fill"),
                    title: .init(text: "Locked by ScreenControl", color: .white),
                    subtitle: .init(text: "Get back to work Matt Walsh", color: .lightGray),
                    primaryButtonLabel: .init(text: "Request Unlock", color: .white),
                    primaryButtonBackgroundColor: .systemBlue
                )
        
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for applications shielded because of their category.
        ShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        ShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        ShieldConfiguration()
    }
}
