//
//  ToastPresenter.swift
//  Shared
//
//  Provides a simple toast presentation service that can be injected and
//  observed by SwiftUI views for lightweight notifications.
//

import Combine
import Foundation
import SwiftUI

public enum ToastKind: Sendable, Equatable {
    case success
    case failure
    case neutral
}

public struct ToastMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let kind: ToastKind

    public init(text: String, kind: ToastKind = .neutral) {
        id = UUID()
        self.text = text
        self.kind = kind
    }
}

@MainActor
public final class ToastPresenter: ObservableObject {
    @Published public private(set) var message: ToastMessage?

    private var dismissTask: Task<Void, Never>?

    public init() {}

    public func show(_ toast: ToastMessage, duration: Duration = .seconds(2)) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            message = toast
        }

        dismissTask = Task { [toastID = toast.id] in
            do {
                try await Task.sleep(for: duration)
            } catch {
                return
            }

            await MainActor.run { [weak self] in
                guard let self, self.message?.id == toastID else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.message = nil
                }
                self.dismissTask = nil
            }
        }
    }

    public func show(text: String, kind: ToastKind = .neutral, duration: Duration = .seconds(2)) {
        show(ToastMessage(text: text, kind: kind), duration: duration)
    }

    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            message = nil
        }
    }
}
