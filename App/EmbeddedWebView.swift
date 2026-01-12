//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import Combine
import Foundation
import Shared
import SwiftUI
import WebKit

struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool

    @StateObject private var model = EmbeddedWebViewModel()

    var body: some View {
        WebViewContainer(webView: model.webView)
            .task(id: url) { await model.load(url) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    openInSafariButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if showsCloseButton {
                        closeButton
                    }
                }
                if isPadLayout {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .accessibilityLabel("Back")
                        .disabled(!model.canGoBack)

                        Button {
                            goForward()
                        } label: {
                            Image(systemName: "chevron.forward")
                        }
                        .accessibilityLabel("Forward")
                        .disabled(!model.canGoForward)

                        Button {
                            reload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Reload")
                    }
                }
            }
    }

    private var isPadLayout: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac
        #endif
    }

    private var shareButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = model.currentURL ?? url
                ContentSharePresenter.shared.shareURL(targetURL, title: model.currentTitle)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share")
    }

    private var openInSafariButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = model.currentURL ?? url
                LinkOpener.openURL(targetURL)
            }
        } label: {
            Image(systemName: "safari")
        }
        .accessibilityLabel("Open in Safari")
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("Close")
    }

    @MainActor
    private func reload() {
        model.reload()
    }

    @MainActor
    private func goBack() {
        model.goBack()
    }

    @MainActor
    private func goForward() {
        model.goForward()
    }
}

@MainActor
private final class EmbeddedWebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var currentURL: URL?
    @Published var currentTitle: String?
    @Published var canGoBack = false
    @Published var canGoForward = false

    let webView: WKWebView

    override init() {
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
    }

    func load(_ target: URL) {
        guard currentURL != target else { return }
        currentURL = target
        webView.load(URLRequest(url: target))
        updateState()
    }

    func reload() {
        webView.reload()
        updateState()
    }

    func goBack() {
        webView.goBack()
        updateState()
    }

    func goForward() {
        webView.goForward()
        updateState()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didCommit _: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        updateState()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        updateState()
    }

    private func updateState() {
        currentURL = webView.url ?? currentURL
        currentTitle = webView.title
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

@MainActor
private struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context _: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ uiView: WKWebView, context _: Context) {
        if uiView !== webView {
            uiView.navigationDelegate = webView.navigationDelegate
        }
    }
}
