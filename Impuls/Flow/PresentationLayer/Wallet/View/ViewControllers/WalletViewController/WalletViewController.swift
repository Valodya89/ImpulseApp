//
//  WalletViewController.swift
//  MimoBike
//
//  Created by Vardan on 17.05.21.
//

import UIKit
import ContactsUI

enum WalletFillOptions: CaseIterable {
    case card
    case attachCard
    case iDram
    case tellCell
    case crypto
}

private enum MethodPayment {
    case card
    case deposit
    case iDram
    case tellCell(phone: String)
    case crypto
    case none
}

final class WalletViewController: UIViewController, StoryboardInitializable {
    
    //MARK: - Outlets
    @IBOutlet weak var collectionViewParent: UIView!
    @IBOutlet weak var collectionLayerHeight: NSLayoutConstraint!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var collectionLayerWidth: NSLayoutConstraint!
    @IBOutlet weak var payButton: ActionButton!
    @IBOutlet weak var freeMinutesLabel: UILabel!
    @IBOutlet weak var balanceCurrency: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var paymentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var balanceView: UIView!
    @IBOutlet weak var promoBGView: UIView!
    @IBOutlet weak var transferMoneyView: UIView!
    @IBOutlet weak var orderCardView: UIView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardContentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var numericTextField: NumericTextField!
    
    @IBOutlet weak var promoCodeBGView: UIView!
    
    @IBOutlet weak var promoCodeViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var promoCodeTF: UITextField!
    @IBOutlet weak var sendPromoBtn: UIButton!
    
    
    
    var index = 0
    var inForwardDirection = true
    var timer: Timer?
    private var collectionModel: [WalletFillOptions] = WalletFillOptions.allCases
    private var currentVisibleCollectionIndex: Int = 0
    
    var orderCardNavVC: UINavigationController?
    
    private lazy var pagerControll: UIPageControl = {
        let pageContoll = UIPageControl()
        pageContoll.numberOfPages = collectionModel.count
        pageContoll.currentPageIndicatorTintColor = UIColor.mimoBlackWith075alpha
        pageContoll.pageIndicatorTintColor = UIColor.mimoBlackWith025alpha
        return pageContoll
    }()
    
    private lazy var pagerControll2: UIPageControl = {
        let pageContoll = UIPageControl()
        pageContoll.numberOfPages = collectionModel.count
        pageContoll.currentPageIndicatorTintColor = UIColor.mimoBlackWith075alpha
        pageContoll.pageIndicatorTintColor = UIColor.mimoBlackWith025alpha
        return pageContoll
    }()
    private var userPhone: String? {
        return  StorageManager().fetch(key: .phoneNumber, type: String.self)
    }
    
    private var currentMethodPayment: MethodPayment = .none
    
    let x = 50
    var dispeceficCount: Int = -1
    var isConifugratedCollection = false
    
    //MARK: - Variables
    
    var friendsList = [ContactsModel]()
    var viewModel = WalletViewModel()
    var user: UserResult?
    var account: UserResult?
    var wallet: WalletModel?
    var avataturURLString: String?
    var tellCellPhoneNumber: String?
    var isPageControllHidden: Bool = false
    var animationDispatchBerrier: DispatchWorkItem?
    var animatablePageControll: Bool = true
    var amount = 0
    
    //MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numericTextField.keyboardType = .numberPad
        if let debt = UserManager.share.debtAmount , debt > 0 {
            numericTextField.numberText = (debt - (UserManager.share.walletModel?.balance ?? 0.0).rounded())
        }
        scrollView.animateOut(animatable: false)
        MILoader.show()
        registerKeyboardNotifications()
        configureUI()
        registerCells()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(userChanged), name: Constant.Notifications.updateUserUI, object: nil)
        let tapGestureHideKeyboard =  UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureHideKeyboard)
