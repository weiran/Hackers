//
//  Settings+UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

extension UserDefaults {
    public var darkModeEnabled: Bool {
        let themeSetting = string(forKey: UserDefaultsKeys.Theme.rawValue)
        return themeSetting == "dark"
    }

    public var jobsEnabled: Bool {
        let jobsEnabled = string(forKey:
            UserDefaultsKeys.Jobs.rawValue)
        return jobsEnabled == "enabled"
    }

    public func setDarkMode(_ enabled: Bool) {
        set(enabled ? "dark" : "light", forKey: UserDefaultsKeys.Theme.rawValue)
    }

    public func setJobsEnabled(_ enabled: Bool) {
        set(enabled ? "enabled" : "disabled", forKey: UserDefaultsKeys.Jobs.rawValue)
    }

}

enum UserDefaultsKeys: String {
    case Theme
    case Jobs
}
