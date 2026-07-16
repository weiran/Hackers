import Shared
import Testing

@Suite("App runtime policy")
struct AppRuntimePolicyTests {
    @Test("Standard runtime enables user-facing system behavior")
    func standardPolicy() {
        #expect(AppRuntimePolicy.standard.allowsCredentialAutoFill)
        #expect(AppRuntimePolicy.standard.allowsReviewPrompts)
    }

    @Test("Automation runtime removes nondeterministic system behavior")
    func automationPolicy() {
        #expect(!AppRuntimePolicy.automation.allowsCredentialAutoFill)
        #expect(!AppRuntimePolicy.automation.allowsReviewPrompts)
    }
}
