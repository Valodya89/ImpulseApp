//
//  ChargerSuccessViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import UIKit
import SwiftUI
import Combine

// MARK: - End-of-rent presenter

/// The one place that turns "this rent is over" into the Thank-you summary,
/// whatever screen is up. The summary used to be presented by two screens
/// only (Home and the power-bank map), each with its own gating, so a
/// RENT_ENDED that arrived while the rider was on Profile, in the wallet
/// sheet, behind an alert, in the background, or that reached the app over
/// the HTTP state re-read instead of the socket, was lost: the active strip
/// disappeared and nothing else happened.
///
/// Sources: the application-scoped power-bank socket (RENT_ENDED), and the
/// `GET /api/state` re-reads of Home and the map for a rent this process has
/// seen running (never for finished rents the strip never showed - the state
/// keeps listing old ones). One summary per rent id, however many sources
/// report the end. A summary that cannot be shown right now (background,
/// another summary or an alert up, a transition in flight) waits and is
/// retried on the next activation, Home / map appearance, summary dismissal,
/// and on a short timer while something is queued.
final class EndedRentPresenter {

    static let shared = EndedRentPresenter()

    /// Rents whose summary was presented in this process.
    private var shownRentIds = Set<String>()
    /// Rents this process has seen as RENT_STARTED (socket or state read):
    /// only these may get a summary from an HTTP state read.
    private var seenActiveRentIds = Set<String>()
    private var queue: [RentedCharger] = []
    private var cancellables = Set<AnyCancellable>()
    private var isStarted = false
    private var retry: DispatchWorkItem?

    /// How long a blocked summary (alert up, transition running) waits before
    /// the next attempt. Alerts have no dismissal hook of their own.
    private let retryInterval: TimeInterval = 1

    private init() {}

    // MARK: - Sources

    /// Idempotent. Started from the scene delegate; Home calls it again as a
    /// safety net.
    func start() {
        guard !isStarted else { return }
        isStarted = true

        // Application scope: the very same connection Home and the map listen
        // to, so nothing is subscribed twice and no frame is missed.
        let chargerSocket: MimoChargerSocketServiceProtocol = Resolver.resolve()
        chargerSocket.dataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rent in self?.handleSocketFrame(rent) }
            .store(in: &cancellables)

        // willEnterForeground is too early to present; didBecomeActive is not.
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.presentPendingIfPossible() }
            .store(in: &cancellables)
    }

    private func handleSocketFrame(_ rent: RentedCharger) {
        guard let id = rent.data?.id else { return }

        switch rent.rentState {
        case .rentStarted:
            seenActiveRentIds.insert(id)
        case .rentEnded:
            // The socket is live: its end always gets a summary.
            seenActiveRentIds.remove(id)
            offer(rent)
        case .rentNotStarted:
            // Never ran: no summary, and no HTTP fallback either.
            seenActiveRentIds.remove(id)
        default:
            break
        }
    }

    /// A rent ended. Shown now when possible, otherwise kept; never twice for
    /// the same rent. Frames without an id cannot be deduplicated and are
    /// ignored, as the two screens always did.
    func offer(_ rent: RentedCharger) {
        guard let id = rent.data?.id else { return }
        guard !shownRentIds.contains(id) else { return }

        // A later report of the same end carries at least as much data.
        queue.removeAll { $0.data?.id == id }
        queue.append(rent)
        MimoSocketLog.info(.charger, "summary queued", "rent=\(id)")
        presentPendingIfPossible()
    }

    /// HTTP fallback: one `GET /api/state` answer (Home strip or the map). A
    /// running rent is remembered; a rent reported as ended gets its summary
    /// only when this process saw it running, so the finished rents the state
    /// keeps listing for a while never produce one.
    func stateRead(_ rents: [RentedCharger]) {
        for rent in rents {
            guard let id = rent.data?.id else { continue }

            switch rent.rentState {
            case .rentStarted:
                seenActiveRentIds.insert(id)
            case .rentEnded:
                guard seenActiveRentIds.remove(id) != nil else { continue }
                MimoSocketLog.info(.charger, "summary from state read", "rent=\(id)")
                offer(rent)
            default:
                break
            }
        }
    }

    /// The summary sheet is gone: the next waiting one, if any, can go up.
    func summaryDismissed() {
        presentPendingIfPossible()
    }

    // MARK: - Presenting

    /// Shows the next waiting summary when the app is active and the top of
    /// the screen can take it. Safe to call from any appearance callback.
    func presentPendingIfPossible() {
        retry?.cancel()
        retry = nil

        guard let rent = queue.first, let id = rent.data?.id else { return }
        guard UIApplication.shared.applicationState == .active else { return }

        guard KeychainManager().isUserLoggedIn(),
              let top = UIApplication.shared.topMostViewController(),
              canPresent(over: top) else {
            scheduleRetry()
            return
        }

        queue.removeFirst()
        shownRentIds.insert(id)
        MimoSocketLog.info(.charger, "summary shown", "rent=\(id) over=\(type(of: top))")
        ChargerRouter.shared.showChargerSuccessViewController(top, currency: UserManager.share.walletModel?.currency, rentedCharger: rent)
    }

    private func canPresent(over top: UIViewController) -> Bool {
        if top is RentSummaryHostingController { return false }
        if top is UIAlertController || top is MimoAlertController { return false }
        if top.isBeingPresented || top.isBeingDismissed { return false }
        if top.presentedViewController != nil { return false }
        return top.viewIfLoaded?.window != nil
    }

    /// Blocked right now (an alert, a transition): try again shortly. The
    /// appearance and activation hooks still fire in between.
    private func scheduleRetry() {
        let work = DispatchWorkItem { [weak self] in self?.presentPendingIfPossible() }
        retry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval, execute: work)
    }
}

