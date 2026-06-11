import UIKit

final public class InsuranceTableViewCell: UITableViewCell {

    @IBOutlet weak var timerLabel: UILabel!
    // MARK: Outlets
    @IBOutlet private weak var insuranceLabel: UILabel!
    @IBOutlet private weak var insuranceButton: UIButton!
    @IBOutlet private weak var insuranceCheildImageView: UIImageView!
    @IBOutlet private weak var insuranceCheildImageViewCenterHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet private weak var informationButton: UIButton!
    @IBOutlet public weak var insurancePriceLabel: UILabel!
    var isHaveActiveInsurance: Double? = 0
    // MARK: Properties
    public static let cellNibName = UINib(nibName: "InsuranceTableViewCell", bundle: nil)
    public static let cellIdentifier = "InsuranceTableViewCell"
    public var currencySymbol: String = "" {
        didSet {
            let price = storageManager.fetch(key: .insurancePrice, type: Double.self) ?? 0
            insurancePriceLabel.text = "SCOOTER_insurance_price".localized().replacingOccurrences(of: "%s", with: "\(price) \(currencySymbol)")
        }
    }
    public var onInsuranceToggled: ((Bool) -> Void)?
    let storageManager = StorageManager()
    var timer: Timer?
    var expirationDate: Date?
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        timerLabel.isHidden = true
        insurancePriceLabel.isHidden = false
        // also stop timer if you have one
    }
    
    // MARK: View Lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        insuranceButton.layer.cornerRadius = insuranceButton.frame.height / 2
        // Initialization code
        insuranceLabel.text = "SCOOTER_insurance".localized()
    }
    
    func configure() {
        let price = storageManager.fetch(key: .insurancePrice, type: Double.self) ?? 0
        insurancePriceLabel.text = "SCOOTER_insurance_price".localized()
            .replacingOccurrences(of: "%s", with: "\(price) \(currencySymbol)")

        isHaveActiveInsurance = storageManager.fetch(key: .activeInsuranceEnd, type: Double.self)

        if let millis = isHaveActiveInsurance {
            timerLabel.isHidden = false
            insurancePriceLabel.isHidden = true

            let seconds = TimeInterval(millis) / 1000.0
            expirationDate = Date(timeIntervalSince1970: seconds)
            startTimer()
            updateLabel()
            setData(isSelected: true)
        } else {
            // ✅ IMPORTANT: reset UI for non-active state
            timerLabel.isHidden = true
            insurancePriceLabel.isHidden = false
            setData(isSelected: false)
        }

        // ⚠️ I recommend removing this line (see #4)
        // onInsuranceToggled?(isHaveActiveInsurance != nil)
    }

    
    func startTimer() {
            timer?.invalidate()

            timer = Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: true,
                block: { [weak self] _ in
                    self?.updateLabel()
                }
            )

            // ensure it runs on scroll, etc.
            RunLoop.main.add(timer!, forMode: .common)
        }

        func updateLabel() {
            guard let expirationDate = expirationDate else { return }

            let remaining = expirationDate.timeIntervalSinceNow

            if remaining <= 0 {
                timer?.invalidate()
                timer = nil
                timerLabel.isHidden = true
                insurancePriceLabel.isHidden = false
                setData(isSelected: false)
                onInsuranceToggled?(false)
                return
            }

            timerLabel.text = format(timeInterval: remaining)
        }

        func format(timeInterval: TimeInterval) -> String {
            let totalSeconds = Int(timeInterval)

            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60

            // HH:mm:ss (e.g. 01:23:45)
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    
    deinit {
            timer?.invalidate()
        }
    
    // MARK: Methods
    public func setData(isSelected: Bool) {
        insuranceButton.layer.cornerRadius = insuranceButton.frame.height / 2
        insuranceButton.isSelected = isSelected
        insuranceButton.backgroundColor = isSelected ? UIColor(named: "mimoYellow500") : UIColor(named: "mimoGrayLight")
//        informationButton.alpha = isSelected ? 1 : 0
        insuranceCheildImageViewCenterHorizontalConstraint.constant = isSelected ? 9 : -7
        self.layoutIfNeeded()
    }
    
    // MARK: Actions
    @IBAction private func insuranceButtonAction(_ sender: UIButton) {
        //sender.isSelected.toggle()
        let isHaveActiveInsurance = storageManager.fetch(key: .activeInsuranceEnd, type: Double.self)
        if isHaveActiveInsurance == nil {
            setData(isSelected: true)
            onInsuranceToggled?(true)
        }
    }
    
    @IBAction private func informationButtonAction(_ sender: UIButton) {
    }
}
