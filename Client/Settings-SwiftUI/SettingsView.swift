//
//  SettingsView.swift
//  Hackers
//
//  Created by Weiran Zhang on 22/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @State var showOnboarding = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LOGIN")) {
                    Text("Account")
                }

                Section(header: Text("APPEARANCE")) {
                    Picker(
                        selection: $settings.theme,
                        label: Text("Theme")
                    ) {
                        Text("System").tag(SettingsStore.ThemeType.system)
                        Text("Light").tag(SettingsStore.ThemeType.light)
                        Text("Dark").tag(SettingsStore.ThemeType.dark)
                    }

                    Toggle(isOn: $settings.safariReaderMode) {
                        Text("Open Safari in Reader Mode")
                    }
                }

                Section(header: Text("MORE")) {
                    Button(action: {
                        self.showOnboarding = true
                    }) {
                        Text("Show What's New")
                    }.sheet(isPresented: $showOnboarding) {
                        OnboardingViewControllerWrapper()
                    }
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
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsStore())
    }
}
#endif
