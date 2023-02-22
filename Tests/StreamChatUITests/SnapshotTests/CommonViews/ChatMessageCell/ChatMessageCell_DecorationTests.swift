//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageCell_DecorationTests: XCTestCase {
    private lazy var subject: ChatMessageCell! = .init(style: .default, reuseIdentifier: nil)

    override func setUpWithError() throws {
        try super.setUpWithError()
        subject.setMessageContentIfNeeded(
            contentViewClass: ChatMessageContentView.self,
            attachmentViewInjectorType: nil,
            options: [.bubble]
        )
    }

    override func tearDownWithError() throws {
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - setupLayout

    func test_setupLayout_headerAndFooterContainersHaveBeenAddedInHierarchy() {
        subject.setUpLayout()

        XCTAssertEqual(subject.containerStackView.subviews.count, 3)
    }

    func test_setupLayout_headerAndFooterContainersHaveSameWidthAsTheCell() {
        subject.setUpLayout()

        subject.frame = .init(x: 0, y: 0, width: 100, height: 200)
        subject.setNeedsLayout()
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.headerContainerView.frame.size.width, 100)
        XCTAssertEqual(subject.containerStackView.frame.size.width, 100)
        XCTAssertEqual(subject.footerContainerView.frame.size.width, 100)
    }

    // MARK: - setUpAppearance

    func test_setUpAppearance_configuresHeaderAndFooterContainersCorrectly() {
        subject.headerContainerView.backgroundColor = .red
        subject.footerContainerView.backgroundColor = .red

        subject.setUpAppearance()

        XCTAssertNil(subject.headerContainerView.backgroundColor)
        XCTAssertNil(subject.footerContainerView.backgroundColor)
    }

    // MARK: - prepareForReuse

    func test_prepareForReuse_configuresHeaderAndFooterContainersCorrectly() {
        subject.headerContainerView.addSubview(.init())
        subject.headerContainerView.isHidden = false
        subject.footerContainerView.addSubview(.init())
        subject.footerContainerView.isHidden = false

        subject.prepareForReuse()

        XCTAssertTrue(subject.headerContainerView.subviews.isEmpty)
        XCTAssertTrue(subject.headerContainerView.isHidden)
        XCTAssertTrue(subject.footerContainerView.subviews.isEmpty)
        XCTAssertTrue(subject.footerContainerView.isHidden)
    }

    // MARK: - updateDecoration

    func test_updateDecoration_decorationTypeIsHeaderAndDecorationViewIsNotNil_updatesHeaderContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .header, decorationView: decorationView)

        XCTAssertEqual(subject.headerContainerView.subviews.count, 1)
        XCTAssertEqual(subject.headerContainerView.subviews.first, decorationView)
        XCTAssertFalse(subject.headerContainerView.isHidden)
    }

    func test_updateDecoration_decorationTypeIsHeaderAndDecorationViewIsNotNilAndLaterUpdateWithDecorationViewNil_updatesHeaderContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .header, decorationView: decorationView)
        subject.updateDecoration(for: .header, decorationView: nil)

        XCTAssertTrue(subject.headerContainerView.subviews.isEmpty)
        XCTAssertTrue(subject.headerContainerView.isHidden)
    }

    func test_updateDecoration_decorationTypeIsFooterAndDecorationViewIsNotNil_updatesFooterContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .footer, decorationView: decorationView)

        XCTAssertEqual(subject.footerContainerView.subviews.count, 1)
        XCTAssertEqual(subject.footerContainerView.subviews.first, decorationView)
        XCTAssertFalse(subject.footerContainerView.isHidden)
    }

    func test_updateDecoration_decorationTypeIsFooterAndDecorationViewIsNotNilAndLaterUpdateWithDecorationViewNil_updatesFooterContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .header, decorationView: decorationView)
        subject.updateDecoration(for: .header, decorationView: nil)

        XCTAssertTrue(subject.headerContainerView.subviews.isEmpty)
        XCTAssertTrue(subject.headerContainerView.isHidden)
    }
}
