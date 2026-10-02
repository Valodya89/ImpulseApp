//
//  TransferRecipientCardView.swift
//  Impuls
//
//  Who the money is going to: avatar, name and phone number. Used as the
//  card at the top of the amount step and as a row in the recent-recipients
//  list (compact size).
//

import SwiftUI
import Kingfisher

struct TransferRecipientCardView: View {

    let recipient: TransferRecipient
    var size: CGFloat = 56

    var body: some View {
        HStack(spacing: 14) {
            TransferAvatarView(url: recipient.avatarURL, size: size)

            VStack(alignment: .leading, spacing: 3) {
                Text(recipient.displayName)
                    .font(size >= 48 ? .robotoBold17 : .robotoMedium15)
                    .foregroundColor(.appLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let phone = recipient.displayPhone {
                    Text(phone)
                        .font(.robotoRegular13)
                        .foregroundColor(.gray5)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

/// Circular avatar with a brand ring; falls back to a neutral glyph when the
/// recipient has no picture.
struct TransferAvatarView: View {

    let url: URL?
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let url = url {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person")
                    .font(.system(size: size * 0.42, weight: .light))
                    .foregroundColor(.gray5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appFill)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.brandYellow, lineWidth: size >= 48 ? 2 : 1.5))
    }
}
