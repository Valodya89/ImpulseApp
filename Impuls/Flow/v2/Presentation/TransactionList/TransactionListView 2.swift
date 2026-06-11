//
//  TransactionListView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/26/25.
//

import SwiftUI
 
struct TransactionListView: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            transactionsListView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.evBgColor.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { navigationView() }
    }
    
    func transactionsListView() -> some View {
        Group {
            if viewModel.transactions.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(pinnedViews: .sectionHeaders) {
                        
                        ForEach(viewModel.transactions) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    transactionView(item)
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                HStack {
                                    Text(section.title)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(Color.evText9)
                                        .padding(.horizontal, 16)
                                        .background(Color.evBgColor)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    private func transactionView(_ item: TransactionDTO) -> some View {
        HStack(spacing: 0) {
            Image(item.type.isIncomeing ? "icon_transaction_income" : "icon_transaction_outcome")
                .frame(width: 29)
                .padding([.bottom, .top, .leading], 20)
                .padding(.trailing, 10)
            
            VStack(spacing: 8) {
                Text(item.type.isIncomeing ? "Income" : "Outcome")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.robotoMedium15)
                    .foregroundColor(.evText9)
                
                Text(DateFormatter.dayMonthFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(item.date))))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.evText6)
                    .font(.robotoRegular12)
            }
            
            Text("\(item.amount.description) \(item.currency)")
                .font(.robotoMedium15)
                .foregroundColor(.evText9)
                .padding(.trailing, 16)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(item.type.isIncomeing ? Color(hex: "#08BC05") : Color.evText6)
                .offset(x: -2)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    func navigationView() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("Transactions")
                    .font(.robotoBold15)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            Image(.icCloseBig)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(.leading, 18.5)
                .onTapGesture { dismiss() }
        }
        .background(Color.white)
    }
    
    var emptyDataView: some View {
        VStack(spacing: 8) {
            Image("ic_empty_data")
            
            Text("Begin your adventure!")
                .font(.robotoSemibold16)
                .foregroundColor(Color.black08)
            
            Text("Your History will show here once you’ve made your first Trip")
                .font(.robotoRegular15)
                .foregroundColor(Color.gray8)
       
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

