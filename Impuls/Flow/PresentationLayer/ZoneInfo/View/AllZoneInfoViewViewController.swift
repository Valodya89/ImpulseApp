//
//  AllZoneInfoViewViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 21.01.23.
//

import UIKit

protocol AllZoneInfoViewViewControllerDelegate: AnyObject {
    func didSelectOkay()
}

class AllZoneInfoViewViewController: UIViewController {

    @IBOutlet weak var zoneTableView: UITableView!
    @IBOutlet weak var okayButton: UIButton!
    
    weak var delegate: AllZoneInfoViewViewControllerDelegate?
    
    var clickedZone: String = ""
    
    private var homeRepository = HomeRepository()
    private var zoneInfoList: [ZoneInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        getZoneInfos()
    }

    func setupUI() {
        zoneTableView.delegate = self
        zoneTableView.dataSource = self
        
        self.okayButton.layer.cornerRadius = self.okayButton.frame.height / 2
    }
    
    
    func getZoneInfos() {
        homeRepository.getZoneInfo { result in
            
            switch result {
            case .success(let zoneInfoList):
                self.zoneInfoList = zoneInfoList
                if self.clickedZone.count > 0 {
                    self.zoneInfoList = zoneInfoList.filter({$0.id == self.clickedZone})
                }
                if self.clickedZone.count == 0 {
                    self.zoneInfoList.insert(ZoneInfo(id: "Parking", title: "MOBILE_parking_zone".localized(), description: ""), at: 0)
                }
                self.zoneTableView.reloadData()
            case .failure(let error):
                switch error {
                case .invalidParse(let message):
                    print(message)
                case .responseError(let message):
                    print(message)
                case  .validatorError(let message):
                    print(message)
                case .serverError:
                    print("Server Error")
                    
                case .tooFar(let message):
                    print(message)
                }
            }
        }
    }
    
    @IBAction func okayButtonAction(_ sender: UIButton) {
//        guard let delegate = delegate else {  return }
//        delegate.didSelectOkay()
        
        self.dismiss(animated: true)
    }

}

extension AllZoneInfoViewViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.clickedZone.count > 0 {
            return 1
        }
        return self.zoneInfoList.count ==  0 ? 3 : self.zoneInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZoneInfoCell", for: indexPath) as? ZoneInfoCell
        if  self.zoneInfoList.count > 0 {
            cell?.setData(zoneeInfo: self.zoneInfoList[indexPath.row])
        }
//        if self.clickedZone.count > 0 {
//            cell?.titleLable.text = self.clickedZone
//        }
        return cell!
    }
    
}
