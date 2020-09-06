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
import Loaf

class FeedCollectionViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    var authenticationUIService: AuthenticationUIService?

    private lazy var dataSource = makeDataSource()
    private lazy var viewModel = FeedViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupTitle()

        fetchFeed()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        smoothlyDeselectItems(collectionView)
    }

    private func fetchFeed(fetchNextPage: Bool = false) {
        firstly {
            viewModel.fetchFeed(fetchNextPage: fetchNextPage)
        }.done {
            self.update(with: self.viewModel)
        }.catch { _ in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }.finally {
            self.collectionView.refreshControl?.endRefreshing()
        }
    }

    @objc private func fetchFeedWithReset() {
        viewModel.reset()
        fetchFeed()
    }

    @objc private func fetchFeedNextPage() {
        fetchFeed(fetchNextPage: true)
    }
}

extension FeedCollectionViewController: Themed {
    func applyTheme(_ theme: AppTheme) { }
}

extension FeedCollectionViewController {
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
}

extension FeedCollectionViewController: UICollectionViewDelegate {
    private func setupCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.leadingSwipeActionsConfigurationProvider = voteSwipeActionConfiguration(indexPath:)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(fetchFeedWithReset),
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl

        collectionView.backgroundView = TableViewBackgroundView.loadingBackgroundView()

        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.dataSource = dataSource

        collectionView.reloadData()
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<FeedViewModel.Section, Post> {
        let reuseIdentifier = "FeedItemCell"

        return UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, post) in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseIdentifier,
                for: indexPath
            ) as? FeedItemCell else {
                fatalError("Couldn't dequeue cell \(reuseIdentifier)")
            }

            cell.setImageWithPlaceholder(
                url: UserDefaults.standard.showThumbnails ? post.url : nil
            )

            cell.postTitleView.post = post
            cell.linkPressedHandler = { post in
                self.openURL(post.url)
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
           let post = dataSource.itemIdentifier(for: indexPath) {
            openURL(post.url)
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
                self.openURL(post.url)
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
            title: "Upvote",
            handler: { _, _, completion in
                self.vote(on: post)
                completion(true)
            }
        )

        voteAction.image = UIImage(
            systemName: post.upvoted ? "arrow.uturn.down" : "arrow.up"
        )
        if !post.upvoted {
            voteAction.backgroundColor = self.themeProvider.currentTheme.upvotedColor
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
           let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? FeedItemCell {
            cell.postTitleView.post = post
        }
    }

    private func handleVoteError(error: Error) {
        guard
            let error = error as? HackersKitError,
            let authenticationUIService = self.authenticationUIService else {
            return
        }

        switch error {
        case .unauthenticated:
            self.present(
                authenticationUIService.unauthenticatedAlertController(),
                animated: true
            )
        default:
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }
    }
}

extension FeedCollectionViewController {
    private func openURL(_ url: URL) {
        if let safariViewController = SFSafariViewController.instance(for: url) {
            navigationController?.present(safariViewController, animated: true)
        }
    }

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
