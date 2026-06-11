//
//  MimoSplashViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.08.23.
//

import UIKit
import Lottie
import Combine

class MimoSplashViewController: BaseViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var logoLottieView: LottieAnimationView!
    
    let viewModel: MimoSplashViewModel = Resolver.resolve()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addGradientAnimation(gradientView)
    }
    
    private func setupViewModel() {
        viewModel.$localizations
            .sink { [weak self] localizations in
                guard let self, localizations != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if self.viewModel.isAccountComplated {
                        LoginRouter.shared.showStartViewController(self)
                    } else {
                        LoginRouter.shared.showStartViewController(self)
                    }
                }
            }
            .store(in: &cancellables)
        
//        viewModel.loadData()
    }
    
    private func setupUI() {
        logoLottieView.animation = .named(Constant.Lottie.logo)
        logoLottieView.loopMode = .loop
        logoLottieView.play(fromProgress: logoLottieView.currentProgress, toProgress: 1, loopMode: .loop)
    }

}
