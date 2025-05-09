//
//  DraggableCommentsButton.swift
//  Hackers
//
//  Created by Stanislav Rassolenko on 7/2/24.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class DraggableCommentsButton: UIButton {
    private var post: Post
    private var parentVc: UIViewController

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.text = String(post.commentsCount)
        label.textColor = AppTheme.default.titleTextColor
        label.backgroundColor = AppTheme.default.cellHighlightColor
        label.cornerRadius = 12.5
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    required init(for parent: UIViewController, and post: Post) {
        self.parentVc = parent
        self.post = post
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        setupLayout()
        setupForParent()
        setupCountLabel()
    }

    private func setupLayout() {
        layer.cornerRadius = 25
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        setImage(UIImage(
            systemName: "message",
            withConfiguration: UIImage.SymbolConfiguration(weight: .bold)
        ), for: .normal)
        imageView?.contentMode = .scaleToFill
        imageView?.tintColor = .white
        isOpaque = true
        translatesAutoresizingMaskIntoConstraints = false

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragHandler)))
    }

    private func setupForParent() {
        addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        parentVc.view.addSubview(self)
        constrainSelf()
        parentVc.view.bringSubviewToFront(self)
        layer.zPosition = parentVc.view.layer.zPosition + 1
        for subview in parentVc.view.subviews {
            subview.isUserInteractionEnabled = false
        }
        isEnabled = true
        isUserInteractionEnabled = true
    }

    private func setupCountLabel() {
        addSubview(countLabel)
        constrainCountLabel()
    }

    private func constrainCountLabel() {
        countLabel.centerXAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        countLabel.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        countLabel.widthAnchor.constraint(equalToConstant: 25).isActive = true
        countLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }

    private func constrainSelf() {
        bottomAnchor.constraint(equalTo: parentVc.view.safeAreaLayoutGuide.bottomAnchor, constant: -60).isActive = true
        trailingAnchor.constraint(equalTo: parentVc.view.trailingAnchor, constant: -16).isActive = true
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        widthAnchor.constraint(equalToConstant: 50).isActive = true
    }

    @objc private func buttonAction() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentsVc = storyboard.instantiateViewController(
            withIdentifier: "CommentsViewController"
        ) as? CommentsViewController

        if let cvc = commentsVc {
            cvc.postId = post.id
            cvc.showPost = false
            cvc.post = post
            let navigationController = UINavigationController(rootViewController: cvc)
            self.parentVc.present(navigationController, animated: true, completion: nil)
        }
    }

    @objc private func dragHandler(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: parentVc.view)
        let draggedView = gesture.view
        draggedView?.center = location

        if gesture.state == .ended {
            if self.frame.midX >= (self.parentVc.view.layer.frame.width) / 2 {
                self.positionViewWithAnimation {
                    self.center.x = (self.parentVc.view.layer.frame.width) - 40
                }
            } else {
                self.positionViewWithAnimation {
                    self.center.x = 40
                }
            }
        }
    }

    private func positionViewWithAnimation(animation: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: .curveEaseIn,
            animations: animation,
            completion: nil
        )
    }
}

extension DraggableCommentsButton {
    public static func attachTo(_ parentVc: UIViewController, with post: Post) {
        if UserDefaults.standard.showCommentsButton {
            _ = DraggableCommentsButton(for: parentVc, and: post)
        }
    }
}
