//
//  NotificationViewModel.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 11.08.21.
//

import UIKit

class NotificationViewModel: NSObject {

    private let network = SessionNetwork()

    func getNotificationsList(_ complation: @escaping ([NotificationListResponse]?) -> Void) {
        DispatchQueue.global().async {
            self.network.request(with: URLBuilder(from: AuthAPI.getNotificationList)) { ressult in
                DispatchQueue.main.async {
                    switch ressult {
                    
                    case .success(let data):
                        guard let notificationsList = MimoConverter<BaseResponseModel<[NotificationListResponse]>>.parseJson(data: data as Any) else {
                            complation(nil)
                            return
                        }
                        
                        complation(notificationsList.content)
                    case .failure(let error):
                        print(error)
                        complation(nil)
                        break
                    }
                }
            }
        }
    }
}
