import SwiftUI
import MessageUI

public struct CleanSettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showOnboarding = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailView = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(footer: versionLabel) {
                    HStack {
                        Image(uiImage: Bundle.main.icon ?? UIImage())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                        VStack(alignment: .leading) {
                            Text("Hackers")
                                .font(.title)
                            Text("By Weiran Zhang")
                        }
                    }
                    Button(action: {
                        if let url = URL(string: "https://github.com/weiran/hackers") {
                            UIApplication.shared.open(url)
                        }
                    }, label: {
                        Text("Hackers on GitHub")
                    })
                    Button(action: {
                        self.showMailView.toggle()
                    }, label: {
                        Text("Send Feedback")
                    })
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $showMailView) { MailView(result: self.$mailResult) }
                    Button(action: { self.showOnboarding = true }, label: {
                        Text("Show What's New")
                    })
                    .sheet(isPresented: $showOnboarding) { OnboardingViewControllerWrapper() }
                }

                Section(header: Text("Appearance")) {
                    Toggle(isOn: $viewModel.showThumbnails) {
                        Text("Show Thumbnails")
                    }
                    Toggle(isOn: $viewModel.swipeActions) {
                        Text("Enable Swipe Actions")
                    }
                    Toggle(isOn: $viewModel.showComments) {
                        Text("Show Comments Button")
                    }
                }

                Section(header: Text("Behaviour")) {
                    Toggle(isOn: $viewModel.safariReaderMode) {
                        Text("Open Safari in Reader Mode")
                    }
                    Toggle(isOn: $viewModel.openInDefaultBrowser) {
                        Text("Open in System Browser")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Settings"))
            .navigationBarItems(trailing:
                Button(
                    action: {
                        dismiss()
                    },
                    label: {
                        Image(systemName: "xmark")
                    }
                )
            )
        }
    }

    private var versionLabel: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return HStack {
            Spacer()
            Text("Version \(appVersion ?? "1.0")")
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// These need to be provided by the main app, so for now we'll create placeholders
struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let parentCopy = parent
            Task { @MainActor in
                controller.dismiss(animated: true)
                if let error = error {
                    parentCopy.result = .failure(error)
                } else {
                    parentCopy.result = .success(result)
                }
            }
        }
    }
}

struct OnboardingViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // Placeholder
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}