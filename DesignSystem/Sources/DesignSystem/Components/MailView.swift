//
//  MailView.swift
//  DesignSystem
//
//  Mail compose view
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
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        public func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
        }
    }
}