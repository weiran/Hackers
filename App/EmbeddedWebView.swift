//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import Shared
import SwiftUI
import WebKit

struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool

    @State private var currentURL: URL?
    @State private var currentTitle: String?

    var body: some View {
        WebKitView(
            url: url,
            onUpdate: { updatedURL, updatedTitle in
                Task { @MainActor in
                    currentURL = updatedURL
                    currentTitle = updatedTitle
                }
            }
        )
        .ignoresSafeArea(.container, edges: .all)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                shareButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                if showsCloseButton {
                    closeButton
                }
            }
        }
    }

    private var shareButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = currentURL ?? url
                ContentSharePresenter.shared.shareURL(targetURL, title: currentTitle)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share")
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("Close")
    }
}

// TODO: Replace WebKitView with native WebView once macOS Catalyst supports it.
private struct WebKitView: UIViewRepresentable {
    let url: URL
    let onUpdate: (URL?, String?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onUpdate: onUpdate)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        context.coordinator.load(url: url, into: webView)
        context.coordinator.forwardUpdate(from: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(url: url, into: webView)
        context.coordinator.forwardUpdate(from: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onUpdate: (URL?, String?) -> Void
        private var lastRequestedURL: URL?

        init(onUpdate: @escaping (URL?, String?) -> Void) {
            self.onUpdate = onUpdate
        }

        func load(url: URL, into webView: WKWebView) {
            guard lastRequestedURL != url else { return }
            lastRequestedURL = url
            let request = URLRequest(url: url)
            webView.load(request)
        }

        func forwardUpdate(from webView: WKWebView) {
            if let currentURL = webView.url {
                lastRequestedURL = currentURL
            }
            onUpdate(webView.url, webView.title)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            forwardUpdate(from: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError _: Error) {
            forwardUpdate(from: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError _: Error) {
            forwardUpdate(from: webView)
        }
    }
}
