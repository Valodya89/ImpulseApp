//
//  MiAlertView.swift
//  Impuls
//
//  Compatibility shim over the Mimo alert card. The SCL-derived popup that used
//  to live here (coloured circle, bounce animation, integer colours) is gone;
//  `MiAlertView().showError(...)` / `showSuccess(...)` and the other `show*`
//  entry points keep their signatures and now present `MimoAlertCardView`
//  through `MimoAlertController`, so the call sites did not change.
//

import UIKit

// Pop Up Styles
public enum SCLAlertViewStyle {
    case success, error, notice, warning, info, edit, wait, question

    public var defaultColorInt: UInt {
        switch self {
        case .success: return 0x22B573
        case .error: return 0xC1272D
        case .notice: return 0x727375
        case .warning: return 0xFFD110
        case .info: return 0xFFD110
        case .edit: return 0xA429FF
        case .wait: return 0xD62DA5
        case .question: return 0x727375
        }
    }

    /// The card kind this legacy style maps to.
    var alertKind: MimoAlertContent.Kind {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .important
        case .notice, .info, .edit, .wait, .question: return .info
        }
    }
}

// Animation Styles (accepted for source compatibility; the card cross-dissolves).
public enum SCLAnimationStyle {
    case noAnimation, topToBottom, bottomToTop, leftToRight, rightToLeft
}

// Action Types
public enum SCLActionType {
    case none, selector, closure
}

public enum SCLAlertButtonLayout {
    case horizontal, vertical
}

// Button sub-class, kept because `addButton` still returns one.
open class SCLButton: UIButton {
    var actionType = SCLActionType.none
    var target: AnyObject!
    var selector: Selector!
    var action: (() -> Void)!
    var customBackgroundColor: UIColor?
    var customTextColor: UIColor?
    var initialTitle: String!
    var showTimeout: ShowTimeoutConfiguration?

    public struct ShowTimeoutConfiguration {
        let prefix: String
        let suffix: String

        public init(prefix: String = "", suffix: String = "") {
            self.prefix = prefix
            self.suffix = suffix
        }
    }

    public init() {
        super.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
}

// Allow alerts to be closed/renamed in a chainable manner
open class SCLAlertViewResponder {
    let alertview: MiAlertView

    public init(alertview: MiAlertView) {
        self.alertview = alertview
    }

    /// Titles cannot change once the card is on screen; kept as no-ops.
    open func setTitle(_ title: String) {}

    open func setSubTitle(_ subTitle: String?) {}

    open func close() {
        alertview.hideView()
    }

    open func setDismissBlock(_ dismissBlock: @escaping DismissBlock) {
        alertview.dismissBlock = dismissBlock
    }
}

public typealias DismissBlock = () -> Void

// The alert. Buttons are collected with `addButton`, then one of the `show*`
// methods presents the card with them (plus the close button, if any).
open class MiAlertView {

    public struct SCLAppearance {
        /// Whether a tap on the scrim closes the card.
        public var hideWhenBackgroundViewIsTapped: Bool = false
        /// Whether a card with a timeout also gets a close button.
        public var showCloseButton: Bool = false

        public init(hideWhenBackgroundViewIsTapped: Bool = false, showCloseButton: Bool = false) {
            self.hideWhenBackgroundViewIsTapped = hideWhenBackgroundViewIsTapped
            self.showCloseButton = showCloseButton
        }
    }

    public struct SCLTimeoutConfiguration {
        public typealias ActionType = () -> Void

        var value: TimeInterval
        let action: ActionType

        public init(timeoutValue: TimeInterval, timeoutAction: @escaping ActionType) {
            self.value = timeoutValue
            self.action = timeoutAction
        }
    }

    var appearance: SCLAppearance
    open var dismissBlock: DismissBlock?

    private var actions: [MimoAlertAction] = []
    private var buttons: [SCLButton] = []
    private weak var controller: MimoAlertController?
    private var showing = false

    public init(appearance: SCLAppearance) {
        self.appearance = appearance
    }

    public init() {
        self.appearance = SCLAppearance()
    }

    // MARK: - Buttons

    @discardableResult
    open func addButton(_ title: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil, showTimeout: SCLButton.ShowTimeoutConfiguration? = nil, action: @escaping () -> Void) -> SCLButton {
        let button = makeButton(title, backgroundColor: backgroundColor, textColor: textColor, showTimeout: showTimeout)
        button.actionType = .closure
        button.action = action
        actions.append(MimoAlertAction(title: title, tone: tone(for: backgroundColor, textColor: textColor), handler: action))
        return button
    }

