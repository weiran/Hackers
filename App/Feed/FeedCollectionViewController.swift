//
//  FeedCollectionViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit
import PromiseKit
import SafariServices

class FeedCollectionViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    private lazy var dataSource = makeDataSource()
    private lazy var viewModel = FeedViewModel()

    private var refreshToken: NotificationToken?
    private let cellIdentifier = "ItemCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupCollectionViewListConfiguration()
        setupTitle()
        setupNotificationCenter()
        showOnboarding()

        fetchFeed()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectItems(collectionView)
    }

    private func setupTitle() {
        let button = TitleButton()
        button.setTitleText(viewModel.postType.title)
        button.setupMenu()
        button.handler = { postType in
            self.viewModel.postType = postType
            self.setupTitle()
            self.viewModel.reset()
            self.update(with: self.viewModel, animate: false)
            self.fetchFeed()
        }

        navigationItem.titleView = button
        title = viewModel.postType.title
    }

    private func fetchFeed(fetchNextPage: Bool = false) {
        firstly {
            viewModel.fetchFeed(fetchNextPage: fetchNextPage)
        }.done {
            self.update(with: self.viewModel, animate: fetchNextPage == true)
        }.catch { _ in
            UINotifications.showError()
        }.finally {
            self.collectionView.refreshControl?.endRefreshing()
        }
    }

    @objc private func fetchFeedWithReset() {
        setupCollectionViewListConfiguration()
        viewModel.reset()
        fetchFeed()
    }

    @objc private func fetchFeedNextPage() {
        fetchFeed(fetchNextPage: true)
    }

    private func setupNotificationCenter() {
        refreshToken = NotificationCenter.default.observe(
            name: Notification.Name.refreshRequired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchFeedWithReset()
        }
    }

    private func showOnboarding() {
        if let onboardingVC = OnboardingService.onboardingViewController() {
            present(onboardingVC, animated: true)
        }
    }
}

extension FeedCollectionViewController: UICollectionViewDelegate {

    private func setupCollectionViewListConfiguration() {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)

        if UserDefaults.standard.swipeActionsEnabled {
            config.leadingSwipeActionsConfigurationProvider = voteSwipeActionConfiguration(indexPath:)
        }

