//
//  MailView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import MessageUI

public struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    let recipients: [String]
    let subject: String
    let messageBody: String

    public init(
        result: Binding<Result<MFMailComposeResult, Error>?>,
        recipients: [String] = [],
        subject: String = "",
        messageBody: String = ""
    ) {
        self._result = result
        self.recipients = recipients
        self.subject = subject
        self.messageBody = messageBody
    }

    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = context.coordinator

        // Ensure configuration happens on main queue with slight delay
        // This fixes iOS 18+ issue where fields appear blank
        DispatchQueue.main.async {
            mailVC.setToRecipients(self.recipients)
            mailVC.setSubject(self.subject)
            mailVC.setMessageBody(self.messageBody, isHTML: false)
        }

        return mailVC
    }

    public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        nonisolated public func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
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
