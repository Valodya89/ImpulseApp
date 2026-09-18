//
//  NotificationsWorker.swift
//  Impuls
//
//  Combine wrapper over the notification list endpoint the legacy
//  `NotificationViewModel` used, so the SwiftUI screen shares the same
//  request, response model and parsing.
//

import Combine
import Foundation

protocol NotificationsWorkerProtocol {
    func getNotifications() -> AnyPublisher<[NotificationListResponse], MimoError>
}

final class NotificationsWorker: NotificationsWorkerProtocol {

    private let network = SessionNetwork()

    func getNotifications() -> AnyPublisher<[NotificationListResponse], MimoError> {
        Deferred {
            Future<[NotificationListResponse], MimoError> { promise in
                self.network.request(with: URLBuilder(from: AuthAPI.getNotificationList)) { result in
                    switch result {
                    case .success(let data):
                        guard let response = MimoConverter<BaseResponseModel<[NotificationListResponse]>>.parseJson(data: data as Any) else {
                            promise(.failure(.init(error: .invalidParse("Can not parse notifications"))))
                            return
                        }

                        promise(.success(response.content ?? []))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
