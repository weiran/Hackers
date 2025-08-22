//
//  HackersKitError.swift
//  Shared
//
//  Error types for the app
//

import Foundation

public enum HackersKitError: Error {
    case unauthenticated
    case scraperError
    case networkError(Error)
    case parseError
    case unknown
    
    public var localizedDescription: String {
        switch self {
        case .unauthenticated:
            return "You need to be logged in to perform this action."
        case .scraperError:
            return "Failed to parse the content."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError:
            return "Failed to parse the response."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}