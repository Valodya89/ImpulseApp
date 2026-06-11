//
//  NotificationListViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 8/7/21.
//

import UIKit

final class NotificationListViewController: BaseViewController, StoryboardInitializable, UITextViewDelegate {

    @IBOutlet weak var emptyTextLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var notificationViewModel = NotificationViewModel()
    var tableData: [NotificationListResponse] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emptyTextLbl.text = "MOBILE__empty_notification_list_message".localized()
        self.emptyTextLbl.isHidden = true
        self.titleLbl.text = "MOBILE_notifications_title".localized()
        // Do any additional setup after loading the view.
        navigationController?.navigationBar.isHidden = false
        self.title = "MOBILE_notifications_title".localized()
        tableView.isHidden = true
        tableView.rowHeight = 44
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotificationList()
    }
    
    private func getNotificationList() {
        MILoader.show()
        notificationViewModel.getNotificationsList({ notList in
            if let notList = notList {
                self.tableData = notList
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.isHidden = notList.count > 0 ? false : true
                }
            }
            
            DispatchQueue.main.async {
                MILoader.hide()
                self.emptyTextLbl.isHidden = !(notList ?? []).isEmpty
            }
        })
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension NotificationListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationListTableViewCell") as? NotificationListTableViewCell
        let locale = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        switch locale {
        case "en":
            cell?.titleLabel.text = tableData[indexPath.row].content?.en?.title
            cell?.descriptionLabel.attributedText = convertStringToAttributedString(text: tableData[indexPath.row].content?.en?.content ?? "")
        case "ru":
            cell?.titleLabel.text = tableData[indexPath.row].content?.ru?.title
            cell?.descriptionLabel.attributedText = convertStringToAttributedString(text: tableData[indexPath.row].content?.ru?.content ?? "")
        case "hy-AM", "hy":
            cell?.titleLabel.text = tableData[indexPath.row].content?.hy?.title
            cell?.descriptionLabel.attributedText = convertStringToAttributedString(text: tableData[indexPath.row].content?.hy?.content ?? "")
        default:
            break
        }
        cell?.descriptionLabel.delegate = self
        cell?.descriptionLabel.isUserInteractionEnabled = true
        UITextView.appearance().linkTextAttributes = [ .foregroundColor: UIColor.blue ]

        let date = Date(timeIntervalSince1970: (tableData[indexPath.row].date ?? 0.0) / 1000)
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "dd MMM YYYY hh:mm"

        let dateString = dayTimePeriodFormatter.string(from: date)
        cell?.dateLabel.text = dateString
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let locale = StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        var height: CGFloat = 0.0
        
        switch locale {
        case "en":
            height = (tableData[indexPath.row].content?.en?.content ?? "").height(constraintedWidth: self.view.frame.width - 40, font: UIFont.systemFont(ofSize: 18))
        case "ru":
            height = (tableData[indexPath.row].content?.ru?.content ?? "").height(constraintedWidth: self.view.frame.width - 40, font: UIFont.systemFont(ofSize: 18))
        case "hy-AM", "hy":
            height = (tableData[indexPath.row].content?.hy?.content ?? "").height(constraintedWidth: self.view.frame.width - 40, font: UIFont.systemFont(ofSize: 18))
        default:
            break
        }

        return  height + 110 //UITableView.automaticDimension
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

            print(URL)
        UIApplication.shared.canOpenURL(URL)
            //*** Set storyboard id same as VC name
//            self.navigationController!.pushViewController((self.storyboard?.instantiateViewController(withIdentifier: "TheLastViewController"))! as UIViewController, animated: true)

            return true
        }
    func convertStringToAttributedString(text: String) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 16)])
        
        for link in checkForUrls(text: text) {
            let str = link.absoluteString
            let nsRange = NSString(string: text).range(of: str, options: .caseInsensitive)
            
            if nsRange.location != NSNotFound {
                attributedString.addAttribute(.link, value: str, range: nsRange)
            }
        }
       
        
        return attributedString
    }
    
    func checkForUrls(text: String) -> [URL] {
        let types: NSTextCheckingResult.CheckingType = .link

        do {
            let detector = try NSDataDetector(types: types.rawValue)

            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
            return matches.compactMap({$0.url})
        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return []
    }
}


extension String {
func height(constraintedWidth width: CGFloat, font: UIFont) -> CGFloat {
    let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
    label.numberOfLines = 0
    label.text = self
    label.font = font
    label.sizeToFit()

    return label.frame.height
 }
}
