//
//  OpenInViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class OpenInViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = item.attachments?.first,
            itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(
                forTypeIdentifier: "public.url",
                options: nil,
                completionHandler: { url, _ in
                    if let shareURL = url as? URL,
                        shareURL.host?.localizedCaseInsensitiveCompare("news.ycombinator.com") == .orderedSame,
                        let components = URLComponents(url: shareURL, resolvingAgainstBaseURL: true),
                        let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                        let id = Int(idString),
                        let openInURL = URL(string: "com.weiranzhang.Hackers://item?id=\(id)") {
                        DispatchQueue.main.async {
                            SharedExtensions.open(openInURL, in: self)
                            self.close()
                        }
                    } else {
                        self.error()
                    }
            })
        } else {
            self.error()
        }
    }

    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    func error() { }
}
