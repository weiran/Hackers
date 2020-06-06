//
//  NewsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SafariServices
import PromiseKit
import Kingfisher
import Loaf
import SwipeCellKit

class NewsViewController: UITableViewController {
    public var authenticationUIService: AuthenticationUIService?
    public var swipeCellKitActions: SwipeCellKitActions?

    private var posts = [HackerNewsPost]()
    private var dataSource: UITableViewDiffableDataSource<Section, HackerNewsPost>?
    public var postType: HackerNewsPostType = .news

    private var peekedIndexPath: IndexPath?
    private var pageIndex = 1
    private var isFetching = false

    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForPreviewing(with: self, sourceView: tableView)

        tableView.refreshControl?.addTarget(self,
                                            action: #selector(fetchPostsWithReset),
                                            for: UIControl.Event.valueChanged)
        tableView.tableFooterView = UIView(frame: .zero) // remove cell separators on empty table
        tableView.backgroundView = TableViewBackgroundView.loadingBackgroundView()
        dataSource = makeDataSource()
        tableView.dataSource = dataSource

        notificationToken = NotificationCenter.default
            .observe(name: AuthenticationUIService.Notifications.AuthenticationDidChangeNotification,
                     object: nil,
                     queue: .main
            ) { _ in self.fetchPostsWithReset() }

        setupTheming()
        fetchPosts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // when the cell is still visible, no need to deselect it
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            smoothlyDeselectRows()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCommentsSegue",
            let navigationController = segue.destination as? UINavigationController,
            let commentsViewController = navigationController.viewControllers.first as? CommentsViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            commentsViewController.post = posts[indexPath.row]
        }
    }

    private func navigateToComments() {
        performSegue(withIdentifier: "ShowCommentsSegue", sender: self)
    }

    @IBAction func showNewSettings(_ sender: Any) {
        let settingsStore = SettingsStore()
        let hostingVC = UIHostingController(
            rootView: SettingsView()
                .environmentObject(settingsStore))
        present(hostingVC, animated: true)
    }
}

extension NewsViewController { // post fetching
    @objc private func fetchPosts() {
        guard !isFetching else { return }

        isFetching = true
        let isFirstPage = pageIndex == 1

        firstly {
            HackerNewsData.shared.getPosts(type: postType, page: pageIndex)
        }.done { posts in
            if isFirstPage {
                self.posts = [HackerNewsPost]()
            }
            self.posts.append(contentsOf: posts)
            self.update(with: self.posts, animate: !isFirstPage)
        }.catch { error in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }.finally {
            self.isFetching = false
            self.tableView.refreshControl?.endRefreshing()
            self.pageIndex += 1
        }
    }

    @objc private func fetchPostsWithReset() {
        pageIndex = 1
        fetchPosts()
    }
}

extension NewsViewController {
    enum Section: CaseIterable {
        case main
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, HackerNewsPost> {
        let reuseIdentifier = "PostCell"

        return UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, post) in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: reuseIdentifier,
                for: indexPath
            ) as? PostCell else { return nil }
            cell.postDelegate = self
            cell.delegate = self

            cell.postTitleView.post = post
            cell.postTitleView.delegate = self
            cell.setImageWithPlaceholder(url: post.url)

            return cell
        }
    }

    func update(with posts: [HackerNewsPost], animate: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, HackerNewsPost>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(posts)
        self.dataSource?.apply(snapshot, animatingDifferences: animate)
    }
}

extension NewsViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let buffer: CGFloat = 200
        let scrollPosition = scrollView.contentOffset.y
        let bottomPosition = scrollView.contentSize.height - scrollView.frame.size.height

        if scrollPosition > bottomPosition - buffer {
            fetchPosts()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        if postType == .jobs {
            didPressLinkButton(post)
        } else {
            navigateToComments()
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension NewsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let post = posts[indexPath.row]
        guard orientation == .left,
            post.postType != .jobs else {
                return nil
        }

        return swipeCellKitActions?.voteAction(post: post, tableView: tableView,
                                               indexPath: indexPath, viewController: self)
    }

    func tableView(_ tableView: UITableView,
                   editActionsOptionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> SwipeOptions {
        let expansionStyle = SwipeExpansionStyle(target: .percentage(0.2),
                                                 elasticOverscroll: false,
                                                 completionAnimation: .bounce)
        var options = SwipeOptions()
        options.expansionStyle = expansionStyle
        options.expansionDelegate = BounceExpansion()
        options.transitionStyle = .drag
        return options
    }
}

extension NewsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.refreshControl?.tintColor = theme.appTintColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}

extension NewsViewController: UIViewControllerPreviewingDelegate, SFSafariViewControllerPreviewActionItemsDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard
            let indexPath = tableView.indexPathForRow(at: location),
            posts.count > indexPath.row else {
                return nil
        }
        let post = posts[indexPath.row]
        if UIApplication.shared.canOpenURL(post.url) {
            peekedIndexPath = indexPath
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            return SFSafariViewController.instance(for: post.url, previewActionItemsDelegate: self)
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true, completion: nil)
    }

    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem] {
        guard let indexPath = peekedIndexPath else {
            return [UIPreviewActionItem]()
        }

        let post = posts[indexPath.row]
        let commentsPreviewActionTitle = post.commentsCount > 0 ?
            "View \(post.commentsCount) comments" : "View comments"

        let viewCommentsPreviewAction =
            UIPreviewAction(title: commentsPreviewActionTitle,
                            style: .default) { [unowned self, indexPath = indexPath] (_, _) -> Void in
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.navigateToComments()
        }
        return [viewCommentsPreviewAction]
    }
}

extension NewsViewController: PostTitleViewDelegate, PostCellDelegate {
    func didPressLinkButton(_ post: HackerNewsPost) {
        if let safariViewController =
            SFSafariViewController.instance(for: post.url, previewActionItemsDelegate: self) {
            navigationController?.present(safariViewController, animated: true)
        }
    }

    func didTapThumbnail(_ sender: Any) {
        guard let tapGestureRecognizer = sender as? UITapGestureRecognizer else { return }
        let point = tapGestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            didPressLinkButton(post)
        }
    }
}
