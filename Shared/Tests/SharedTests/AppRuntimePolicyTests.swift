import Shared
import Testing

@Suite("App runtime policy")
struct AppRuntimePolicyTests {
    @Test("Commenting is opt-in for automation and can be changed independently")
    func commentingIsOptIn() {
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
        let automationEnabled = AppRuntimePolicy.automation.withCommenting(true)
        #expect(automationEnabled.allowsCommenting)
        #expect(!automationEnabled.allowsCredentialAutoFill)
        #expect(!automationEnabled.allowsReviewPrompts)
    }
}
