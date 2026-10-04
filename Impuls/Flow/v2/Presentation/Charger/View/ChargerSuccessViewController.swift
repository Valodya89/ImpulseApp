//
//  ChargerSuccessViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import UIKit
import SwiftUI

// MARK: - End-of-rent summary

/// The summary shown the moment a power-bank rent ends (power-bank map and
/// Home). Presents the very same `ReceiptView` the history uses for that rent,
/// as a sheet with a drag handle and a close (x), plus a primary "Thank you"
/// button. Close, "Thank you" and a swipe-down all end it the same way: publish
/// `.chargerRentEnded` exactly once, so the map / home refresh as they always
/// did after the legacy `ChargerSuccessViewController`.
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
            dismiss(animated: true)
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
