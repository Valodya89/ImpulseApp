//
//  ChargerErrorViewController.swift
//  Impuls
//
//  The "you cannot start yet" popup raised when the backend refuses a rent or
//  a ride - most often for a balance under the minimum. One card for every
//  product: the illustration in a yellow well, the reason in words and, when
//  topping up would fix it, the two ways to do that plus one Continue that
//  opens the wallet. Otherwise just OK. The card hugs short content and
//  scrolls under the pinned button only when taller than the screen.
//
//  `showErrorPopUp(message:service:)` and `ScooterPlanViewController` still
//  construct it under this name with the old signature.
//

import UIKit
import SwiftUI

// MARK: - Content

struct ServiceBlockedPopupContent {
    let service: MimoType
    let message: String
    /// Whether the two top-up options and Continue are shown.
    let isReplenishable: Bool
    /// "5000 AMD"-style minimum shown inside the balance option's title.
    let minimumBalance: String

    /// Impulse rents power banks, so the power-bank station is the one
    /// illustration for every product except an EV charging point.
    var imageName: String {
        switch service {
        case .evCharger: return "mimo_ev_charger_station"
        case .scooter, .bike, .charger: return "mimo_charger_station"
        }
    }

    var title: String {
        "\("SCOOTER_min_balanse_title".localized(fallback: "Hi, friend")) ✋"
    }
}

// MARK: - View

struct ServiceBlockedPopupView: View {

    let content: ServiceBlockedPopupContent
    let onClose: () -> Void
    let onContinue: () -> Void

