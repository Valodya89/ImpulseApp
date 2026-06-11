//
//  ErrorMessageView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.05.24.
//

import SwiftUI

struct ErrorMessageView: View {
    let message: ErrorMessage

    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .padding(.leading, 20)
            
            VStack(alignment: .leading) {
                Text(message.title).font(.system(size: 16, weight: .bold))
                Text(message.body).font(.system(size: 14, weight: .regular))
                    .lineLimit(2)
            }
            .multilineTextAlignment(.leading)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.errorRed)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(10)
    }
}

