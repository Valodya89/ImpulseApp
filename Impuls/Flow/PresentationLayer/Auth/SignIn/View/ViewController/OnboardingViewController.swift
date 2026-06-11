//
//  OnboardingViewController.swift
//  MimoBike
//
//  Created by Vardan on 22.04.21.
//

import UIKit

final class OnboardingViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - outlets

    @IBOutlet weak var initialNextView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var initialView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var nextButtonContentView: UIView!
    @IBOutlet weak var infoImg1: UIImageView!
    
    @IBOutlet var stepLabels: [UILabel]!
    
    var isPresentedHome = false
    
    //MARK: - Life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDelegates()
        configureUI()
    }

    /// configure delegates
    private func configureDelegates() {
        scrollView.delegate = self
    }
    
    /// configure user interface
    private func configureUI() {
        stepLabels.enumerated().forEach { (index, label) in
            label.text = "MOBILE_sign_in_step".localized().uppercased() + " " + (index + 1).description
        }
        initialNextView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        nextButtonContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        
        infoImg1.contentMode = .scaleAspectFit
        infoImg1.layer.masksToBounds = true
    }

    private func goToHomeVC() {
//        if isPresentedHome {
            self.dismiss(animated: true)
            
//            return
//        }
//        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
//        homeVC.state = .smallBottomSheet
//        let navVC = UINavigationController(rootViewController: homeVC)
//        setRootViewController(navVC)
        
//        HomeRouter.shared.showHomeViewController()
        
    }
    
    //MARk: - Actions
    
    @IBAction func skeepAction(_ sender: UIButton) {
//        navigationController?.popViewController(animated: true)
        self.dismiss(animated: true)
    }
    
    @IBAction func pageControlSelectionAction(_ sender: UIPageControl) {
        let page: Int? = sender.currentPage
        var frame: CGRect = self.scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page ?? 0)
        frame.origin.y = 0
        self.scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        guard pageControl.currentPage != 6 else {
            if navigationController?.viewControllers[0] is MapViewController {
                navigationController?.popToRootViewController(animated: true)
                return 
            }
            goToHomeVC()
            return
        }
        let multiplier = pageControl.currentPage + 1
        
        scrollView.contentOffset.x = CGFloat(multiplier) * scrollView.frame.width
    }
    
    @IBAction func initialNextTapped(_ sender: Any) {
        initialView.isHidden = true
    }
}


//MARK: - scroll view extension

extension OnboardingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let pageFraction = scrollView.contentOffset.x / pageWidth
        pageControl.currentPage = Int(round(pageFraction))
    }
}