    @State private var appeared = false
    /// Measured height of the scrolling part, so the card hugs short content
    /// and only scrolls when the options do not fit the screen.
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Color.alwaysBlack.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            card
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.22)) { appeared = true }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    hero

                    Text(content.title)
                        .font(.robotoBold24)
                        .foregroundColor(.appLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(content.message)
                        .font(.robotoRegular15)
                        .foregroundColor(.appSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if content.isReplenishable {
                        options
                            .padding(.top, 4)

                        security
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(key: ContentHeightKey.self, value: geometry.size.height)
                    }
                )
            }
            .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
            .frame(maxHeight: contentHeight > 0 ? contentHeight : nil)

            footer
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .mimoCard(radius: 24)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appSecondaryLabel)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }

    private var hero: some View {
        Image(content.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .padding(18)
            .background(Circle().fill(Color.yellowTint))
            .padding(.top, 20)
    }

    /// The two ways out of a low balance, "or" between them.
    private var options: some View {
        VStack(spacing: 0) {
            option(
                imageName: "ic_popup_bank_card",
                systemImage: "creditcard.fill",
                title: Text("CHARGER_attach_bank_card".localized(fallback: "Attach a bank card")),
                subtitle: "CHARGER_attach_bank_card_description".localized(fallback: "Rentals are paid from the card automatically.")
            )

            orDivider

            option(
                imageName: "ic_popup_wallet",
                systemImage: "wallet.pass.fill",
                title: balanceTitle,
                subtitle: "CHARGER_top_up_balance_description".localized(fallback: "Add money to your wallet and pay from it.")
            )
        }
    }

    private var balanceTitle: Text {
        let template = "CHARGER_top_up_balance".localized(fallback: "Top up at least %@")
        let text = template.contains("%@")
            ? String(format: template, content.minimumBalance)
            : "\(template) \(content.minimumBalance)"
        // The amount is what the rider needs to remember, so it gets the colour.
        guard let range = text.range(of: content.minimumBalance) else { return Text(text) }

        return Text(text[..<range.lowerBound])
            + Text(text[range]).foregroundColor(.successGreen)
            + Text(text[range.upperBound...])
    }

    private func option(imageName: String, systemImage: String, title: Text, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Group {
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.appSecondaryLabel)
                }
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                title
                    .font(.robotoBold16)
                    .foregroundColor(.appLabel)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.robotoRegular13)
                    .foregroundColor(.appSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appFill)
        )
    }

    private var orDivider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.dividerColor).frame(height: 1)

            Text("MOBILE_global_or".localized(fallback: "or"))
                .font(.robotoRegular13)
                .foregroundColor(.appSecondaryLabel)

            Rectangle().fill(Color.dividerColor).frame(height: 1)
        }
        .frame(height: 30)
    }

    /// Reassurance above the button. Informational only, so it does not
    /// compete with Continue.
    private var security: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if UIImage(named: "ic_security") != nil {
                    Image("ic_security")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.successGreen)
                }
            }
            .frame(width: 24, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("CHARGER_security_title".localized(fallback: "Your payments are protected"))
                    .font(.robotoBold14)
                    .foregroundColor(.appLabel)
                    .fixedSize(horizontal: false, vertical: true)

                Text("CHARGER_security_description".localized(fallback: "Card details are handled by the bank, never stored by the app."))
                    .font(.robotoRegular12)
                    .foregroundColor(.appSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
    }

    private var footer: some View {
        Group {
            if content.isReplenishable {
                Button(action: onContinue) {
                    Text("MOBILE_global_continue".localized(fallback: "Continue"))
                }
                .buttonStyle(MimoAlertButtonStyle(tone: .primary))
            } else {
                Button(action: onClose) {
                    Text("MOBILE_global_ok".localized(fallback: "OK"))
                }
                .buttonStyle(MimoAlertButtonStyle(tone: .primary))
            }
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Controller

class ChargerErrorViewController: UIViewController {

    private let content: ServiceBlockedPopupContent
    private let onReplenish: () -> Void

    /// The minimum the rent rules ask for when no card is attached. Source:
    /// powerbank docs/mobile-api.md, POST /api/rent/{id}/scan -
    /// `WALLET_min_balance_or_card_required` (`MIN_BALANCE_OR_CARD`, `amount` 5000).
    static let defaultMinimumAmount: Double = 5000

    /// `amount` followed by the signed-in user's wallet currency, e.g. "5000 AMD".
    /// Falls back to the bare amount when no wallet is loaded - never another
    /// currency's name.
    static func formattedMinimumBalance(_ amount: Double = defaultMinimumAmount) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"

        guard let currency = UserManager.share.walletModel?.currency.currencyNameOrCode else {
            return number
        }
        return "\(number) \(currency)"
    }

    /// - Parameters:
    ///   - message: the backend's reason, already made user-facing.
    ///   - isReplenishable: whether topping up fixes it (options + Continue).
    ///   - service: picks the illustration; the power-bank station by default.
    ///   - minimumAmount: the balance the rules ask for, shown in the top-up option.
    ///   - onReplenish: runs after Continue once the card has closed.
    init(message: String,
         isReplenishable: Bool,
         service: MimoType = .charger,
         minimumAmount: Double = ChargerErrorViewController.defaultMinimumAmount,
         onReplenish: @escaping () -> Void) {
        self.content = ServiceBlockedPopupContent(service: service,
                                                  message: message,
                                                  isReplenishable: isReplenishable,
                                                  minimumBalance: ChargerErrorViewController.formattedMinimumBalance(minimumAmount))
        self.onReplenish = onReplenish
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// A card over the screen needs the presenter to stay visible. Callers that
    /// still set `.fullScreen` (the storyboard plan screen) are overruled here.
    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .overFullScreen }
        set { }
    }

    override var modalTransitionStyle: UIModalTransitionStyle {
        get { .crossDissolve }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let host = UIHostingController(
            rootView: ServiceBlockedPopupView(
                content: content,
                onClose: { [weak self] in self?.dismiss(animated: true) },
                onContinue: { [weak self] in
                    guard let self else { return }
                    let onReplenish = self.onReplenish
                    self.dismiss(animated: true, completion: onReplenish)
                }
            )
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
        MimoFeedback.shared.error()
    }
}
