//
//  PresentationService.swift
//  Shared
//
//  Service for presentation-related utilities
//

import UIKit

public class PresentationService {
    public static let shared = PresentationService()
    
    private init() {}
    
    public var windowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes.first as? UIWindowScene
    }
    
    public var rootViewController: UIViewController? {
        windowScene?.windows.first?.rootViewController
    }
}