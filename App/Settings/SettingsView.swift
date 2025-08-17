//
//  SettingsView.swift
//  Hackers
//
//  Created by Weiran Zhang on 22/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showOnboarding = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailView = false

    var body: some View {
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
                            LinkOpener.openURL(url)
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
                    Toggle(isOn: $settings.showThumbnails) {
                        Text("Show Thumbnails")
                    }
                    Toggle(isOn: $settings.swipeActions) {
                        Text("Enable Swipe Actions")
                    }
                    Toggle(isOn: $settings.showComments) {
                        Text("Show Comments Button")
                    }
                }

                Section(header: Text("Behaviour")) {
                    Toggle(isOn: $settings.safariReaderMode) {
                        Text("Open Safari in Reader Mode")
                    }
                    Toggle(isOn: $settings.openInDefaultBrowser) {
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

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsStore())
    }
}
#endif
