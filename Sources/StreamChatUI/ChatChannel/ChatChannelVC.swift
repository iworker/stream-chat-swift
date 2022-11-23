//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying the channel messages.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelVC: _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController!

    /// User search controller for suggestion users when typing in the composer.
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

    /// The size of the channel avatar.
    open var channelAvatarSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    public var client: ChatClient {
        channelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = components
        .messageListVC
        .init()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    /// Header View
    open private(set) lazy var headerView: ChatChannelHeaderView = components
        .channelHeaderView.init()
        .withoutAutoresizingMaskConstraints

    /// View for displaying the channel image in the navigation bar.
    open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The message composer bottom constraint used for keyboard animation handling.
    public var messageComposerBottomConstraint: NSLayoutConstraint?

    /// A boolean value indicating wether the last message is fully visible or not.
    open var isLastMessageFullyVisible: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    /// A boolean value indicating wether it should mark the channel read.
    open var shouldMarkChannelRead: Bool {
        isLastMessageFullyVisible && channelController.hasLoadedAllNextMessages
    }

    /// Wether the channel is currently jumping to a message which is not loaded yet.
    public var isJumpingToMessage = false

    /// A message that is pending to be scrolled after the UI update.
    ///
    /// Ex: When jumping to a message, we want that message to appear in the UI, and only then scroll to it.
    private var messagePendingScrolling: ChatMessage?

    /// Weather the channel is currently loading previous (old) messages.
    private var isLoadingPreviousMessages: Bool = false

    /// Weather the channel is currently loading next (new) messages.
    private var isLoadingNextMessages: Bool = false

    override open func setUp() {
        super.setUp()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client

        messageComposerVC.userSearchController = userSuggestionSearchController

        setChannelControllerToComposerIfNeeded(cid: channelController.cid)

        channelController.delegate = self
        channelController.synchronize { [weak self] error in
            if let error = error {
                log.error("Error when synchronizing ChannelController: \(error)")
            }
            self?.setChannelControllerToComposerIfNeeded(cid: self?.channelController.cid)
            self?.messageComposerVC.updateContent()
        }

        // Initial messages data
        messages = Array(channelController.messages)
    }

    private func setChannelControllerToComposerIfNeeded(cid: ChannelId?) {
        guard messageComposerVC.channelController == nil, let cid = cid else { return }
        messageComposerVC.channelController = client.channelController(for: cid)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        addChildViewController(messageListVC, targetView: view)
        messageListVC.view.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)

        addChildViewController(messageComposerVC, targetView: view)
        messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
        messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.pin(equalToConstant: channelAvatarSize.width),
            channelAvatarView.heightAnchor.pin(equalToConstant: channelAvatarSize.height)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
        channelAvatarView.content = (channelController.channel, client.currentUserId)

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }

        navigationItem.titleView = headerView
        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()

        if shouldMarkChannelRead {
            channelController.markRead()
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        keyboardHandler.stop()

        resignFirstResponder()
    }

    /// Jump to a given message.
    /// In case the message is already loaded, it directly goes to it.
    /// If not, it will load the messages around it and go to that page.
    ///
    /// - Parameter message: The message which the message list should go to.
    open func jumpToMessage(_ message: ChatMessage) {
        if let indexPath = messageListVC.getIndexPath(forMessageId: message.id) {
            messageListVC.listView.scrollToRow(at: indexPath, at: .middle, animated: true)
            return
        }

        isJumpingToMessage = true
        messageListVC.listView.isFirstPageLoaded = false
        channelController.loadPageAroundMessageId(message.id) { [weak self] error in
            self?.isJumpingToMessage = false
            if let error = error {
                self?.loadingMessagesAroundFailed(withError: error)
                return
            }

            self?.messageListVC.listView.isFirstPageLoaded = self?.channelController.hasLoadedAllNextMessages ?? false
            self?.messagePendingScrolling = message
        }
    }

    open func loadingMessagesAroundFailed(withError error: Error) {
        log.error("Loading message around failed with error: \(error)")
    }

    // MARK: - ChatMessageListVCDataSource

    public var messages: [ChatMessage] = []

    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        messages.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        messages[safe: indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(messages),
            appearance: appearance
        )
    }

    open func chatMessageListVCShouldJumpToFirstPage(
        _ vc: ChatMessageListVC
    ) {
        isJumpingToMessage = true
        channelController.loadFirstPage { [weak self] _ in
            self?.isJumpingToMessage = false
        }
    }

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        // no-op
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.editMessage(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC.showThread(messageId: message.id)
            }
        default:
            return
        }
    }

    private var previousPosition: CGFloat = 0.0

    open func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {
        if shouldMarkChannelRead {
            channelController.markRead()

            messageListVC.scrollToLatestMessageButton.content = .noUnread
        }

        // JUMPTODO: This should be reusable

        guard scrollView.isTrackingOrDecelerating else {
            return
        }

        let position = scrollView.contentOffset.y
        if position > scrollView.contentSize.height - 250 - scrollView.frame.size.height {
            guard !isLoadingPreviousMessages else {
                return
            }
            isLoadingPreviousMessages = true

            channelController.loadPreviousMessages { [weak self] _ in
                self?.isLoadingPreviousMessages = false
            }
        }

        if position >= 0 && position < 250 && position < previousPosition {
            guard !isLoadingNextMessages else {
                return
            }

            isLoadingNextMessages = true
            messageListVC.listView.isFirstPageLoaded = false

            channelController.loadNextMessages { [weak self] _ in
                self?.messageListVC.listView.isFirstPageLoaded = self?.channelController.hasLoadedAllNextMessages ?? false
                self?.isLoadingNextMessages = false
            }
        }

        previousPosition = position
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    ) {
        messageComposerVC.dismissSuggestions()
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnQuotedMessage quotedMessage: ChatMessage) {
        jumpToMessage(quotedMessage)
    }

    // MARK: - ChatChannelControllerDelegate

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        if shouldMarkChannelRead {
            channelController.markRead()
        }

        // JUMPTODO: Extract this to open var, so that it can be overridable
        if isJumpingToMessage && changes.filter(\.isRemove).count == messages.count {
            return
        }

        messageListVC.setPreviousMessagesSnapshot(messages)
        messageListVC.setNewMessagesSnapshot(Array(channelController.messages))

        // JUMPTODO: This should be reusable
        let oldContentOffset = messageListVC.listView.contentOffset
        let oldContentSize = messageListVC.listView.contentSize
        let pageSize = channelController.channelQuery.pagination?.pageSize ?? .channelsPageSize
        let isNewPageInsertedAtTheBottom = changes.map(\.isInsertion).count == pageSize && changes.first(where: {
            $0.indexPath.item - messageListVC.listView.skippedMessages.count == 0
        }) != nil
        messageListVC.updateMessages(with: changes) { [weak self] in
            // Only after updating the message to the UI we have the message around loaded
            // So we check if we have a message waiting to be scrolled to here
            if let message = self?.messagePendingScrolling,
               let indexPath = self?.messageListVC.getIndexPath(forMessageId: message.id) {
                self?.messageListVC.listView.scrollToRow(at: indexPath, at: .middle, animated: true)
                self?.messagePendingScrolling = nil
            }

            // Calculate new content offset after loading next page
            if !channelController.hasLoadedAllNextMessages && isNewPageInsertedAtTheBottom {
                let newContentSize = self?.messageListVC.listView.contentSize ?? .zero
                let newOffset = oldContentOffset.y + (newContentSize.height - oldContentSize.height)
                self?.messageListVC.listView.contentOffset.y = newOffset
            }
        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        let channelUnreadCount = channelController.channel?.unreadCount ?? .noUnread
        messageListVC.scrollToLatestMessageButton.content = channelUnreadCount
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        guard channelController.areTypingEventsEnabled else { return }

        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != self.client.currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            messageListVC.hideTypingIndicator()
        } else {
            messageListVC.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }

    // When app becomes active, and channel is open, recreate the database observers and reload
    // the data source so that any missed database updates from the NotificationService are refreshed.
    @objc func appMovedToForeground() {
        channelController.delegate = self
        messageListVC.dataSource = self
    }
}
