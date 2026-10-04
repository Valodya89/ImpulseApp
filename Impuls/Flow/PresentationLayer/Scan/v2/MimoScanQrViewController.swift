//
//  MimoScanQrViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 01.06.23.
//
//  The QR scan screen. The camera (`QRScannerView`), code validation and the
//  delegate live here; everything drawn on top of the camera is
//  `MimoScanQrOverlayView` below. The storyboard scene still connects the
//  outlets, so they stay declared and its subviews are hidden instead of
//  removed.
//

import UIKit
import SwiftUI
import AVFoundation
import MercariQRScanner

protocol MimoScanQrViewControllerDelegate: AnyObject {
    func didFinishScan(with value: String, type: MimoType)
}

class MimoScanQrViewController: MimoBaseViewController {

    @IBOutlet private weak var qrTextField: MITextFieldView!

    @IBOutlet private weak var flashButton: UIButton!
    @IBOutlet private weak var doneButton: UIBarButtonItem!

    @IBOutlet private weak var qrTextFieldBottomConstraint: NSLayoutConstraint!

    var mimoType: MimoType?
    weak var delegate: MimoScanQrViewControllerDelegate?

    private var qrScannerView: QRScannerView?
    private let overlayModel = MimoScanQrOverlayModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        installOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // The overlay carries its own close button; the storyboard's bar is
        // only chrome now.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if qrScannerView == nil {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                self.setupQRScanner()
            } else {
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        if granted {
                            self.setupQRScanner()
                        } else {
                            self.showCameraAccessAlert()
                        }
                    }
                }
            }
        }
    }

    private func setupQRScanner() {
        guard qrScannerView == nil else { return }
        self.qrScannerView = QRScannerView(frame: self.view.bounds)
        self.qrScannerView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // The library draws its own focus frame at a fixed spot; a clear image
        // keeps that out of the way so the overlay's viewfinder is the only one.
        let clearFocus = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
        self.qrScannerView?.configure(delegate: self, input: .init(focusImage: clearFocus, isBlurEffectEnabled: true))
        self.qrScannerView?.startRunning()
        self.view.addSubview(self.qrScannerView!)
        self.view.sendSubviewToBack(self.qrScannerView!)
    }

    private func installOverlay() {
        view.subviews.forEach { $0.isHidden = true }
        view.backgroundColor = .black

        let host = UIHostingController(
            rootView: MimoScanQrOverlayView(
                model: overlayModel,
                onClose: { [weak self] in self?.doneAction() },
                onToggleTorch: { [weak self] in self?.flashAction() },
                onSubmit: { [weak self] code in self?.submitManualCode(code) }
            )
        )
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        view.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        host.didMove(toParent: self)
    }

    private func finishScan(with code: String) {
        self.dismiss(animated: true) { [code, mimoType, delegate] in
            var val: String
            switch mimoType {
            case .scooter:
                val = code
            case .bike:
                val = URL(string: code)?.query ?? ""
            case .charger:
                val = URL(string: code)?.lastPathComponent ?? ""
            case .evCharger:
                val = URL(string: code)?.lastPathComponent ?? ""
            case nil:
                val = ""
            }
            delegate?.didFinishScan(with: val, type: mimoType ?? .scooter)
        }
    }

    /// The typed code. Same wrapping the old text field did: anything that is
    /// not a scooter or station code is handed to the validators as a URL.
    private func submitManualCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            overlayModel.shakeToken += 1
            MimoFeedback.shared.error()
            return
        }

        var value = trimmed
        if !value.hasPrefix("1001") && !value.hasPrefix("200") {
            value = "https://testHost.com?\(value)"
        }

        handleScanned(code: value, qrScannerView: qrScannerView)
    }
}

// MARK: - Actions
extension MimoScanQrViewController {

    @IBAction private func flashAction() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            device.unlockForConfiguration()
            overlayModel.isTorchOn = device.torchMode == .on
            MimoFeedback.shared.impactLight()
        } catch {
            print(error)
        }
    }

    @IBAction private func doneAction() {
        self.dismiss(animated: true)
    }
}

