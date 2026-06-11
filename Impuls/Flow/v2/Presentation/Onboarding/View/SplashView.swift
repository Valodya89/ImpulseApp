//
//  SplashView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.09.23.
//

import SwiftUI

struct SplashView: View {
    
    @ObservedObject var viewModel: MimoSplashViewModel = Resolver.resolve()
    
    init() {
        viewModel.loadData()
    }
    
    var body: some View {
        ZStack {
            if viewModel.translationsGot {
                if viewModel.isUserLoggedIn {
                    if viewModel.isAccountComplated {
                        HomeView(
                            homeViewModel: MimoHomeViewModel(
                                worker: Resolver.resolve(),
                                locationManager: Resolver.resolve(),
                                messageServicce: Resolver.resolve(),
                                activeTrips: viewModel.activeTrips ?? []
                            )
                        )
                    } else {
                        WelcomeView(activeTrips: viewModel.activeTrips ?? [], languages: viewModel.languages ?? [])
                    }
                } else {
                    WelcomeView(activeTrips: viewModel.activeTrips ?? [], languages: viewModel.languages ?? [])
                }
            } else {
                ZStack {
                    LogoAnimationView()
                        .padding(.horizontal, 50)
                }
                .background(Color(UIColor.mimoYellow500).edgesIgnoringSafeArea(.all))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
