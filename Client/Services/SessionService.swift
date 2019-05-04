//
//  SessionService.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import PromiseKit
import KeychainAccess
import HNScraper

class SessionService {
    private let keychain = Keychain(service: StorageKeys.service.rawValue)
    private var hackerNewsService: HackerNewsService
    
    private var user: HNUser?
    
    public var authenticationState: AuthenticationState {
        if HNLogin.shared.user != nil && HNLogin.shared.sessionCookie != nil {
            return .authenticated
        }
        return .notAuthenticated
    }
    public var username: String? {
        return user?.username
    }
    
    init(hackerNewsService: HackerNewsService) {
        self.hackerNewsService = hackerNewsService
        HNLogin.shared.addObserver(self)
    }
    
    public func authenticate() -> Promise<AuthenticationState> {
        let (promise, seal) = Promise<AuthenticationState>.pending()
        
        if let username = self.keychain[StorageKeys.username.rawValue],
            let password = self.keychain[StorageKeys.password.rawValue] {
            firstly {
                self.hackerNewsService.login(username: username, password: password)
            }.done { (user, _) in
                if let user = user {
                    self.user = user
                    seal.fulfill(.authenticated)
                } else {
                    seal.fulfill(.notAuthenticated)
                }
            }.catch { error in
                seal.reject(error)
            }
        } else {
            seal.fulfill(.notAuthenticated)
        }
        
        return promise
    }
    
    public func authenticate(username: String, password: String) -> Promise<AuthenticationState> {
        let (promise, seal) = Promise<AuthenticationState>.pending()
        
        firstly {
            self.hackerNewsService.login(username: username, password: password)
        }.done { (user, _) in
            if let user = user {
                self.user = user
                seal.fulfill(.authenticated)
                
                self.keychain[StorageKeys.username.rawValue] = username
                self.keychain[StorageKeys.password.rawValue] = password
            } else {
                seal.fulfill(.notAuthenticated)
            }
        }.catch { error in
            seal.reject(error)
        }
        
        return promise
    }
    
    private enum StorageKeys: String {
        case service = "com.weiranzhang.Hackers"
        case username = "username"
        case password = "password"
    }
    
    public enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}

extension SessionService: HNLoginDelegate {
    func didLogin(user: HNUser, cookie: HTTPCookie) {
        self.user = user
    }
}
