//
//  SubscriptionCancelView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 29.06.24.
//

import SwiftUI
import SwiftMessages

struct SubscriptionCancelView: View {
    
    var message: SubscriptionCancel
    
    var body: some View {
        ZStack {
            ZStack {
                VStack(spacing: 0) {
                    Image("subscription_cancel")
                        .resizable()
                        .frame(width: 100, height: 100, alignment: .center)
                        .padding(.top, 38)
                    
                    Text("MOBILE_subscriptions_cancel_title".localized())
                        .foregroundColor(Color.gray8)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 32)
                    
                    Text("MOBILE_subscriptions_cancel_description".localized())
                        .foregroundColor(Color.gray6)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                    
                    Button {
                        message.keepAction()
                    } label: {
                        ZStack {
                            Text("MOBILE_subscriptions_cancel_keep_action_title".localized())
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 24).fill(Color.mimoYellow500))
                    }
                    .frame(height: 48)
                    .padding(.top, 32)
                    
                    Button {
                        message.cancelAction()
                    } label: {
                        ZStack {
                            Text("MOBILE_subscriptions_cancel_action_title".localized())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray8)
                        }
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().stroke(Color.gray8, lineWidth: 1))
                    }
                    .padding(.top, 12)
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

struct SubscriptionCancel: Identifiable, Equatable {
    var id: String
    let keepAction: () -> Void
    let cancelAction: () -> Void
    
    static func == (lhs: SubscriptionCancel, rhs: SubscriptionCancel) -> Bool {
        lhs.id == rhs.id
    }
}

extension SubscriptionCancel: MessageViewConvertible {
    func asMessageView() -> SubscriptionCancelView {
        SubscriptionCancelView(message: self)
    }
}
