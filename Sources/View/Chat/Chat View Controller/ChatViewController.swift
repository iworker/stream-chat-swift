//
//  ChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

public final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public var style = ChatViewStyle()
    let disposeBag = DisposeBag()
    var reactionsView: ReactionsView?
    private(set) var items = [ChatItem]()
    
    var scrollEnabled: Bool {
        return reactionsView == nil
    }
    
    private(set) lazy var composerView: ComposerView = {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }()
    
    private(set) lazy var composerCommands: ComposerHelperContainerView = {
        let container = ComposerHelperContainerView()
        container.backgroundColor = style.incomingMessage.chatBackgroundColor.isDark ? .chatDarkGray : .white
        container.titleLabel.text = "Commands"
        container.add(for: composerView)
        container.isHidden = true
        container.closeButton.isHidden = true
        
        if let channelConfig = channelPresenter?.channel.config {
            channelConfig.commands.forEach { command in
                let view = ComposerCommandView(frame: .zero)
                view.backgroundColor = container.backgroundColor
                view.update(command: command.name, args: command.args, description: command.description)
                container.containerView.addArrangedSubview(view)
                
                view.rx.tapGesture().when(.recognized)
                    .subscribe(onNext: { [weak self] _ in self?.addCommandToComposer(command: command.name) })
                    .disposed(by: self.disposeBag)
            }
        }
        
        return container
    }()
    
    private(set) lazy var editComposer: ComposerHelperContainerView = {
        let container = ComposerHelperContainerView()
        container.backgroundColor = style.incomingMessage.chatBackgroundColor.isDark ? .chatDarkGray : .white
        container.titleLabel.text = "Edit message"
        container.add(for: composerView)
        container.isHidden = true
        
        container.closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                if let self = self {
                    self.channelPresenter?.editMessage = nil
                    self.composerView.textView.text = ""
                    self.editComposer.animate(show: false)
                    
                    if self.composerView.textView.isFirstResponder {
                        self.composerView.textView.resignFirstResponder()
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return container
    }()
    
    private(set) lazy var tableView: TableView = {
        let tableView = TableView(frame: .zero, style: .plain)
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerMessageCell(style: style.incomingMessage)
        tableView.registerMessageCell(style: style.outgoingMessage)
        tableView.register(cellType: StatusTableViewCell.self)
        
        tableView.contentInset = UIEdgeInsets(top: 2 * .messageEdgePadding,
                                              left: 0,
                                              bottom: .messagesToComposerPadding,
                                              right: 0)
        
        view.insertSubview(tableView, at: 0)
        
        let footerView = ChatFooterView(frame: CGRect(x: 0, y: 0, width: 0, height: .chatFooterHeight))
        footerView.backgroundColor = style.incomingMessage.chatBackgroundColor
        tableView.tableFooterView = footerView
        
        return tableView
    }()
    
    public var channelPresenter: ChannelPresenter? {
        didSet {
            if let presenter = channelPresenter {
                Driver.merge((presenter.parentMessage == nil ? presenter.channelRequest : presenter.replyRequest),
                             presenter.changes,
                             presenter.ephemeralChanges)
                    .do(onNext: { [weak presenter] _ in presenter?.sendRead() })
                    .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
                    .disposed(by: disposeBag)
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupComposerView()
        setupTableView()
        updateTitle()
        
        guard let presenter = channelPresenter else {
            return
        }
        
        if presenter.isEmpty {
            channelPresenter?.load()
        } else {
            items = presenter.items
            tableView.reloadData()
            tableView.scrollToBottom(animated: false)
            DispatchQueue.main.async { self.tableView.scrollToBottom(animated: false) }
            presenter.sendRead()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startGifsAnimations()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGifsAnimations()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return style.incomingMessage.chatBackgroundColor.isDark ? .lightContent : .default
    }
    
    private func updateTitle() {
        guard title == nil, navigationItem.rightBarButtonItem == nil else {
            return
        }
        
        title = channelPresenter?.channel.name
        
        let channelAvatar = AvatarView(cornerRadius: .messageAvatarRadius)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatar)
        
        channelAvatar.update(with: channelPresenter?.channel.imageURL,
                             name: channelPresenter?.channel.name,
                             baseColor: style.incomingMessage.chatBackgroundColor)
    }
}

// MARK: - Table View

extension ChatViewController {
    
    private func setupTableView() {
        tableView.backgroundColor = style.incomingMessage.chatBackgroundColor
        tableView.makeEdgesEqualToSuperview()
    }
    
    private func updateTableView(with changes: ViewChanges) {
        guard isViewLoaded else {
            return
        }
        
        switch changes {
        case .none, .itemMoved:
            return
        case let .reloaded(row, items):
            self.items = items
            let isLastRow = row == (items.count - 1)
            let needsToScroll = isLastRow || isLoadingCellPresented()
            tableView.reloadData()
            
            if scrollEnabled, needsToScroll {
                tableView.scrollToRow(at: .row(row), at: .top, animated: false)
            }

        case let .itemAdded(row, reloadRow, forceToScroll, items):
            self.items = items
            let indexPath = IndexPath.row(row)
            let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
            tableView.stayOnScrollOnce = scrollEnabled && (forceToScroll || needsToScroll)
            
            tableView.performBatchUpdates({
                tableView.insertRows(at: [indexPath], with: .none)

                if let reloadRow = reloadRow {
                    tableView.reloadRows(at: [.row(reloadRow)], with: .none)
                }
            })
        case let .itemUpdated(row, message, items):
            self.items = items
            tableView.reloadRows(at: [.row(row)], with: .none)
            
            if let reactionsView = reactionsView {
                reactionsView.update(with: message)
            }
        case let .itemRemoved(row, items):
            self.items = items
            tableView.deleteRows(at: [.row(row)], with: .none)
        case let .footerUpdated(isUsersTyping):
            updateFooterView(isUsersTyping)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            return .unused
        }
        
        let backgroundColor = style.incomingMessage.chatBackgroundColor
        
        switch items[indexPath.row] {
        case .loading:
            channelPresenter?.loadNext()
            return tableView.loadingCell(at: indexPath, backgroundColor: backgroundColor)
            
        case let .status(title, subtitle, highlighted):
            return tableView.statusCell(at: indexPath,
                                        title: title,
                                        subtitle: subtitle,
                                        backgroundColor: backgroundColor,
                                        highlighted: highlighted)
        case .message(let message):
            return messageCell(at: indexPath, message: message)
        default:
            return .unused
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count else {
            return
        }
        
        let item = items[indexPath.row]
        
        if case .message(let message) = item {
            willDisplay(cell: cell, at: indexPath, message: message)
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageTableViewCell {
            cell.free()
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    private func isLoadingCellPresented() -> Bool {
        return nil != tableView.visibleCells.first(where: { cell -> Bool in
            if let cell = cell as? StatusTableViewCell,
                let title = cell.title,
                title.lowercased() == UITableView.loadingTitle.lowercased() {
                return true
            }
            
            return false
        })
    }
}
