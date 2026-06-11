//
//  WelcomeView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.09.23.
//

import SwiftUI

struct WelcomeView: View {
    
    @State var showLanguagesView = false
    var activeTrips: [AnyObject]
    var languages: [LanguageResult]
    
    var selectedLanguage: LanguageResult {
        return languages.first(where: { $0.isSelected }) ?? languages.first(where: { $0.id == "am" }) ?? languages.first ?? LanguageResult(id: "", name: "", flag: Data(), isSelected: false)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                WelcomePlayerView()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("MOBILE_global_welcome_title".localized())
                            .font(.robotoLight36)
                            .foregroundColor(.white)
                        Text("Импульс")
                            .font(.robotoBold36)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    Button {
                        showLanguagesView = true
                    } label: {
                        ZStack(alignment: .leading) {
                            HStack {
                                Text(selectedLanguage.name)
                                    .font(.robotoBold15)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                HStack {
                                    Image(uiImage: UIImage(data: selectedLanguage.flag) ?? UIImage())
                                        .resizable()
                                        .frame(width: 18, height: 12)
                                        .shadow(radius: 3)
                                    
                                    Image(systemName: "chevron.down")
                                        .resizable()
                                        .frame(width: 12, height: 6)
                                        .foregroundColor(.black025)
                                }
                            }
                            .padding(.horizontal, 22)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: LoginView(
                        viewModel: LoginViewModel(
                            locationManager: Resolver.resolve(),
                            activeTrips: activeTrips
                        )
                    )) {
                        Text("MOBILE_global_next".localized())
                    }
                    .buttonStyle(MimoButton())
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $showLanguagesView, content: {
                    LanguageView(languages: languages)
                })
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarTitle(Text(""), displayMode: .inline)
        .navigationBarHidden(true)
    }
}
