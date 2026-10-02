//
//  SplashView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.09.23.
//

import SwiftUI

struct SplashView: View {

    @ObservedObject var viewModel: MimoSplashViewModel = Resolver.resolve()

    /// One full pass of the logo animation, so the splash leaves on the flat
    /// line at the end of a pass rather than cutting through the pulse. Cached
    /// texts can answer in a blink, and a splash that flickers past reads as a
    /// glitch rather than a welcome.
    private let minimumOnScreen: TimeInterval = 2.45

    /// False until the splash has been up long enough to be seen.
    @State private var splashWatched = false

    private var isReady: Bool { viewModel.translationsGot && splashWatched }

    init() {
        viewModel.loadData()
    }

    var body: some View {
        ZStack {
            if isReady {
                // A signed-in rider lands on Home even with an incomplete
                // profile: what is missing is asked for by the requirements
                // sheet when an action needs it, never at launch.
                if viewModel.isUserLoggedIn {
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
                ZStack {
                    LogoAnimationView()
                        .padding(.horizontal, 50)
                }
                .background(Color.alwaysWhite.edgesIgnoringSafeArea(.all))
                .transition(.opacity)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .animation(.easeInOut(duration: 0.35), value: isReady)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumOnScreen) {
                splashWatched = true
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
