//
//  MimoAlert.swift
//  Impuls
//
//  The app's one alert: a centred card on a dimmed scrim with a tinted icon
//  well, a Roboto title, an optional message and stacked pill buttons (yellow
//  affirmative on top, hairline secondary, red destructive). It replaces the
//  system `UIAlertController`, the SCL-derived `MiAlertView` and the
//  auto-dismissing "important" xib, so every popup reads the same in light and
//  dark. UIKit shows it through `MimoAlertController` (also from a manager
//  without a view controller); SwiftUI through `.mimoAlert(isPresented:)` /
//  `.mimoAlert(item:)`.
//

import SwiftUI
import UIKit

// MARK: - Model

struct MimoAlertAction: Identifiable {

    enum Tone {
        /// The one yellow button.
        case primary
        /// Hairline pill: cancel, "not now", the second of two choices.
        case secondary
        /// Red fill for the action a rider cannot take back.
        case destructive
    }

    let id = UUID()
    let title: String
    let tone: Tone
    let handler: () -> Void

    init(title: String, tone: Tone = .primary, handler: @escaping () -> Void = {}) {
        self.title = title
        self.tone = tone
        self.handler = handler
    }

    static func ok(_ handler: @escaping () -> Void = {}) -> MimoAlertAction {
        MimoAlertAction(title: "MOBILE_global_ok".localized(fallback: "OK"), tone: .primary, handler: handler)
    }

    static func cancel(_ title: String? = nil, _ handler: @escaping () -> Void = {}) -> MimoAlertAction {
        MimoAlertAction(title: title ?? "MOBILE_global_cancel".localized(fallback: "Cancel"), tone: .secondary, handler: handler)
    }
}

struct MimoAlertContent {

    enum Kind {
        case info
        case success
        case error
        /// Something the rider must notice but that is not a failure (amber well).
        case important
    }

    var kind: Kind = .info
    var title: String
    var message: String? = nil
    var actions: [MimoAlertAction] = []
    /// Seconds after which the card leaves on its own. `nil` keeps it until a
    /// button or the scrim is tapped.
    var autoDismiss: TimeInterval? = nil
    /// Whether a tap outside the card closes it. Defaults to yes only when the
    /// card has no buttons - a choice should be made, not swiped away.
    var dismissesOnScrimTap: Bool? = nil

    var closesOnScrimTap: Bool {
        dismissesOnScrimTap ?? (actions.isEmpty || autoDismiss != nil)
    }

    /// Buttons in display order: the primary or destructive choice on top,
    /// the quiet ones under it, whatever order the caller listed them in.
    var orderedActions: [MimoAlertAction] {
        actions.filter { $0.tone != .secondary } + actions.filter { $0.tone == .secondary }
    }

    // MARK: Presets

    static func info(_ title: String, message: String? = nil, actions: [MimoAlertAction] = [.ok()]) -> MimoAlertContent {
        MimoAlertContent(kind: .info, title: title, message: message, actions: actions)
    }

    static func error(_ message: String, title: String? = nil, actions: [MimoAlertAction] = [.ok()]) -> MimoAlertContent {
        MimoAlertContent(kind: .error,
                         title: title ?? "MOBILE__global_attention".localized(fallback: "Attention"),
                         message: message,
                         actions: actions)
    }

    static func success(_ title: String, message: String? = nil, actions: [MimoAlertAction] = [.ok()]) -> MimoAlertContent {
        MimoAlertContent(kind: .success, title: title, message: message, actions: actions)
    }

    static func important(_ title: String, message: String? = nil, actions: [MimoAlertAction] = [.ok()]) -> MimoAlertContent {
        MimoAlertContent(kind: .important, title: title, message: message, actions: actions)
    }

    /// Alias kept for parity with the other apps' `warning` preset.
    static func warning(_ title: String, message: String? = nil, actions: [MimoAlertAction] = [.ok()]) -> MimoAlertContent {
        important(title, message: message, actions: actions)
    }
}

// MARK: - Button style

/// The alert's pill: 48 pt capsule, Roboto bold 15, brand yellow for the
/// affirmative choice, a hairline for the quiet one, red for the destructive.
struct MimoAlertButtonStyle: ButtonStyle {