    @discardableResult
    open func addButton(_ title: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil, showTimeout: SCLButton.ShowTimeoutConfiguration? = nil, target: AnyObject, selector: Selector) -> SCLButton {
        let button = makeButton(title, backgroundColor: backgroundColor, textColor: textColor, showTimeout: showTimeout)
        button.actionType = .selector
        button.target = target
        button.selector = selector
        actions.append(MimoAlertAction(title: title, tone: tone(for: backgroundColor, textColor: textColor)) {
            _ = target.perform(selector)
        })
        return button
    }

    private func makeButton(_ title: String, backgroundColor: UIColor?, textColor: UIColor?, showTimeout: SCLButton.ShowTimeoutConfiguration?) -> SCLButton {
        let button = SCLButton()
        button.setTitle(title, for: .normal)
        button.initialTitle = title
        button.customBackgroundColor = backgroundColor
        button.customTextColor = textColor
        button.showTimeout = showTimeout
        buttons.append(button)
        return button
    }

    /// The first added button is the affirmative one; a red custom colour
    /// marks a destructive choice; everything after the first stays quiet.
    private func tone(for backgroundColor: UIColor?, textColor: UIColor?) -> MimoAlertAction.Tone {
        if let backgroundColor, backgroundColor.isReddish { return .destructive }
        return actions.isEmpty ? .primary : .secondary
    }

    // MARK: - Show

    @discardableResult
    open func showCustom(_ title: String, subTitle: String? = nil, color: UIColor, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .info, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showSuccess(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt = SCLAlertViewStyle.success.defaultColorInt, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .success, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showError(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt = SCLAlertViewStyle.error.defaultColorInt, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .error, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showNotice(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt = SCLAlertViewStyle.notice.defaultColorInt, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .info, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showWarning(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt = SCLAlertViewStyle.warning.defaultColorInt, colorTextButton: UInt = 0x000000, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .important, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showInfo(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, showCloseButton: Bool = false, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt = SCLAlertViewStyle.info.defaultColorInt, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .info, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showWait(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt? = SCLAlertViewStyle.wait.defaultColorInt, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .info, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showEdit(_ title: String, subTitle: String? = nil, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt = SCLAlertViewStyle.edit.defaultColorInt, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: .info, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showTitle(_ title: String, subTitle: String? = nil, style: SCLAlertViewStyle, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, colorStyle: UInt? = 0x000000, colorTextButton: UInt = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: style.alertKind, title: title, subTitle: subTitle, closeButtonTitle: closeButtonTitle, timeout: timeout)
    }

    @discardableResult
    open func showTitle(_ title: String, subTitle: String? = nil, timeout: SCLTimeoutConfiguration?, completeText: String?, showCloseButton: Bool = false, style: SCLAlertViewStyle, colorStyle: UInt? = 0x000000, colorTextButton: UInt? = 0xFFFFFF, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        present(kind: style.alertKind, title: title, subTitle: subTitle, closeButtonTitle: completeText, timeout: timeout)
    }

    /// Builds the card: the added buttons, then the close button (yellow when
    /// it is the only one, hairline under other choices). A card with nothing
    /// to tap still gets OK, so it can always be closed.
    private func present(kind: MimoAlertContent.Kind, title: String, subTitle: String?, closeButtonTitle: String?, timeout: SCLTimeoutConfiguration?) -> SCLAlertViewResponder {
        var all = actions
        if let closeButtonTitle, !closeButtonTitle.isEmpty {
            all.append(MimoAlertAction(title: closeButtonTitle, tone: all.isEmpty ? .primary : .secondary))
        }
        if all.isEmpty && timeout == nil {
            all = [.ok()]
        }

        var content = MimoAlertContent(kind: kind, title: title, message: subTitle, actions: all, autoDismiss: timeout?.value)
        if appearance.hideWhenBackgroundViewIsTapped {
            content.dismissesOnScrimTap = true
        }

        // The timeout action, like SCL's, runs when the card leaves on its own.
        var timedOut = true
        content.actions = content.actions.map { action in
            MimoAlertAction(title: action.title, tone: action.tone) {
                timedOut = false
                action.handler()
            }
        }

        showing = true
        let alert = MimoAlertController(content: content) { [self] in
            self.showing = false
            if timedOut, let timeout { timeout.action() }
            self.dismissBlock?()
        }
        controller = alert
        MimoAlertController.show(alert)

        return SCLAlertViewResponder(alertview: self)
    }

    // MARK: - Hide

    @objc open func hideView() {
        controller?.finish(with: nil)
    }

    open func isShowing() -> Bool {
        showing
    }
}

private extension UIColor {
    /// Red enough to mean "destructive" when a caller colours a button itself.
    var isReddish: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard resolvedColor(with: UITraitCollection.current).getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        return r > 0.6 && g < 0.4 && b < 0.4
    }
}

public func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
    UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}
