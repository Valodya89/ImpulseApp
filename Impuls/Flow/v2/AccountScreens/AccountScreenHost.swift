//
//  AccountScreenHost.swift
//  Impuls
//
//  Bridge used by the account screens while they are migrated from their
//  storyboards to SwiftUI.
//
//  The storyboard scenes stay exactly as they are: every `@IBOutlet` the scene
//  connects is still there (removing one crashes at load), the view models,
//  delegates and `@IBAction`s are untouched. What changes is only what the
//  rider sees - the legacy hierarchy is faded out and a `UIHostingController`
//  is pinned over it.
//
//  Why `alpha` and not `isHidden`: a hidden view cannot become first responder,
//  and these screens keep driving the *existing* keyboards and pickers
//  (`DatePickerManager`, `PickerViewManager`) by focusing the legacy text field
//  behind the SwiftUI skin. Fading keeps that working while making the old
//  layout invisible; the hosting view sits on top with an opaque background,
//  so no touch ever reaches the faded controls.
//

import UIKit
import SwiftUI

extension UIViewController {

    /// Fades out the legacy storyboard content and pins a SwiftUI host over the
    /// whole view.
    ///
    /// - Parameters:
    ///   - content: the SwiftUI screen that replaces the storyboard layout.
    ///   - legacyRoots: the storyboard containers to fade. Pass the outermost
    ///     ones; their subviews come along. They are *not* hidden and *not*
    ///     removed, so outlets, constraints and first-responder behaviour stay
    ///     intact.
    @discardableResult
    func installAccountScreenHost<Content: View>(_ content: Content,
                                                 hiding legacyRoots: [UIView?]) -> UIHostingController<Content> {
        for root in legacyRoots {
            root?.alpha = 0
        }

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = UIColor(named: "AppSecondaryBackground")
        host.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(host)
        view.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        host.didMove(toParent: self)

        return host
    }
}