    var tone: MimoAlertAction.Tone = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.robotoBold15)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(foreground)
            .background(Capsule().fill(background))
            .overlay(Capsule().stroke(tone == .secondary ? Color.appSeparator : Color.clear, lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var background: Color {
        switch tone {
        case .primary: return .brandYellow
        case .secondary: return .appBackground
        case .destructive: return .errorRed
        }
    }

    private var foreground: Color {
        switch tone {
        case .primary: return .onBrandLabel
        case .secondary: return .appLabel
        case .destructive: return .alwaysWhite
        }
    }
}

// MARK: - Card

struct MimoAlertCardView: View {

    let content: MimoAlertContent
    /// Called with the tapped action, or `nil` for a scrim tap / auto-dismiss.
    let onFinish: (MimoAlertAction?) -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.alwaysBlack.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if content.closesOnScrimTap { onFinish(nil) }
                }

            card
                .padding(.horizontal, 32)
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.22)) { appeared = true }

            if let delay = content.autoDismiss {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { onFinish(nil) }
            }
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            icon

            Text(content.title)
                .font(.robotoBold20)
                .foregroundColor(.appLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let message = content.message, !message.isEmpty {
                Text(message)
                    .font(.robotoRegular15)
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !content.actions.isEmpty {
                VStack(spacing: 10) {
                    ForEach(content.orderedActions) { action in
                        Button(action: { onFinish(action) }) {
                            Text(action.title)
                        }
                        .buttonStyle(MimoAlertButtonStyle(tone: action.tone))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .mimoCard(radius: 20)
    }

    /// Tinted well by kind: yellow info, green success, red error, amber important.
    private var icon: some View {
        Image(systemName: symbol)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(iconForeground)
            .frame(width: 56, height: 56)
            .background(Circle().fill(iconBackground))
    }

    private var symbol: String {
        switch content.kind {
        case .info: return "info"
        case .success: return "checkmark"
        case .error: return "exclamationmark"
        case .important: return "exclamationmark.triangle.fill"
        }
    }

    private var iconForeground: Color {
        switch content.kind {
        case .info: return .onBrandLabel
        case .success: return .successGreen
        case .error: return .errorRed
        case .important: return .warningColor
        }
    }

    private var iconBackground: Color {
        switch content.kind {
        case .info: return .brandYellow
        case .success: return .greenTint
        case .error: return .redTint
        case .important: return .amberTint
        }
    }
}

// MARK: - UIKit presentation

/// Over-full-screen controller with a clear background that hosts the card
/// and its scrim, cross-dissolved in and out. `show(_:)` puts it on whatever
/// is on top, so a manager without a view controller can still raise one.
final class MimoAlertController: UIViewController {

    private let content: MimoAlertContent
    private let onDismissed: (() -> Void)?
    private var finished = false

    init(content: MimoAlertContent, onDismissed: (() -> Void)? = nil) {
        self.content = content
        self.onDismissed = onDismissed
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let host = UIHostingController(
            rootView: MimoAlertCardView(content: content) { [weak self] action in
                self?.finish(with: action)
            }
        )
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        view.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        host.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        switch content.kind {
        case .error: MimoFeedback.shared.error()
        case .success: MimoFeedback.shared.success()
        case .info, .important: break
        }
    }

    /// Closes the card once, then runs the tapped action (after the dismissal
    /// so a handler that presents something else is not blocked by this one).
    func finish(with action: MimoAlertAction?, runHandler: Bool = true) {
        guard !finished else { return }
        finished = true

        let handler = runHandler ? action?.handler : nil
        let onDismissed = onDismissed

        if presentingViewController != nil {
            dismiss(animated: true) {
                handler?()
                onDismissed?()
            }
        } else {
            handler?()
            onDismissed?()
        }
    }

    // MARK: Presenting

    /// Presents on `presenter`, or on whatever controller is currently on top.
    /// Always hops to the main thread: error paths reach here from network
    /// callbacks.
    static func show(_ alert: MimoAlertController, on presenter: UIViewController? = nil) {
        DispatchQueue.main.async {
            guard let target = presenter.flatMap(topMost) ?? UIApplication.topController() else { return }
            target.present(alert, animated: true)
        }
    }

    @discardableResult
    static func present(_ content: MimoAlertContent, on presenter: UIViewController? = nil) -> MimoAlertController {
        let alert = MimoAlertController(content: content)
        show(alert, on: presenter)
        return alert
    }

    /// `present` from a controller that already presents something is refused
    /// by UIKit; walk up to the one actually on screen.
    private static func topMost(_ controller: UIViewController) -> UIViewController {
        var top = controller
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}

/// Imperative entry point for code that has no view controller at hand
/// (network layer, managers): `MimoAlert.show(.error("..."))`.
enum MimoAlert {

    @discardableResult
    static func show(_ content: MimoAlertContent, on presenter: UIViewController? = nil) -> MimoAlertController {
        MimoAlertController.present(content, on: presenter)
    }
}

// MARK: - SwiftUI presentation

/// Presents the Mimo alert over the whole window while `isPresented` is true.
/// The binding flips back to false when a button, the scrim or the timer
/// closes the card, so it behaves like `.alert(isPresented:)`.
struct MimoAlertModifier: ViewModifier {

    @Binding var isPresented: Bool
    let makeContent: () -> MimoAlertContent

    @State private var controller: MimoAlertController?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { show in
                if show {
                    present()
                } else {
                    controller?.finish(with: nil, runHandler: false)
                    controller = nil
                }
            }
            .onAppear {
                // `onChange` misses a binding that is already true on first paint.
                if isPresented { present() }
            }
    }

    private func present() {
        guard controller == nil else { return }

        let alert = MimoAlertController(content: makeContent()) {
            controller = nil
            if isPresented { isPresented = false }
        }
        controller = alert
        MimoAlertController.show(alert)
    }
}

extension View {
    func mimoAlert(isPresented: Binding<Bool>, content: @escaping () -> MimoAlertContent) -> some View {
        modifier(MimoAlertModifier(isPresented: isPresented, makeContent: content))
    }
}

/// Item-driven variant, the counterpart of `.alert(item:)`: the card shows
/// while `item` is non-nil and the binding clears when it closes.
struct MimoAlertItemModifier<Item: Identifiable>: ViewModifier {

    @Binding var item: Item?
    let makeContent: (Item) -> MimoAlertContent

    @State private var controller: MimoAlertController?
    @State private var shownID: Item.ID?

    func body(content: Content) -> some View {
        content
            .onChange(of: item?.id) { id in
                if let id, id != shownID, let item {
                    present(item)
                } else if id == nil {
                    controller?.finish(with: nil, runHandler: false)
                    controller = nil
                    shownID = nil
                }
            }
            .onAppear {
                if let item, controller == nil { present(item) }
            }
    }

    private func present(_ item: Item) {
        controller?.finish(with: nil, runHandler: false)
        shownID = item.id

        let alert = MimoAlertController(content: makeContent(item)) {
            controller = nil
            shownID = nil
            if self.item != nil { self.item = nil }
        }
        controller = alert
        MimoAlertController.show(alert)
    }
}

extension View {
    func mimoAlert<Item: Identifiable>(item: Binding<Item?>, content: @escaping (Item) -> MimoAlertContent) -> some View {
        modifier(MimoAlertItemModifier(item: item, makeContent: content))
    }
}

// MARK: - Legacy "important" card

/// Kept for the call sites that raise the auto-dismissing card
/// (`showMimoAlert(.important(...))`); the card is now `MimoAlertCardView`.
enum AlertType {
    case errorNotification(message: String)
    case important(isSuccess: Bool, title: String? = nil, message: String, action: (() -> ())? = nil)
}

extension UIViewController {

    func showMimoAlert(_ type: AlertType) {
        switch type {
        case .errorNotification(let message):
            MimoAlertController.present(.error(message), on: self)

        case .important(let isSuccess, let title, let message, let action):
            var content = MimoAlertContent(
                kind: isSuccess ? .success : .important,
                title: title ?? (isSuccess
                                 ? "MOBILE_global_thank_you".localized(fallback: "Thank you")
                                 : "MOBILE_insufficient_account".localized(fallback: "Insufficient funds")),
                message: message,
                actions: [],
                autoDismiss: 3
            )
            content.dismissesOnScrimTap = true

            let alert = MimoAlertController(content: content, onDismissed: action)
            MimoAlertController.show(alert, on: self)
        }
    }

    func dismissMimoAlert() {
        (presentedViewController as? MimoAlertController)?.finish(with: nil, runHandler: false)
    }

    /// Shortcut for the common one-button case.
    func showMimoAlert(_ content: MimoAlertContent) {
        MimoAlertController.present(content, on: self)
    }
}
