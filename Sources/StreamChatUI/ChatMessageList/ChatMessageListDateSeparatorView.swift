//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The date separator view that groups messages from the same day.
open class ChatMessageListDateSeparatorView: ChatMessageDecorationView, AppearanceProvider {
    /// The date in string format.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    /// The container that the contentTextLabel will be placed aligned to its centre.
    open private(set) lazy var container: UIView = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "dateSeparatorContainer")

    /// The text label that renders the date string.
    open private(set) lazy var contentTextLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "textLabel")

    override open func setUpLayout() {
        super.setUpLayout()

        addSubview(container)

        container.embed(contentTextLabel, insets: .init(top: 3, leading: 9, bottom: 3, trailing: 9))

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.background7

        contentTextLabel.font = appearance.fonts.footnote
        contentTextLabel.textColor = appearance.colorPalette.staticColorText
    }

    override open func updateContent() {
        super.updateContent()

        contentTextLabel.text = content
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        container.layer.cornerRadius = bounds.height / 2
    }
}
