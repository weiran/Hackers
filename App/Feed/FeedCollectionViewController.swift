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
        }.done { _ in
            self.update(with: self.viewModel)
        }.catch { _ in

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
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.dataSource = dataSource

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(fetchFeedWithReset),
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl

        collectionView.backgroundView = TableViewBackgroundView.loadingBackgroundView()

        // seems to fix incorrectly sized cells on initial load
        self.collectionView.reloadData()
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<FeedViewModel.Section, Post> {
        let reuseIdentifier = "FeedItemCell"

        let upvoteAction = UIContextualAction(
            style: .normal,
            title: "Upvote",
            handler: { _, _, completion in
                completion(true)
            }
        )
        upvoteAction.image = UIImage(systemName: "chevron.up")

        return UICollectionViewDiffableDataSource(
            collectionView: self.collectionView) { (collectionView, indexPath, post) in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseIdentifier,
                for: indexPath
            ) as? FeedItemCell else { return nil }

            cell.setImageWithPlaceholder(
                url: UserDefaults.standard.showThumbnails ? post.url : nil
            )

            cell.postTitleView.post = post
            cell.linkPressedHandler = { post in
                self.openURL(post.url)
            }

            cell.leadingSwipeActionsConfiguration = UISwipeActionsConfiguration(
                actions: [upvoteAction]
            )

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