extension MimoScanQrViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        showAlertMessage("MOBILE_scan_not_supported".localized(fallback: "Scanning not supported"), meassage: error.localizedDescription)
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        handleScanned(code: code, qrScannerView: qrScannerView)
    }

    // Also reached from manual code entry, where no scanner exists because the
    // user denied camera access.
    private func handleScanned(code: String, qrScannerView: QRScannerView?) {
        let scooterQrValidator = Validator(data: code)
                                    .isValidScooterCode()
                                    .validate()

        let chargerQrValidator = Validator(data: code)
                                    .isValidChargerCode()
                                    .validate()
        let evChargerQrValidator = Validator(data: code)
                                    .isValidEVChargerCode()
                                    .validate()

        let bikeQrValidator = Validator(data: code)
                                .isValidBikeCode()
                                .validate()

        // Cleared first: otherwise an unrecognised code kept the type this screen
        // was opened with and was processed as that vehicle instead of rejected.
        mimoType = nil

        if scooterQrValidator.isValid {
            mimoType = .scooter
        } else if chargerQrValidator.isValid {
            mimoType = .charger
        } else if bikeQrValidator.isValid {
            mimoType = .bike
        } else if evChargerQrValidator.isValid {
            mimoType = .evCharger
        }

        if mimoType == .scooter {
            UserDefaults.standard.set("scooter", forKey: "BikeState")
        } else if mimoType == .charger {
            //
        } else if mimoType == .evCharger {
            //
        } else if mimoType == .bike {
            UserDefaults.standard.set("bike", forKey: "BikeState")
        } else {
            self.showAlertMessage("MOBILE_incorrect_qr".localized(), actionText: "MOBILE_global_ok".localized(), action: {
                qrScannerView?.rescan()
            })

            return
        }

        finishScan(with: code)
    }
}

// MARK: - Overlay

/// State shared between the controller and the SwiftUI overlay.
final class MimoScanQrOverlayModel: ObservableObject {
    @Published var code: String = ""
    @Published var isTorchOn: Bool = false
    /// Manual entry shakes when submitted empty; bumping this replays it.
    @Published var shakeToken: Int = 0
}

/// Everything drawn over the camera on the QR scan screen: the close and
/// torch controls, the viewfinder frame with its hint, and the card at the
/// bottom for typing the code instead. Lives in this file because the Xcode
/// project is not folder-synchronised.
struct MimoScanQrOverlayView: View {

    @ObservedObject var model: MimoScanQrOverlayModel
    let onClose: () -> Void
    let onToggleTorch: () -> Void
    let onSubmit: (String) -> Void

    @FocusState private var isEditing: Bool

    private let maxCodeLength = 10

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Spacer(minLength: 12)

            viewfinder

            Spacer(minLength: 12)

            entryCard
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { isEditing = false }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack {
            roundButton(systemImage: "xmark", isActive: false, action: onClose)

            Spacer()

            Text("MOBILE_scan_qr_title".localized(fallback: "Scan QR code"))
                .font(.robotoBold17)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            roundButton(systemImage: model.isTorchOn ? "bolt.fill" : "bolt.slash.fill",
                        isActive: model.isTorchOn,
                        action: onToggleTorch)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Drawn over the camera, so white on a dark scrim in both appearances.
    private func roundButton(systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isActive ? .onBrandLabel : .white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(isActive ? Color.brandYellow : Color.black.opacity(0.45)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Viewfinder

    private var viewfinder: some View {
        VStack(spacing: 18) {
            MimoScanViewfinderCorners()
                .stroke(Color.brandYellow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 240, height: 240)

            Text("MOBILE_scan_bike_code".localized())
                .font(.robotoMedium15)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
        }
    }

    // MARK: - Manual entry

    private var entryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOBILE_scan_enter_code".localized(fallback: "Or type the code"))
                .font(.robotoMedium13)
                .foregroundColor(.appSecondaryLabel)

            HStack(spacing: 10) {
                TextField("", text: Binding(
                    get: { model.code },
                    set: { model.code = String($0.filter(\.isNumber).prefix(maxCodeLength)) }
                ))
                .keyboardType(.numberPad)
                .font(.robotoMedium16)
                .foregroundColor(.appLabel)
                .focused($isEditing)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.appSecondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isEditing ? Color.brandYellow : Color.appSeparator, lineWidth: 1)
                )
                .modifier(MimoScanShakeEffect(shakes: CGFloat(model.shakeToken)))
                .animation(.default, value: model.shakeToken)

                Button {
                    isEditing = false
                    onSubmit(model.code)
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(model.code.isEmpty ? .gray4 : .onBrandLabel)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(model.code.isEmpty ? Color.appFill : Color.brandYellow))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .mimoCard(radius: 20)
    }
}

/// Four L-shaped corners: the classic scan frame, drawn rather than shipped
/// as an image so it takes the accent colour.
private struct MimoScanViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 32
        let radius: CGFloat = 20
        var path = Path()

        // top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        // top-right
        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        // bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))

        // bottom-left
        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))

        return path
    }
}

private struct MimoScanShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 4), y: 0))
    }
}
