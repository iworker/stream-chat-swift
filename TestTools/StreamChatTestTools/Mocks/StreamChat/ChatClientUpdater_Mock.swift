//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

/// Mock implementation of `ChatClientUpdater`
final class ChatClientUpdater_Mock: ChatClientUpdater {
    @Atomic var prepareEnvironment_newToken: Token?
    var prepareEnvironment_called: Bool { prepareEnvironment_newToken != nil }

    @Atomic var reloadUserIfNeeded_called = false {
        didSet {
            reloadUserIfNeeded_callsCount += 1
        }
    }

    var reloadUserIfNeeded_callsCount = 0
    @Atomic var reloadUserIfNeeded_completion: ((Error?) -> Void)?
    @Atomic var reloadUserIfNeeded_callSuper: (() -> Void)?
    @Atomic var reloadUserIfNeeded_userConnectionProvider: UserConnectionProvider?

    @Atomic var connect_called = false
    @Atomic var connect_completion: ((Error?) -> Void)?

    var disconnect_called: Bool { disconnect_source != nil }
    @Atomic var disconnect_source: WebSocketConnectionState.DisconnectionSource?
    @Atomic var disconnect_completion: (() -> Void)?

    // MARK: - Overrides

    override func prepareEnvironment(
        userInfo: UserInfo?,
        newToken: Token,
        completion: ((Error?) -> Void)? = nil
    ) {
        prepareEnvironment_newToken = newToken
    }

    override func reloadUserIfNeeded(
        userInfo: UserInfo,
        userConnectionProvider: UserConnectionProvider,
        completion: ((Error?) -> Void)?
    ) {
        reloadUserIfNeeded_called = true
        reloadUserIfNeeded_completion = completion
        reloadUserIfNeeded_userConnectionProvider = userConnectionProvider
        reloadUserIfNeeded_callSuper = {
            super.reloadUserIfNeeded(
                userInfo: userInfo,
                userConnectionProvider: userConnectionProvider,
                completion: completion
            )
        }
    }

    override func connect(completion: ((Error?) -> Void)? = nil) {
        connect_called = true
        connect_completion = completion
    }
    
    override func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        disconnect_source = source
        disconnect_completion = completion
    }

    // MARK: - Clean Up

    func cleanUp() {
        prepareEnvironment_newToken = nil

        reloadUserIfNeeded_called = false
        reloadUserIfNeeded_callsCount = 0
        reloadUserIfNeeded_completion = nil
        reloadUserIfNeeded_callSuper = nil

        connect_called = false
        connect_completion = nil

        disconnect_source = nil
        disconnect_completion = nil
    }
}
