//
//  OnboardingService.swift
//  Hackers
//
//  Created by Weiran Zhang on 15/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import SwiftUI
import WhatsNewKit

enum OnboardingService {
    public static func onboardingViewController(forceShow: Bool = false) -> UIViewController? {
        if ProcessInfo.processInfo.arguments.contains("disableOnboarding"), forceShow == false {
            return nil
        }

        let whatsNew = WhatsNew(
            title: "What's New in Hackers",
            items: items()
        )

        let keyValueVersionStore = KeyValueWhatsNewVersionStore(
            keyValueable: UserDefaults.standard
        )

        let viewController: WhatsNewViewController?

        if forceShow {
            viewController = WhatsNewViewController(
                whatsNew: whatsNew,
                configuration: configuration()
            )
        } else {
            viewController = WhatsNewViewController(
                whatsNew: whatsNew,
                configuration: configuration(),
                versionStore: keyValueVersionStore
            )
        }

        let theme = AppThemeProvider.shared.currentTheme
        viewController?.overrideUserInterfaceStyle = theme.userInterfaceStyle

        return viewController
    }

    private static func configuration() -> WhatsNewViewController.Configuration {
        let appTheme = AppThemeProvider.shared.currentTheme
        let theme = WhatsNewViewController.Theme { theme in
            theme.backgroundColor = appTheme.backgroundColor
            theme.titleView.titleColor = appTheme.titleTextColor
            theme.completionButton.backgroundColor = appTheme.appTintColor
            theme.completionButton.titleColor = .white
            theme.itemsView.titleColor = appTheme.titleTextColor
            theme.itemsView.subtitleColor = appTheme.textColor
        }
        return WhatsNewViewController.Configuration(theme: theme)
    }

    private static func items() -> [WhatsNew.Item] {
        let votingItem = WhatsNew.Item(
            title: "Up Vote",
            subtitle: "Swipe right on posts and comments to up vote them.",
            image: UIImage(named: "UpvoteOnboardingIcon")
        )
        let collapseCommentsItem = WhatsNew.Item(
            title: "Collapse Comments",
            subtitle: "Tap on a comment to collapse its replies. Tap again to expand.",
            image: UIImage(named: "CollapseCommentsOnboardingIcon")
        )
        let swipeCollapseCommentsItem = WhatsNew.Item(
            title: "Collapse Comment Threads",
            subtitle: "Swipe left on a comment to collapse the whole thread of comments.",
            image: UIImage(named: "CollapseCommentThreadOnboardingIcon")
        )
        let darkModeItem = WhatsNew.Item(
            title: "Dark Mode",
            subtitle: "Switch to a true black dark theme in settings.",
            image: UIImage(named: "DarkThemeOnboardingIcon")
        )
        return [votingItem, collapseCommentsItem, swipeCollapseCommentsItem, darkModeItem]
    }
}

struct OnboardingViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = WhatsNewViewController

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<OnboardingViewControllerWrapper>
    ) -> UIViewControllerType {
        let onboardingViewController = OnboardingService.onboardingViewController(forceShow: true)!
        // swiftlint:disable force_cast
        return onboardingViewController as! UIViewControllerType
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: UIViewControllerRepresentableContext<OnboardingViewControllerWrapper>
    ) {}
}
