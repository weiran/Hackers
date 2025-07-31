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
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @State private var showOnboarding = false
    @State private var showLogin = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailView = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("HACKERS")) {
                    Button(action: {
                        if let url = URL(string: "https://github.com/weiran/hackers") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Website")
                    }
                    Button(action: {
                        self.showMailView.toggle()
                    }) {
                        Text("Send Feedback")
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $showMailView) {
                        MailView(result: self.$mailResult)
                    }
                    Button { self.showOnboarding = true } label: {
                        Text("Show What's New")
                    }.sheet(isPresented: $showOnboarding) {
                        OnboardingViewControllerWrapper()
                    }
                }

                Section(header: Text("LOGIN")) {
                    Button { self.showLogin = true } label: {
                        Text("Account")
                    }.sheet(isPresented: $showLogin) {
                        LoginView()
                    }
                }

                Section(header: Text("APPEARANCE")) {
                    Toggle(isOn: $settings.showThumbnails) {
                        Text("Show Thumbnails")
                    }
                    Toggle(isOn: $settings.swipeActions) {
                        Text("Enable Swipe Actions")
                    }
                    Toggle(isOn: $settings.showComments) {
                        Text("Show Comments Button")
                    }
                    Toggle(isOn: $settings.safariReaderMode) {
                        Text("Open Safari in Reader Mode")
                    }
                    .disabled(settings.openInDefaultBrowser)
                    Toggle(isOn: $settings.openInDefaultBrowser) {
                        Text("Open in Default Browser")
                    }
                }

                Section {
                    versionLabel
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Settings"))
            .navigationBarItems(trailing:
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    label: {
                        Text("Close")
                            .bold()
                    }
                )
            )
        }
    }

    private var versionLabel: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return Text("Version \(appVersion ?? "1.0")")
            .foregroundColor(.gray)
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