        config.showsSeparators = false

        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView.setCollectionViewLayout(layout, animated: false)
    }

    private func setupCollectionView() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(fetchFeedWithReset),
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl

        collectionView.backgroundView = TableViewBackgroundView.loadingBackgroundView()

        collectionView.register(
            UINib(nibName: cellIdentifier, bundle: nil),
            forCellWithReuseIdentifier: cellIdentifier
        )

        collectionView.dataSource = dataSource
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<FeedViewModel.Section, Post> {
        return UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, post) in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: self.cellIdentifier,
                for: indexPath
            ) as? ItemCell else {
                fatalError("Couldn't dequeue cell \(self.cellIdentifier)")
            }

            cell.apply(post: post)
            cell.setupThumbnail(with: UserDefaults.standard.showThumbnails ? post.url : nil)

            cell.linkPressedHandler = { post in
                guard !post.url.absoluteString.starts(with: "item?id=") else {
                    self.collectionView.selectItem(at: indexPath, animated: true)
                    self.performSegue(withIdentifier: "ShowCommentsSegue", sender: self)
                    return
                }

                self.openURL(url: post.url) {
                    if let svc = SFSafariViewController.instance(for: post.url) {
                        self.navigationController?.present(svc, animated: true) {
                            _ = DraggableCommentsButton(for: svc, and: post)
                        }
                    }
                }
            }

            return cell
        }
    }

    private func update(with viewModel: FeedViewModel, animate: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<FeedViewModel.Section, Post>()
        snapshot.appendSections(FeedViewModel.Section.allCases)
        snapshot.appendItems(viewModel.posts, toSection: FeedViewModel.Section.main)
        self.dataSource.apply(snapshot, animatingDifferences: animate)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.postType == .jobs,
           let post = dataSource.itemIdentifier(for: indexPath),
           !post.url.absoluteString.starts(with: "item?id=") { // self job posts should show comments
            self.openURL(url: post.url) {
                if let svc = SFSafariViewController.instance(for: post.url) {
                    self.navigationController?.present(svc, animated: true) {
                        _ = DraggableCommentsButton(for: svc, and: post)
                    }
                }
            }
        } else {
            performSegue(withIdentifier: "ShowCommentsSegue", sender: collectionView)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if indexPath.row == viewModel.posts.count - 5 && !viewModel.isFetching {
            fetchFeedNextPage()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let post = viewModel.posts[indexPath.row]

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil
        ) { _ in
            let upvote = UIAction(
                title: "Upvote",
                image: UIImage(systemName: "arrow.up"),
                identifier: UIAction.Identifier(rawValue: "upvote")
            ) { _ in
                self.vote(on: post)
            }

            let unvote = UIAction(
                title: "Unvote",
                image: UIImage(systemName: "arrow.uturn.down"),
                identifier: UIAction.Identifier(rawValue: "unvote")
            ) { _ in
                self.vote(on: post)
            }

            let openLink = UIAction(
                title: "Open Link",
                image: UIImage(systemName: "safari"),
                identifier: UIAction.Identifier(rawValue: "open.link")
            ) { _ in
                self.openURL(url: post.url) {
                    if let svc = SFSafariViewController.instance(for: post.url) {
                        self.navigationController?.present(svc, animated: true) {
                            _ = DraggableCommentsButton(for: svc, and: post)
                        }
                    }
                }
            }

            let shareLink = UIAction(
                title: "Share Link",
                image: UIImage(systemName: "square.and.arrow.up"),
                identifier: UIAction.Identifier(rawValue: "share.link")
            ) { _ in
                let url = post.url.host != nil ? post.url : post.hackerNewsURL
                let activityViewController = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                let cell = collectionView.cellForItem(at: indexPath)
                activityViewController.popoverPresentationController?.sourceView = cell
                self.present(activityViewController, animated: true, completion: nil)
            }

            let voteMenu = post.upvoted ? unvote : upvote
            let linkMenu = UIMenu(title: "", options: .displayInline, children: [openLink, shareLink])

            return UIMenu(title: "", image: nil, identifier: nil, children: [voteMenu, linkMenu])
        }
    }
}

extension FeedCollectionViewController {
    private func voteSwipeActionConfiguration(indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let post = self.viewModel.posts[indexPath.row]

        let voteAction = UIContextualAction(
            style: .normal,
            title: nil,
            handler: { _, _, completion in
                self.vote(on: post)
                completion(true)
            }
        )

        if post.upvoted {
            // unvote
            voteAction.image = UIImage(systemName: "arrow.uturn.down")
        } else {
            voteAction.image = UIImage(systemName: "arrow.up")
        }

        if !post.upvoted {
            voteAction.backgroundColor = AppTheme.default.upvotedColor
        }

        return UISwipeActionsConfiguration(actions: [voteAction])
    }

    private func vote(on post: Post) {
        let isUpvote = !post.upvoted

        // optimistally update
        updateVote(on: post, isUpvote: isUpvote)

        firstly {
            viewModel.vote(on: post, upvote: isUpvote)
        }.catch { [weak self] error in
            self?.updateVote(on: post, isUpvote: !isUpvote)
            self?.handleVoteError(error: error)
        }
    }

    private func updateVote(on post: Post, isUpvote: Bool) {
        post.upvoted = isUpvote
        post.score += isUpvote ? 1 : -1

        if let index = viewModel.posts.firstIndex(of: post),
           let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? ItemCell {
            cell.apply(post: post)
        }
    }

    private func handleVoteError(error: Error) {
        guard let error = error as? HackersKitError else {
            return
        }

        switch error {
        case .unauthenticated:
            self.present(
                AuthenticationHelper.unauthenticatedAlertController(self),
                animated: true
            )
        default:
            UINotifications.showError()
        }
    }
}

extension FeedCollectionViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCommentsSegue",
           let navVC = segue.destination as? UINavigationController,
           let commentsVC = navVC.children.first as? CommentsViewController,
           let indexPath = collectionView.indexPathsForSelectedItems?.first,
           let post = dataSource.itemIdentifier(for: indexPath) {
            commentsVC.post = post
            commentsVC.postId = post.id
        }
    }
}
