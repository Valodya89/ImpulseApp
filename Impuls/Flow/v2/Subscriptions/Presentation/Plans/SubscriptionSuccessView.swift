//
//  SubscriptionSuccessView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import SwiftUI
import SwiftMessages

struct SubscriptionSuccessView: View {
    
    let message: SubscriptionSuccess
    
    var body: some View {
        ZStack {
            ZStack {
                VStack(spacing: 0) {
                    Image("subscription_success")
                        .resizable()
                        .frame(width: 100, height: 100, alignment: .center)
                        .padding(.top, 38)
                    
                    Text("MOBILE_subscriptions_success_title".localized())
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.gray8)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 32)
                    
                    Text("MOBILE_subscriptions_success_congratulations".localized())
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.gray8)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.top, 20)
                    
                    Text("MOBILE_subscriptions_success_description".localized().replacingOccurrences(of: "%@", with: message.name))
                        .foregroundColor(Color.gray9)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                    
                    Button {
                        message.action()
                    } label: {
                        ZStack {
                            Text("MOBILE_subscriptions_success_action_title".localized())
                                .foregroundColor(.black)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(Color.mimoYellow500))
                    }
                    .frame(height: 48)
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            .padding(.horizontal, 48)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}


struct SubscriptionSuccess: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let action: () -> Void
    
    static func == (lhs: SubscriptionSuccess, rhs: SubscriptionSuccess) -> Bool {
        lhs.id == rhs.id
    }
}

extension SubscriptionSuccess: MessageViewConvertible {
    func asMessageView() -> SubscriptionSuccessView {
        SubscriptionSuccessView(message: self)
    }
}
