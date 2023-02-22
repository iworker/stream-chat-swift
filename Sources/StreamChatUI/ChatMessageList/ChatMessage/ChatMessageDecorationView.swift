//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A type that describes where a decoration will be placed
public enum ChatMessageDecorationType {
    /// A header decoration is being placed above the
    /// cell's content
    case header

    /// A footer decoration is being placed below the
    /// cell's content
    case footer
}

/// The view that displays any header or footer decorations above & below a
/// ChatMessageCell.
open class ChatMessageDecorationView: _TableViewHeaderFooterReusableView {
    public static var reuseId: String { "\(self)" }

    /// The type this decoration has been used for
    open var decorationType: ChatMessageDecorationType!

    /// The indexPath of the ChatMessageCell that this decoration belongs to.
    open var indexPath: IndexPath!

    /// A convenience method that allows for inline content updates of a decorationView if it
    /// matches the provided type.
    public func updateContentIf<DecorationViewType: ChatMessageDecorationView>(
        typeIs decorationViewType: DecorationViewType.Type,
        configurationBlock: (DecorationViewType) -> Void
    ) -> ChatMessageDecorationView? {
        guard let castedValue = self as? DecorationViewType else {
            return self
        }
        configurationBlock(castedValue)
        return castedValue
    }
}
