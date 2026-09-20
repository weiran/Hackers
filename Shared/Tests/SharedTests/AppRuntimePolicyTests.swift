import Shared
import Testing

@Suite("App runtime policy")
struct AppRuntimePolicyTests {
    @Test("Standard runtime enables user-facing system behavior")
    func standardPolicy() {
        #expect(AppRuntimePolicy.standard.allowsCredentialAutoFill)
        #expect(AppRuntimePolicy.standard.allowsReviewPrompts)
        #expect(AppRuntimePolicy.standard.allowsCommenting)
    }

    @Test("Automation runtime removes nondeterministic system behavior")
    func automationPolicy() {
        #expect(!AppRuntimePolicy.automation.allowsCredentialAutoFill)
        #expect(!AppRuntimePolicy.automation.allowsReviewPrompts)
    }

    @Test("Commenting stays disabled unless explicitly enabled")
    func commentingDefaults() {
        #expect(AppRuntimePolicy.automation.allowsCommenting == false)
        #expect(!AppRuntimePolicy(
            allowsCredentialAutoFill: true,
            allowsReviewPrompts: true
        ).allowsCommenting)
    }

    @Test("withCommenting enables commenting without touching other capabilities")
    func withCommenting() {
        let enabled = AppRuntimePolicy.standard.withCommenting(true)

        #expect(enabled.allowsCommenting)
        #expect(enabled.allowsCredentialAutoFill == AppRuntimePolicy.standard.allowsCredentialAutoFill)
        #expect(enabled.allowsReviewPrompts == AppRuntimePolicy.standard.allowsReviewPrompts)

        let automationEnabled = AppRuntimePolicy.automation.withCommenting(true)
        #expect(automationEnabled.allowsCommenting)
        #expect(!automationEnabled.allowsCredentialAutoFill)
        #expect(!automationEnabled.allowsReviewPrompts)

        #expect(AppRuntimePolicy.standard.withCommenting(false) == AppRuntimePolicy(
            allowsCredentialAutoFill: true,
            allowsReviewPrompts: true,
            allowsCommenting: false
        ))
    }
}
