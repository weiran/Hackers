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
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .task(id: url) { await load(url) }
            .task { await monitorNavigations() }
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
                if UIDevice.current.userInterfaceIdiom == .pad {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .accessibilityLabel("Back")
                        .disabled(!canGoBack)

                        Button {
                            goForward()
                        } label: {
                            Image(systemName: "chevron.forward")
                        }
                        .accessibilityLabel("Forward")
                        .disabled(!canGoForward)

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

    private var openInSafariButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = currentURL ?? url
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
    private func load(_ target: URL) async {
        guard currentURL != target else { return }
        currentURL = target
        _ = page.load(target)
        updateState()
    }

    @MainActor
    private func monitorNavigations() async {
        updateState()
        do {
            for try await _ in page.navigations {
                updateState()
            }
        } catch {
            // Ignore navigation stream errors; state updates happen on successful events.
        }
    }

    @MainActor
    private func updateState() {
        currentURL = page.url ?? currentURL ?? url
        currentTitle = page.title
        let list = page.backForwardList
        canGoBack = !list.backList.isEmpty
        canGoForward = !list.forwardList.isEmpty
    }

    @MainActor
    private func reload() {
        _ = page.reload()
        updateState()
    }

    @MainActor
    private func goBack() {
        guard let item = page.backForwardList.backList.last else { return }
        _ = page.load(item)
        updateState()
    }

    @MainActor
    private func goForward() {
        guard let item = page.backForwardList.forwardList.first else { return }
        _ = page.load(item)
        updateState()
    }
}
