//
//  HackersKit+URLs.swift
//  Hackers
//
//  Created by Assistant on 2025-08-17.
//  Copyright © 2025 Glass Umbrella. All rights reserved.
//

import Foundation

// MARK: - URL Construction
extension HackersKit {
    
    /// Constructs URLs for various Hacker News endpoints
    enum URLs {
        
        /// Login page URL
        static var login: URL {
            URL(string: "\(hackerNewsBaseURL)/login")!
        }
        
        /// Post page URL with pagination
        static func post(id: Int, page: Int) -> URL {
            var components = URLComponents()
            components.scheme = "https"
            components.host = hackerNewsHost
            components.path = "/item"
            components.queryItems = [
                URLQueryItem(name: "id", value: String(id)),
                URLQueryItem(name: "p", value: String(page))
            ]
            return components.url!
        }
        
        /// Post page URL without pagination
        static func post(id: Int) -> URL {
            URL(string: "\(hackerNewsBaseURL)/item?id=\(id)")!
        }
        
        /// Posts list URL for different post types
        static func postsList(type: PostType, page: Int, nextId: Int) -> URL {
            if type == .newest || type == .jobs {
                return URL(string: "\(hackerNewsBaseURL)/\(type.rawValue)?next=\(nextId)")!
            } else if type == .active {
                return URL(string: "\(hackerNewsBaseURL)/active?p=\(page)")!
            } else {
                return URL(string: "\(hackerNewsBaseURL)/\(type.rawValue)?p=\(page)")!
            }
        }
        
        /// Converts a relative URL path to an absolute Hacker News URL
        static func absolute(from relativePath: String) -> URL? {
            guard !relativePath.isEmpty else { return nil }
            
            // If it's already an absolute URL, return it
            if let url = URL(string: relativePath), url.scheme != nil {
                return url
            }
            
            // Otherwise, construct absolute URL from base
            let path = relativePath.hasPrefix("/") ? relativePath : "/\(relativePath)"
            return URL(string: "\(hackerNewsBaseURL)\(path)")
        }
        
        /// Constructs a full URL from a relative path (used for voting)
        static func fullURL(from relativePath: String) -> URL? {
            // Remove leading slash if present
            let cleanPath = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
            return URL(string: "\(hackerNewsBaseURL)/\(cleanPath)")
        }
    }
}