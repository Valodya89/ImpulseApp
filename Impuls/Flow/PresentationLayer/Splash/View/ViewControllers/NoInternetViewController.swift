//
//  NoInternetViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 02.07.22.
//

import UIKit

class NoInternetViewController: BaseViewController, StoryboardInitializable {

    @IBOutlet weak var wifi: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func tryAgain(_ sender: UIButton) {
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
//            let splashVC = SplashViewController.initFromStoryboard(name: Constant.Storyboards.splash)
//            setRootViewController(splashVC)
            BaseRouter.shared.showSplashView()
        }else{
            print("Internet Connection not Available!")
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.07
            animation.repeatCount = 4
            animation.autoreverses = true
            animation.fromValue = NSValue(cgPoint: CGPoint(x: wifi.center.x - 10, y: wifi.center.y))
            animation.toValue = NSValue(cgPoint: CGPoint(x: wifi.center.x + 10, y: wifi.center.y))

            wifi.layer.add(animation, forKey: "position")
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
