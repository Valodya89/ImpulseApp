//
//  ViewController.swift
//  MimoBike
//
//  Created by Vardan on 27.05.21.
//

import UIKit

class ViewController: UIViewController, iCarouselDataSource, iCarouselDelegate, StoryboardInitializable {
    
    var items: [Int] = []

    @IBOutlet weak var iCarousel: iCarousel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for i in 0 ... 4 {
            items.append(i)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        iCarousel.type = .coverFlow2
        iCarousel.isVertical = true
        iCarousel.delegate = self
        iCarousel.dataSource = self
    }

    func numberOfItems(in carousel: iCarousel) -> Int {
        return items.count
    }

    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        var itemView: UIImageView

        //reuse view if available, otherwise create a new view
        if let view = view as? UIImageView {
            itemView = view
            //get a reference to the label in the recycled view
            label = itemView.viewWithTag(1) as! UILabel
        } else {
            //don't do anything specific to the index within
            //this `if ... else` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame: CGRect(x: 0, y: 0, width: 150, height: 250))
            itemView.image = UIImage(named: "Kim")
            itemView.contentMode = .scaleAspectFill

            label = UILabel(frame: itemView.bounds)
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.font = label.font.withSize(50)
            label.tag = 1
            itemView.addSubview(label)
        }

        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        label.text = "\(items[index])"

        return itemView
    }

    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 0.8
        }
        return value
    }

}

