//
//  OpenInViewController.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import UIKit

class OpenInViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
           let itemProvider = item.attachments?.first,
           itemProvider.hasItemConformingToTypeIdentifier("public.url")
        {
            itemProvider.loadItem(
                forTypeIdentifier: "public.url",
                options: nil,
                completionHandler: { url, _ in
                    if let shareURL = url as? URL,
                       shareURL.host?.localizedCaseInsensitiveCompare("news.ycombinator.com") == .orderedSame,
                       let components = URLComponents(url: shareURL, resolvingAgainstBaseURL: true),
                       let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                       let id = Int(idString),
                       let openInURL = URL(string: "com.weiranzhang.Hackers://item?id=\(id)")
                    {
                        DispatchQueue.main.async {
                            self.openURL(openInURL)
                            self.close()
                        }
                    } else {
                        self.error()
                    }
                },
            )
        } else {
            error()
        }
    }

    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    func error() {}

    /// Specifically crafted `openURL` to work with shared extensions
    /// https://stackoverflow.com/a/79077875
    @objc @discardableResult func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = responder?.next
        }
        return false
    }
}
