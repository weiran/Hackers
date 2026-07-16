import SwiftUI

public struct AppRuntimePolicy: Equatable, Sendable {
    public let allowsCredentialAutoFill: Bool
    public let allowsReviewPrompts: Bool

    public init(
        allowsCredentialAutoFill: Bool,
        allowsReviewPrompts: Bool
    ) {
        self.allowsCredentialAutoFill = allowsCredentialAutoFill
        self.allowsReviewPrompts = allowsReviewPrompts
    }

    public static let standard = AppRuntimePolicy(
        allowsCredentialAutoFill: true,
        allowsReviewPrompts: true
    )

    public static let automation = AppRuntimePolicy(
        allowsCredentialAutoFill: false,
        allowsReviewPrompts: false
    )
}

private struct AppRuntimePolicyKey: EnvironmentKey {
    static let defaultValue = AppRuntimePolicy.standard
}

public extension EnvironmentValues {
    var appRuntimePolicy: AppRuntimePolicy {
        get { self[AppRuntimePolicyKey.self] }
        set { self[AppRuntimePolicyKey.self] = newValue }
    }
}
