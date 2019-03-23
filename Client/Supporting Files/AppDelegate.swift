//
//  AppDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()
        setAppTheme()
        return true
    }
    
    private func setAppTheme() {
        AppThemeProvider.shared.currentTheme = UserDefaults.standard.darkModeEnabled ? .dark : .light
    }
}
