//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageDecorationView_Tests: XCTestCase {
    // MARK: - updateContentIf

    func test_updateContentIf_decorationViewTypeMatches_configurationBlockWasCalled() {
        let subject = DecorationViewTypeA()
        var configurationBlockWasCalled = false

        _ = subject.updateContentIf(
            typeIs: DecorationViewTypeA.self,
            configurationBlock: { _ in configurationBlockWasCalled = true }
        )

        XCTAssertTrue(configurationBlockWasCalled)
    }

    func test_updateContentIf_decorationViewTypeDoesNotMatch_configurationBlockWasCalled() {
        let subject = DecorationViewTypeA()
        var configurationBlockWasCalled = false

        _ = subject.updateContentIf(
            typeIs: DecorationViewTypeB.self,
            configurationBlock: { _ in configurationBlockWasCalled = true }
        )

        XCTAssertFalse(configurationBlockWasCalled)
    }
}

extension ChatMessageDecorationView_Tests {
    private final class DecorationViewTypeA: ChatMessageDecorationView {}
    private final class DecorationViewTypeB: ChatMessageDecorationView {}
}