//        self.perform(#selector(scrollToNextCell), with: nil, afterDelay: 1)
    }
    
    /// tap gesture recognizer selector function view end editing
    @objc private func hideKeyBoard () {
        view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchData()
        loadPagerControll()
        configureDelegates()
        startTimer()
        checkPromoStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let messageService: MessageServiceProtocol = Resolver.resolve()
        messageService.publish(.balanceUpdated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print(" viewDidDisappear WalletViewController")
        self.timer?.invalidate()
        self.timer = nil
        NotificationCenter.default.post(name: Constant.Notifications.updateUserUI, object: nil)
    }
    
    @objc func userChanged() {
        fetchData()
    }
    
    @objc func scrollToNextCell() {
        currentVisibleCollectionIndex += 1
        print("current index = \(currentVisibleCollectionIndex) - from: \(collectionModel.count * x)")
        if currentVisibleCollectionIndex < collectionModel.count * x {
            collectionView.scrollToItem(at: IndexPath(row: currentVisibleCollectionIndex, section: 0), at: .centeredVertically, animated: true)
        } else {
            currentVisibleCollectionIndex = 0
            collectionView.scrollToItem(at: IndexPath(row: currentVisibleCollectionIndex, section: 0), at: .centeredVertically, animated: true)
        }
    }

    /**
     call this method when collection view loaded
     */
    func startTimer() {
//        if timer == nil {
//            timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(scrollToNextCell), userInfo: nil, repeats: true);
//        }
    }
        
    /// configure user interface
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        orderCardView.layer.borderWidth = 1
        orderCardView.layer.cornerRadius = 12
        orderCardView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
      
        collectionViewParent.layer.borderWidth = 1
        collectionViewParent.layer.cornerRadius = 12
        collectionViewParent.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        
        transferMoneyView.layer.borderWidth = 1
        transferMoneyView.layer.cornerRadius = 12
        transferMoneyView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        balanceView.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
        promoBGView.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
        if isConifugratedCollection == false {
            isConifugratedCollection = true
            configureDelegates()
        }
    }
    
    func checkPromoStatus() {
        self.viewModel.checkPromo { result in
            switch result {
            case .success(let status):
                if status.active {
                    self.promoCodeViewHeightConstraint.constant = 100
                    self.promoCodeBGView.isHidden = false
                }  else {
                    self.promoCodeViewHeightConstraint.constant = 0
                    self.promoCodeBGView.isHidden = true
                }
            case .failure(let error):
                break
            }
        }
    }
    
    func fetchData() {
        if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" {
            freeMinutesLabel.text = account?.minutes.description ?? "0"
        } else {
            freeMinutesLabel.text = "0"
        }
        
        self.viewModel.walletInfo {[weak self] info in
            guard let self = self else { return }
            if case .success(let model) = info {
                if model.balance < UserManager.share.debtAmount ?? 0.0 {
                    self.balanceLabel.textColor = .red
                    self.balanceLabel.text = String((model.balance - (UserManager.share.debtAmount ?? 0.0)).rounded())
                } else {
                    self.balanceLabel.text = String(model.balance)
                }
                
                self.balanceCurrency.text = model.currency
                self.wallet = model
                self.reloadData(basedModel: model)
                self.scrollView.animateIn(animatable: true)
                MILoader.hide()
            } else if case .failure(let error) = info {
                MILoader.hide()
                self.scrollView.animateIn(animatable: true)
                UIAlertController.showError(message: error.localizedDescription)
                print("Request errror ================== \n \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: - Methods
    
    /// configure user interface
    func configureUI() {
        minLabel.text = "MOBILE_wallet_minimal_fee".localized().replacingOccurrences(of: "[num]", with: 99.9.description)
        configCollectionView()
    }
    
    private func updatePaymentMethod(to method: MethodPayment) {
        currentMethodPayment = method
        if case .none = method {
            payButton.isActive = false
        } else {
            payButton.isActive = true
        }
    }
    
    private func reloadData(basedModel: WalletModel) {
        if basedModel.card == nil {
            collectionModel.removeAll(where: {$0 == .card})
            collectionView.reloadData()
            scrollToMiddle(atIndex: 0, animated: true)
            pagerControll.numberOfPages = 4
            pagerControll2.numberOfPages = 4
        } else {
            collectionModel = WalletFillOptions.allCases
            collectionView.reloadData()
            scrollToMiddle(atIndex: 0, animated: true)
            pagerControll.numberOfPages = 5
            pagerControll2.numberOfPages = 5
        }
    }
    
    private func loadPagerControll() {
        paymentView.addSubview(pagerControll2)
        paymentView.addSubview(pagerControll)
        pagerControll.translatesAutoresizingMaskIntoConstraints = false
        view.layoutIfNeeded()
        pagerControll.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        pagerControll.centerXAnchor.constraint(equalTo: collectionViewParent.trailingAnchor, constant: 8).isActive = true
        pagerControll.currentPage = 0
        pagerControll.isUserInteractionEnabled = false
        pagerControll.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi / 2), 0, 0, 1)
        pagerControll.layer.transform = CATransform3DScale(pagerControll.layer.transform, 0.9, 0.9, 1)

        pagerControll2.translatesAutoresizingMaskIntoConstraints = false
        pagerControll2.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        pagerControll2.centerXAnchor.constraint(equalTo: collectionViewParent.leadingAnchor, constant: -8).isActive = true
        pagerControll2.currentPage = 0
        pagerControll2.isUserInteractionEnabled = false
        pagerControll2.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi / 2), 0, 0, 1)
        pagerControll2.layer.transform = CATransform3DScale(pagerControll2.layer.transform, 0.9, 0.9, 1)

        
        view.layoutSubviews()
        
        
        
        DispatchQueue.main.async {
            self.setPageControllState(isHidden: true)
        }
    }
    
    /// configure delegates
    private func configureDelegates() {
        collectionView.scrollsToTop = false
        scrollToMiddle(atIndex: 0, animated: false)
        promoCodeTF.delegate = self
    }
    
    /// configure collection
    private func configCollectionView() {
        let floawLayout = collectionView.collectionViewLayout as! UPCarouselFlowLayout
        floawLayout.itemSize = CGSize(width: collectionView.frame.width, height: 156)
        floawLayout.scrollDirection = .vertical
        floawLayout.sideItemScale = 0.8
        floawLayout.sideItemAlpha = 0.7
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        collectionView.collectionViewLayout = floawLayout
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    /// register tableView cell
    private func registerCells() {
        
        collectionView.register(UINib(nibName: AddCreditCardCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: AddCreditCardCollectionViewCell.reuseIdentifier())
        collectionView.register(UINib(nibName: CreditCardCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: CreditCardCollectionViewCell.reuseIdentifier())
        collectionView.register(UINib(nibName: TelcellCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: TelcellCollectionViewCell.reuseIdentifier())
        collectionView.register(UINib(nibName: IDramCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: IDramCollectionViewCell.reuseIdentifier())
        collectionView.register(CryptoCollectionViewCell.self)
    }
        
    private func attachCard() {
        MILoader.show()
        
        func attachCard2() {
            self.viewModel.attachCard { result in
                switch result {
                case .success(let model):
                    MILoader.hide()
                    self.presentAddCardVC(false, cardModel: model)
                case .failure(let error):
                    MILoader.hide()
                    UIAlertController.showError(message: error.localizedDescription)
                }
            }
        }
        
        if wallet?.card != nil {
            MILoader.hide()
            UIAlertController.showAction(title: "MOBILE_global_warning".localized(), message: "MOBILE_wallet_already_have_card".localized(), actions: ("MOBILE_global_continue".localized(), .default, { [weak self] action in
                MILoader.show()
                self?.viewModel.deleteCard {[weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(_):
                        attachCard2()
                        MILoader.hide()
                    case .failure(let error):
                        MILoader.hide()
                        UIAlertController.showError(message: error.localizedDescription)
                    }
                }
            }), ("MOBILE_global_cancel".localized(), .default, {
                action in
                action.dismiss(animated: true, completion: nil)
            }))
        } else {
            attachCard2()
        }
    }
    
    private func depositWithoutCard(_ ammount: Double) {
        MILoader.show()
        viewModel.depositWithoutCard(ammount: ammount) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let model):
                MILoader.hide()
                self.presentAddCardVC(true, cardModel: model)
            case .failure(let error):
                MILoader.hide()
                UIAlertController.showError(message: error.localizedDescription)
                
            }
        }
    }
    
    /// present add card view
    private func presentAddCardVC(_ isDeposit: Bool, cardModel: AttachCardModel) {
        guard let wallet = wallet else { return }
        let addCardVC = AddCreditCardViewController.config(isDeposit: isDeposit, hasAttachedCard: wallet.hasOldCards, walletModel: cardModel, delegate: self)
        navigationController?.pushViewController(addCardVC, animated: true)
    }
    
    private func presentTransferViewController() {
        if UserManager.share.isHaveScooterTrip || UserManager.share.isHaveBikeTrip {
            UIAlertController.showError(message: "MOBILE_have_active_trip".localized())
        } else {
            
            let transferVC = TransferViewController.initFromStoryboard(name: Constant.Storyboards.transfer)
            transferVC.user = user
            transferVC.avatarUrl = avataturURLString
            transferVC.wallet = wallet
            
            let nc = UINavigationController(rootViewController: transferVC)
            present(nc, animated: true, completion: nil)
        }
    }
    
    private func setPageControllState(isHidden: Bool) {
        isPageControllHidden = isHidden
        
        if isHidden {
            
            self.collectionLayerWidth.constant = 10
            self.collectionLayerHeight.constant = 10
          
            UIView.animate(withDuration: 0.12, animations: {
                self.view.layoutIfNeeded()
            }) { _ in
                self.collectionLayerHeight.constant = 0
                self.collectionLayerWidth.constant = 0
                UIView.animate(withDuration: 0.12) {
                    self.view.layoutIfNeeded()
                }

            }
        } else {
            self.collectionLayerWidth.constant = 0
            self.collectionLayerHeight.constant = 0
            UIView.animate(withDuration: 0.12, animations: {
                self.view.layoutIfNeeded()

            }) { _ in
                self.collectionLayerHeight.constant = 10
                self.collectionLayerWidth.constant = 10
                UIView.animate(withDuration: 0.12) {
                    self.view.layoutIfNeeded()
                }

            }
        }
    }
    
    @IBAction func sendPromoAcction(_ sender: UIButton) {
        
        if let code = self.promoCodeTF.text, !code.isEmpty  {
            MILoader.show()
            self.viewModel.sendPromoCode(code: code) { result in
                MILoader.hide()
                self.promoCodeTF.resignFirstResponder()
                switch result {
                case .success:
                    self.showErrorAlertMessage("MOBILE_global_success".localized())
                case .failure(let err):
                    switch err {
                    case .custom(let message):
                        self.showErrorAlertMessage(message.localized())
                    case .internalError:
                        print(err.localizedDescription)
                    case .parseError:
                        print(err.localizedDescription)
                    }
                }
            }
        } else {
            self.promoCodeBGView.shake()
        }
    }
    
    @IBAction func transferMoneyTapped(_ sender: UIButton) {
        presentTransferViewController()
    }
    
    @IBAction func payButtonTapped(_ sender: ActionButton) {
        guard payButton.isActive else {
            return
        }
    
        let currentIndex = arrayIndexForRow(currentVisibleCollectionIndex)
        if self.numericTextField.numberText ?? 0.0 > 0.0 {
            var numberText = self.numericTextField.numberText ?? 0.0
    //        if numberText < 99.9 {
    //            self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Min value to transfer is 99.9 AMD")
    //
    //            return
    //        }
        
            let phoneNumber  = self.tellCellPhoneNumber
            if collectionModel[currentIndex] == .tellCell && (phoneNumber?.isEmpty ?? true) {
                self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Please fill telcell phone number or check your current phone number")
            }
            
            
            if collectionModel[currentIndex] == .tellCell {
                let telcellURL = "telCell"
                
                if openTelCellApp() {
                    MILoader.show()
                    UserWalletManager.shared.payWallet(paymentMethod: collectionModel[currentIndex], amount: numberText, phoneNumber: phoneNumber) { [weak self] (result) in
                        MILoader.hide()
                        
                        switch result {
                        case .success(let paySuccess):
                            self?.handlePaySuccess(result: paySuccess)
                        case .failure(let payFailure):
                            self?.handlePayError(result: payFailure)
                        }
                    }
                }
            } else if collectionModel[currentIndex] == .crypto {
                if numberText >= 1000 {
                    MILoader.show()
                    self.viewModel.depositWithCripto(amount: numberText) { result in
                        MILoader.hide()
                        switch result {
                        case .success(let resultModel):
                            print(resultModel)
                            self.presentAddCardVC(false, cardModel: resultModel)
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                } else {
                    self.numericTextField.shake()
                    self.showErrorAlertMessage("MOBILE_min_value_to_transfer".localized().replacingOccurrences(of: "99.9", with: "1000"))
                }
            } else {
                MILoader.show()
                UserWalletManager.shared.payWallet(paymentMethod: collectionModel[currentIndex], amount: numberText, phoneNumber: phoneNumber) { [weak self] (result) in
                    MILoader.hide()
                    
                    switch result {
                    case .success(let paySuccess):
                        self?.handlePaySuccess(result: paySuccess)
                    case .failure(let payFailure):
                        self?.handlePayError(result: payFailure)
                    }
                }
            }
           
        } else {
            self.numericTextField.shake()
        }
        
      
    }
    
    @IBAction private func closeAction() {
        self.dismiss(animated: true)
    }
    
    func openTelCellApp() -> Bool {
        let instagramHooks = "telcell://"
        let instagramUrl = URL(string: instagramHooks)
        
        let instagramHooks2 = "telCell://"
        let instagramUrl2 = URL(string: instagramHooks2)
        
        let instagramHooks3 = "telcell-wallet://"
        let instagramUrl3 = URL(string: instagramHooks3)
        
        if UIApplication.shared.canOpenURL(instagramUrl!) {
//            UIApplication.shared.open(instagramUrl!)
            return true
        } else if UIApplication.shared.canOpenURL(instagramUrl2!) {
//            UIApplication.shared.open(instagramUrl2!)
            return true
        } else if UIApplication.shared.canOpenURL(instagramUrl3!) {
//            UIApplication.shared.open(instagramUrl3!)
            return true
        } else {
            print("App not installed")
            UIApplication.shared.open(URL(string: "https://apps.apple.com/am/app/telcell-wallet/id1324511564")!)
            return false
        }
    }
    
    func handlePaySuccess(result: PaymentSuccess) {
        switch result {
        case .attachCard(let model):
            self.presentAddCardVC(true, cardModel: model)
        case .idram(let iDramSuccess):
            switch iDramSuccess {
            case .redirectedToApp:
                debugPrint("Application successfully redirected to app store")
            }
        case .visa(let walletModel):
            self.balanceLabel.text = String(walletModel.balance)
            self.balanceCurrency.text = walletModel.currency
            self.wallet = walletModel
            self.reloadData(basedModel: walletModel)
            self.scrollView.animateIn(animatable: true)
        case .telcell:
            self.showAlertMessage("MOBILE_verify_successful_alert".localized(), meassage: "MOBILE__trip_sent_telcell".localized())
        }
    }
    
    func handlePayError(result: PaymentFailures) {
        switch result {
        case .error(let error):
            UIAlertController.showError(message: error.description)
        case .idram(let iDramError):
            switch iDramError {
            case .showIdramAlert(let alert):
                self.present(alert, animated: true, completion: nil)
            case .error(let error):
                UIAlertController.showError(message: error.localizedDescription)
            }
        case .attachCardError(let error):
            switch error {
            case .paymentRejected:
                UIAlertController.showError(message: error.description)
            case .unknown(message: let message):
                UIAlertController.showError(message: message)
            }
        }
    }
    
    @IBAction func orderCardTapped(_ sender: UIButton) {
        let orderCardVC = OrderCardViewController.initFromStoryboard(name: Constant.Storyboards.orderCard)
        self.navigationController?.pushViewController(orderCardVC, animated: true)
    }
    
}

//MARK: - Extensions UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate

extension WalletViewController: UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollToMiddle(atIndex: Int, animated: Bool = true) {
//        UIView.setAnimationsEnabled(false)
//        collectionView.invalidateIntrinsicContentSize()
//        let layout = collectionView.collectionViewLayout as! UPCarouselFlowLayout
//        let middleIndex = atIndex + x * collectionModel.count / 2
//        self.collectionView.scrollToItem(at: IndexPath(item: middleIndex - 1, section: 0), at: .centeredVertically, animated: false)
//        self.collectionView.scrollToItem(at: IndexPath(item: middleIndex - 1, section: 0), at: .centeredVertically, animated: false)
//        self.collectionView.scrollToItem(at: IndexPath(item: middleIndex - 1, section: 0), at: .centeredVertically, animated: false)
//        self.collectionView.scrollToItem(at: IndexPath(item: middleIndex - 1, section: 0), at: .centeredVertically, animated: false)
//        self.collectionView.layoutIfNeeded()
//        self.collectionView.scrollToItem(at: IndexPath(item: middleIndex, section: 0), at: .centeredVertically, animated: false)
//        self.view.layoutSubviews()
//        self.collectionView.layoutSubviews()
//        self.collectionView.scrollToItem(at: IndexPath(item: middleIndex, section: 0), at: .centeredVertically, animated: false)
//        layout.invalidateLayout()
//        currentVisibleCollectionIndex = middleIndex
//        
//        if atIndex == 0 {
//            updatePaymentMethod(to: .deposit)
//        }
//        
//        UIView.setAnimationsEnabled(true)
    }
    
    func arrayIndexForRow(_ row : Int) -> Int {
        return row % collectionModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionModel.count * x
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = arrayIndexForRow(indexPath.row)
        switch collectionModel[index] {
        case .card:
            let cell = CreditCardCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
            if let cardModel = wallet?.card {
                cell.configUI(with: cardModel)
            }

            cell.completion = {[weak self] status in
                self?.collectionView.isScrollEnabled = !status
                if status {
                    self?.timer?.invalidate()
                    self?.timer = nil
                    self?.updatePaymentMethod(to: .card)
                } else {
                    self?.startTimer()
                    self?.updatePaymentMethod(to: .none)
                }
            }
            cell.completionDeleteCard = {
                MILoader.hide()
                UIAlertController.showAction(title: "MOBILE_global_warning".localized(), message: "MOBILE_delete_own_card".localized(), actions: ("MOBILE_global_continue".localized(), .default, { [weak self] action in
                    MILoader.show()
                    self?.viewModel.deleteCard {[weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(_):
                            DispatchQueue.main.async {
                                self.fetchData()
                                self.loadPagerControll()
                            }
                            MILoader.hide()
                        case .failure(let error):
                            MILoader.hide()
                            UIAlertController.showError(message: error.localizedDescription)
                        }
                    }
                }), ("MOBILE_global_cancel".localized(), .default, {
                    action in
                    action.dismiss(animated: true, completion: nil)
                }))

            }
            return cell
        case .attachCard:
            let cell = AddCreditCardCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
            
            cell.minFreeLabel.text = "MOBILE_wallet_num_minutes_free".localized().replacingOccurrences(of: "[num]", with: "10")
            cell.completion = {[weak self] _ in
                self?.attachCard()
            }
            return cell

        case .iDram:
            let cell = IDramCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
            cell.completion = {[weak self] status in
                self?.collectionView.isScrollEnabled = !status
                if status {
                    self?.timer?.invalidate()
                    self?.timer = nil
                    self?.updatePaymentMethod(to: .iDram)
                } else {
                    self?.startTimer()
                    self?.updatePaymentMethod(to: .none)
                }
            }
            return cell
        case .tellCell:
            let cell = TelcellCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
            cell.delegate = self
            cell.userPhone = self.userPhone
            cell.changeCell(state: .close, animatable: false)
//            self.collectionView.transform = state == .open ? CGAffineTransform(scaleX: 0.3, y: 0.3) : .identity

            self.view.setNeedsLayout()
            return cell
            
        case .crypto:
            let cell: CryptoCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = arrayIndexForRow(indexPath.row)
        VibrateManager.vibrate()
        guard currentVisibleCollectionIndex == indexPath.row else {
            if let cell = collectionView.cellForItem(at: IndexPath(row: currentVisibleCollectionIndex, section: 0)) as? TelcellCollectionViewCell {
                cell.chooseUserPhoneTapped(cell)
            }
            return }
        switch collectionModel[index] {
        
        case .attachCard:
            attachCard()
        case .card: break
        case .iDram: break
        case .tellCell: break
        case .crypto: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isPageControllHidden  {
            setPageControllState(isHidden: false)
        }
        animationDispatchBerrier?.cancel()
        animationDispatchBerrier = DispatchWorkItem {
            self.setPageControllState(isHidden: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (UIView.areAnimationsEnabled ? 1 : 0), execute: animationDispatchBerrier!)

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        
        guard let currentPage = collectionView.indexPathForItem(at: scrollView.contentOffset) else { return }
        let index = arrayIndexForRow(currentPage.row)
        pagerControll.currentPage = arrayIndexForRow(currentPage.row)
        pagerControll2.currentPage = arrayIndexForRow(currentPage.row)

        print(currentPage)
        currentVisibleCollectionIndex = currentPage.row
        switch collectionModel[index] {
        case .attachCard:
            updatePaymentMethod(to: .deposit)
        case .card:
            updatePaymentMethod(to: .none)
        case .iDram:
            updatePaymentMethod(to: .none)
        case .tellCell:
            updatePaymentMethod(to: .none)
        case .crypto:
            updatePaymentMethod(to: .crypto)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.isUserInteractionEnabled = true 
    }
}

//-:FIXME Create phone number validator for tellCell phone number.

extension WalletViewController: TelcellCollectionViewCellDelegate {
    func didActivate(phone: String) {
        tellCellPhoneNumber = phone
    }
    

    func didChangeState(_ state: TelcellState, in cell: UICollectionViewCell) {
        if let tellCell = cell as? TelcellCollectionViewCell {
            let layout = collectionView.collectionViewLayout as! UPCarouselFlowLayout
            layout.invalidateLayoutOnFrameChange = false
            collectionView.bringSubviewToFront(tellCell)
            if state == .open {
                updatePaymentMethod(to: .tellCell(phone: tellCellPhoneNumber ?? ""))
                collectionView.isScrollEnabled = false
                tellCell.clipsToBounds = false
                collectionViewHeightConstraint.constant = 220
                tellCell.contextHeightConstant.constant = 220
                layout.invalidateLayoutOnFrameChange = false
                self.timer?.invalidate()
                self.timer = nil
                tellCell.frame = CGRect(x: tellCell.frame.origin.x,
                                        y: tellCell.frame.origin.y,
                                        width: tellCell.frame.width,
                                        height: 220)
                tellCell.layoutIfNeeded()
            } else {
                self.startTimer()
                updatePaymentMethod(to: .none)
                collectionView.isScrollEnabled = true
                tellCell.contextHeightConstant.constant = 156
                collectionViewHeightConstraint.constant = 156
                tellCell.frame = CGRect(x: tellCell.frame.origin.x,
                                        y: tellCell.frame.origin.y,
                                        width: tellCell.frame.width,
                                        height: 156)
                tellCell.layoutIfNeeded()
            }
            
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }) { _ in
                if state == .close {
                    tellCell.clipsToBounds = true
                    layout.invalidateLayoutOnFrameChange = true
                }
            }
        }
    }
    
    func pickFromContacts(state: TelcellState) {
        switch state {
        case .chooseNumber:
            UINavigationBar.appearance().setBackgroundImage(nil, for: UIBarMetrics.default)
            UINavigationBar.appearance().shadowImage = nil
            let contactPicker = CNContactPickerViewController()
            contactPicker.delegate = self
            contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumber.@count > 1")
            present(contactPicker, animated: true)
        default:
            break
        }
    }
}

extension WalletViewController: CNContactPickerDelegate {
  
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        VibrateManager.vibrate()
        guard let currentVisibleCell = self.collectionView.cellForItem(at: IndexPath(row: currentVisibleCollectionIndex, section: 0)) as? TelcellCollectionViewCell else {
            return
        }

        let newFriends = contact.phoneNumbers.first
        currentVisibleCell.changePhoneState(.contactPhone(phone: newFriends?.value.stringValue ?? ""))
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = UIImage()

    }
}

extension WalletViewController: AddCreditCardDelegate {
    
    func didSuccess() {
        navigationController?.popToViewController(self, animated: true)
        fetchData()
    }
    
    func didFailure(with error: Error) {
        navigationController?.popToViewController(self, animated: true)
        fetchData()
    }
}


extension WalletViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view!.isDescendant(of: touch.view!) {
            return true
        }
        return false
    }
}

extension WalletViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.promoCodeTF.resignFirstResponder()
        return true
    }
}
