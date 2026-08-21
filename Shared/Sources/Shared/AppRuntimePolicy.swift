import SwiftUI

public struct AppRuntimePolicy: Equatable, Sendable {
    public let allowsCredentialAutoFill: Bool
    public let allowsReviewPrompts: Bool
    public let allowsCommenting: Bool

    public init(
        allowsCredentialAutoFill: Bool,
        allowsReviewPrompts: Bool,
        allowsCommenting: Bool = false
    ) {
        self.allowsCredentialAutoFill = allowsCredentialAutoFill
        self.allowsReviewPrompts = allowsReviewPrompts
        self.allowsCommenting = allowsCommenting
    }

    public static let standard = AppRuntimePolicy(
        allowsCredentialAutoFill: true,
        allowsReviewPrompts: true,
        allowsCommenting: false
    )

    public static let automation = AppRuntimePolicy(
        allowsCredentialAutoFill: false,
        allowsReviewPrompts: false,
        allowsCommenting: false
    )

    public func withCommenting(_ enabled: Bool) -> AppRuntimePolicy {
        AppRuntimePolicy(
            allowsCredentialAutoFill: allowsCredentialAutoFill,
            allowsReviewPrompts: allowsReviewPrompts,
            allowsCommenting: enabled
        )
    }
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
