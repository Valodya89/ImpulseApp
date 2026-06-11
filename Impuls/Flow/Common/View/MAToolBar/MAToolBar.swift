//
//  MAToolBar.swift
//  Management App
//
//  Created by Dose on 9/7/20.
//  Copyright © 2020 Doseh. All rights reserved.
//

import UIKit

final class MAToolBar: UIView {
    
    @IBOutlet weak var titleBarScrollView: UIScrollView!
    @IBOutlet weak var contentBarScrollView: UIScrollView!
    @IBOutlet weak var titleBarIndicatorView: UIView!
    
    @IBOutlet weak var indicatorViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var indicatorViewLeadingConstraint: NSLayoutConstraint!
    private weak var currentActiveTitleLabel: UILabel?
    private weak var currentActiveView: UIView?
    
    private(set) var titleBars: [String] = []
    private(set) var contentBars: [UIView] = []
    private var titleLabels: [UILabel] = []
    private var currentPage: Int = 0
    private var scrollTouchesDidEnd: (() -> ())? = nil
    private var isAvailableAnimation: Bool = false
    private var isAvailableContentAnimation: Bool = true
    private var indicatorFirstConstraint: CGFloat = 0.0
    
    
    var titleBarFont: (deActive: UIFont, active: UIFont) = (UIFont(name: "Roboto-Light", size: 17)!,UIFont(name: "Roboto", size: 17)!)
    var titleBarColor: (deActive: UIColor,active: UIColor) = (#colorLiteral(red: 0.4470588235, green: 0.4392156863, blue: 0.4392156863, alpha: 1), .black)
    
    var titleSpacing: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        loadFromNib()
    }
    
    func setup(titles: [String], bars: [UIView]) {
        self.titleBars = titles
        self.contentBars = bars
        setupTitleScrollView()
        setupContentScrollView()
        updateTitleScrollView(to: 0)
        if titles.count != bars.count {
            fatalError("Views count should be equal to titles count")
        }
        
        
    }
    
    private func setupTitleScrollView() {
        titleBarScrollView.delegate = self
        titleLabels = createTitles()
        
        let stackView = UIStackView(arrangedSubviews: titleLabels)
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = titleSpacing
        stackView.axis = .horizontal
        titleBarScrollView.addSubviewSizedConstraints(view: stackView)
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.centerXAnchor.constraint(equalTo: titleBarScrollView.centerXAnchor).isActive = true
        indicatorFirstConstraint = indicatorViewLeadingConstraint.constant
        
    }
    
    private func createTitles() -> [UILabel] {
        var labels: [UILabel] = []
        for i in 0 ..< titleBars.count {
            let label = UILabel()
            label.font = titleBarFont.deActive
            label.textColor = titleBarColor.deActive
            label.text = titleBars[i]
            labels.append(label)
            label.textAlignment = .center
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTouchTitle(_:))))
        }
        return labels
    }
    
    private func setupContentScrollView() {
        contentBarScrollView.delegate = self
        contentBarScrollView.isPagingEnabled = true
        for i in 0 ..< contentBars.count {
            contentBarScrollView.addSubview(contentBars[i])
            contentBars[i].translatesAutoresizingMaskIntoConstraints = false
            contentBars[i].topAnchor.constraint(equalTo: contentBarScrollView.topAnchor).isActive = true
            contentBars[i].bottomAnchor.constraint(equalTo: contentBarScrollView.bottomAnchor).isActive = true
            contentBars[i].widthAnchor.constraint(equalTo: contentBarScrollView.widthAnchor).isActive = true
            contentBars[i].heightAnchor.constraint(equalTo: contentBarScrollView.heightAnchor).isActive = true
            if i == 0 {
                contentBars[i].leadingAnchor.constraint(equalTo: contentBarScrollView.leadingAnchor).isActive = true
                continue
            }
            contentBars[i].leadingAnchor.constraint(equalTo: contentBars[i-1].trailingAnchor).isActive = true
            
            if i == contentBars.count - 1 {
                contentBars[i].trailingAnchor.constraint(equalTo: contentBarScrollView.trailingAnchor).isActive = true
            }
            contentBars[i].layoutIfNeeded()
        }
        
    }
    
    private func updateTitleScrollView(to page: Int) {
        currentActiveTitleLabel?.textColor = titleBarColor.deActive
        currentActiveTitleLabel?.font = titleBarFont.deActive

        titleLabels[page].textColor = titleBarColor.active
        titleLabels[page].font = titleBarFont.active

        currentActiveTitleLabel = titleLabels[page]
        currentActiveView = contentBars[page]
        titleBarScrollView.layoutIfNeeded()
        indicatorViewWidthConstraint.constant = titleBarScrollView.frame.width / 2
        indicatorViewLeadingConstraint.constant = titleLabels[page].frame.midX - indicatorViewWidthConstraint.constant / 2
        titleBarScrollView.setNeedsLayout()
        isAvailableAnimation = false
        UIView.animate(withDuration: 0.5, animations: {
            self.titleBarScrollView.layoutIfNeeded()
        }) { (_) in
            self.isAvailableAnimation = true
        }
    }
    
    func updateContentScrollView(to page: Int) {
        currentActiveTitleLabel?.textColor = titleBarColor.deActive
        currentActiveTitleLabel?.font = titleBarFont.deActive

        titleLabels[page].textColor = titleBarColor.active
        titleLabels[page].font = titleBarFont.active

        currentActiveTitleLabel = titleLabels[page]
        currentActiveView = contentBars[page]
        titleBarScrollView.layoutIfNeeded()
        indicatorViewWidthConstraint.constant = titleBarScrollView.frame.width / 2
        indicatorViewLeadingConstraint.constant = titleLabels[page].frame.midX - indicatorViewWidthConstraint.constant / 2
        
        titleBarScrollView.setNeedsLayout()
        isAvailableAnimation = false
        isAvailableContentAnimation = false
        contentBarScrollView.scrollRectToVisible(contentBars[page].frame, animated: true)

        UIView.animate(withDuration: 0.5, animations: {
            self.titleBarScrollView.layoutIfNeeded()
        }) { (_) in
            self.isAvailableAnimation = true
        }
    }
    
    @objc func didTouchTitle(_ gesture: UITapGestureRecognizer) {
        for i in 0..<titleLabels.count {
            if titleLabels[i] == gesture.view {
                updateContentScrollView(to: i)
            }
        }
    }
}

extension MAToolBar: UIScrollViewDelegate {
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.isAvailableContentAnimation = true
        self.isAvailableAnimation = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isAvailableContentAnimation = true
        self.isAvailableAnimation = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Calculation of current indicator position. 
   //     print((bubblesScrollView.frame.width / bubblesScrollView.contentSize.width) * (bubblesScrollView.contentOffset.x))
        if scrollView == contentBarScrollView {
            guard isAvailableContentAnimation else { return }
            let pageIndex = Int(round(scrollView.contentOffset.x/frame.width))
            guard currentPage != pageIndex else { return }
            currentPage = pageIndex
            updateTitleScrollView(to: pageIndex)
            
        }
    }
}

