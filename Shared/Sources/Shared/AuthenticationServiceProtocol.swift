import Foundation

@MainActor
public protocol AuthenticationServiceProtocol: ObservableObject {
    var isAuthenticated: Bool { get }
    var username: String? { get }
    
    func showLogin()
}