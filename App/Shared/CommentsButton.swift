//
//  CommentsButton.swift
//  Hackers
//
//  Created by Stanislav Rassolenko on 7/2/24.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI

struct CommentsButton: View {
    let post: Post
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geometry in
            Button(action: onTap) {
                Label("Comments", systemImage: "message")
                    .labelStyle(.iconOnly)
                    .frame(width: 46, height: 46)
                    .foregroundStyle(Color(UIColor.label))
            }
            .glassEffect(in: .rect(cornerRadius: 23.0))
            .position(
                x: geometry.size.width - 46,
                y: geometry.size.height - 80
            )
        }
    }
}

// MARK: - UIKit Integration Helper
extension CommentsButton {
    static func attachTo(_ parentViewController: UIViewController, with post: Post) {
        guard UserDefaults.standard.showCommentsButton else { return }
        
        let commentsButton = CommentsButton(post: post) {
            let navigationStore = NavigationStore()
            let commentsView = CommentsView(post: post)
                .environmentObject(navigationStore)
            
            let hostingController = UIHostingController(rootView: commentsView)
            let navigationController = UINavigationController(rootViewController: hostingController)
            
            parentViewController.present(navigationController, animated: true)
        }
        
        let hostingController = UIHostingController(rootView: commentsButton)
        hostingController.view.backgroundColor = .clear
        
        parentViewController.addChild(hostingController)
        parentViewController.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: parentViewController)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor)
        ])
    }
}