// MARK: - End-of-rent summary

/// The summary shown the moment a power-bank rent ends, over whatever screen
/// is up (`EndedRentPresenter`). Presents the very same `ReceiptView` the
/// history uses for that rent, as a sheet with a drag handle and a close (x),
/// plus a primary "Thank you" button. Close, "Thank you" and a swipe-down all
/// end it the same way: publish `.chargerRentEnded` exactly once, so the map /
/// home refresh as they always did after the legacy
/// `ChargerSuccessViewController`, then let the presenter show the next
/// waiting summary.
final class RentSummaryHostingController: UIHostingController<ReceiptView>, UIAdaptivePresentationControllerDelegate {

    private var didFinish = false

    /// Same entry data as `ChargerRouter.showChargerSuccessViewController`.
    init(rentedCharger: RentedCharger?, currency: String?) {
        // Filled in below, once `self` exists.
        var finishAction: () -> Void = {}

        let receipt = rentedCharger?.receipt(currency: currency)
            ?? RentedCharger.emptyReceipt(currency: currency)

        super.init(rootView: ReceiptView(
            receipt: receipt,
            doneTitle: "MOBILE_charger_thankYou".localized(fallback: "Thank you"),
            onDone: { finishAction() },
            onClose: { finishAction() }
        ))

        finishAction = { [weak self] in self?.finish(dismissing: true) }

        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            // The receipt draws its own handle.
            sheet.prefersGrabberVisible = false
        }
        presentationController?.delegate = self
        view.backgroundColor = UIColor(named: "EVBackgroundColor")
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: UIAdaptivePresentationControllerDelegate

    /// Swiped down: the sheet is gone already, only the event is still owed.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(dismissing: false)
    }

    private func finish(dismissing: Bool) {
        guard !didFinish else { return }
        didFinish = true

        let messagingService: MessageServiceProtocol = Resolver.resolve()
        messagingService.publish(.chargerRentEnded)

        if dismissing {
            dismiss(animated: true) {
                EndedRentPresenter.shared.summaryDismissed()
            }
        } else {
            EndedRentPresenter.shared.summaryDismissed()
        }
    }
}

private extension RentedCharger {

    /// A rent that ended without a payload (the socket frame failed to decode)
    /// still gets its summary - every cell prints '-' and the amount 0.00.
    static func emptyReceipt(currency: String?) -> ReceiptData {
        ReceiptData(
            id: UUID().uuidString,
            iconName: "mimo_charger_station",
            title: "MOBILE_history_detail_rent_complete".localized(),
            amount: ReceiptFormat.amount(nil, currency: currency),
            dateLine: ReceiptFormat.dateLineOrNow(milliseconds: 0),
            codeTitle: nil,
            code: nil,
            sections: [ReceiptSection(rows: [
                ReceiptRow(title: "MOBILE_history_detail_charger_id".localized(), value: "-"),
                ReceiptRow(title: "MOBILE_history_detail_plan".localized(fallback: "Plan"), value: "-"),
                ReceiptRow(title: "MOBILE_history_detail_duration".localized(), value: ReceiptFormat.clock(seconds: 0))
            ])]
        )
    }
}

// MARK: - Legacy storyboard screen

/// Legacy xib summary. No longer presented - `ChargerRouter` shows
/// `RentSummaryHostingController` instead - but the Charger storyboard scene
/// still names this class, so it stays until the scene is removed.
class ChargerSuccessViewController: MimoBaseViewController {
    
    @IBOutlet private weak var navigationBar: UINavigationBar!
    @IBOutlet private weak var thanksLabel: UILabel!
    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var chargerIDLabel: UILabel!
    @IBOutlet private weak var stationIDLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var planLabel: UILabel!
    
    var rentedCharger: RentedCharger?
    var currency: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        amountLabel.text = String(format: "%.2f \(currency ?? "₽‎")", rentedCharger?.data?.billingDetails?.amount ?? 0)
        stationIDLabel.text = rentedCharger?.data?.startStationQR ?? "-"
        chargerIDLabel.text = rentedCharger?.powerBank?.id
        navigationBar.topItem?.title = "MOBILE_charger_thankYou_navigationTitle".localized()
        planLabel.text = rentedCharger?.data?.billingDetails?.currentTariff?.priceName
        
        let startDate = rentedCharger?.data?.start ?? 0
        let endDate = rentedCharger?.data?.end ?? 0
        let duration = (endDate - startDate)/1000
        
        durationLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(duration))
        
        contentContainerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
    }
    
    @IBAction private func thankYouAction() {
        let messagingService: MessageServiceProtocol = Resolver.resolve()
        messagingService.publish(.chargerRentEnded)
        
        self.dismiss(animated: true)
    }
    
    @IBAction private func shareAction() {
        
    }
}
