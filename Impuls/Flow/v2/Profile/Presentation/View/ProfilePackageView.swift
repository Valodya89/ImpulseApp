//
//  ProfilePackageView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.04.24.
//

import SwiftUI

struct ProfilePackageView: View {
    
    let title: String
    let startDate: String
    let endDate: String
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MOBILE_rates_plans".localized())
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.black)
                        
                        Text(title.uppercased())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .resizable()
                        .foregroundColor(.black025)
                        .frame(width: 8, height: 14)
                        .font(.title.weight(.light))
                        .padding(.trailing, 12)
                }
                .frame(minHeight: 0, maxHeight: .infinity)
                .background(LinearGradient(colors: [.packageStart, .packageEnd], startPoint: .leading, endPoint: .trailing))
                
                ZStack(alignment: .leading) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MOBILE_global_start_date".localized())
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(startDate)
                                .font(.system(size: 12, weight: .light))
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MOBILE_global_end_date".localized())
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(endDate)
                                .font(.system(size: 12, weight: .light))
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 18)
                    .padding(.bottom, 22)
                    .frame(alignment: .leading)
                }
                .frame(minHeight: 0, maxHeight: .infinity)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
