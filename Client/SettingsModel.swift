//
//  SettingsModel.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/08/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

class SettingsModel {
    
    static let shared = SettingsModel()
    
    let hideThumbnailsSetting = "hideThumbnails"
    var hideThumbnails: Bool = false {
        didSet {
            UserDefaults.standard.set(hideThumbnails, forKey: hideThumbnailsSetting)
        }
    }
    
    private init() {
        hideThumbnails = UserDefaults.standard.bool(forKey: hideThumbnailsSetting)
    }
    
}
