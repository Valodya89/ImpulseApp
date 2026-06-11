//
//  LanguageView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.10.23.
//

import SwiftUI

struct LanguageView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    private var selectedColor: Color = Color(red: 0.26, green: 0.63, blue: 0.28)
    
    private var languages: [LanguageResult]
    
    init(languages: [LanguageResult]) {
        self.languages = languages
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 18, height: 18)
                            .padding(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 15)
                
                Text("Language")
                    .font(.robotoBold17)
                    .foregroundColor(.black)
            }
            .frame(height: 54)
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(languages, id: \.id) { language in
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(uiImage: UIImage(data: language.flag) ?? UIImage())
                                    .resizable()
                                    .frame(width: 30, height: 20)
                                    .shadow(radius: 3)
                                
                                Text(language.name)
                                    .font(.robotoMedium17)
                                    .foregroundColor(language.isSelected ? selectedColor : .black075)
                                
                                Spacer()
                                
                                if language.isSelected {
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(selectedColor)
                                }
                            }
                            .frame(height: 64)
                            
                            Divider()
                        }
                        .background(Color.white)
                        .onTapGesture {
                            StorageManager().store(language.id, key: .language)
                            BaseRouter.shared.showSplashView()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
