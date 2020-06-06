//
//  TableViewBackgroundView.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import UIKit

class TableViewBackgroundView: UIView {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!

    var state: TableViewState = .loading {
        didSet {
            updateState()
        }
    }
    var emptyTitle = "No data" {
        didSet {
            updateState()
        }
    }

    enum TableViewState {
        case loading
        case empty
    }

    override func layoutSubviews() {
        setupTheming()
        updateState()
    }

    private func updateState() {
        switch state {
        case .loading:
            activityIndicatorView.isHidden = false
            titleLabel.isHidden = true
        case .empty:
            activityIndicatorView.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = emptyTitle
        }
    }
}

extension TableViewBackgroundView: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
        titleLabel.textColor = theme.textColor
        activityIndicatorView.style = .medium
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}

extension TableViewBackgroundView {
    static func loadingBackgroundView() -> TableViewBackgroundView? {
        guard let view = Bundle.main.loadNibNamed(
            "TableViewBackgroundView",
            owner: self,
            options: nil
        )?.first as? TableViewBackgroundView else {
            return nil
        }
        view.state = .loading
        return view
    }

    static func emptyBackgroundView(message: String) -> TableViewBackgroundView? {
        guard let view = Bundle.main.loadNibNamed(
            "TableViewBackgroundView",
            owner: self,
            options: nil
        )?.first as? TableViewBackgroundView else {
            return nil
        }
        view.state = .empty
        view.emptyTitle = message
        return view
    }
}
