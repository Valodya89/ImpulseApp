//
//  MimoRefreshable.swift
//  Impuls
//
//  SwiftUI side of pull-to-refresh. iOS 15's `.refreshable` only works on List
//  and cannot show a custom indicator, so we reach the UIScrollView behind the
//  SwiftUI ScrollView and hand it a `MimoRefreshControl`:
//
//      ScrollView {
//          VStack {
//              ...
//          }
//          .mimoRefreshable { done in
//              viewModel.reload { done(true) }
//          }
//      }
//
//  Apply it to the ScrollView's CONTENT, not to the ScrollView itself - the
//  same rule as `mimoScrollEnabled`. A background of the content is mounted
//  inside the scroll view, so walking up the superview chain is guaranteed to
//  reach it and reach no other. A background of the ScrollView is mounted as
//  its *sibling*, which leaves nothing to do but guess downwards through
//  SwiftUI's private hierarchy - and on a screen that stacks several scroll
//  views, such as the home hub and its fast-decision sheet, the guess can land
//  on the wrong one.
//

import SwiftUI
import UIKit

extension View {
    /// Adds the branded pull-to-refresh to the ScrollView this content sits in.
    /// The action receives a completion; call it with `true` when the data is
    /// back (or `false` to end with an error haptic).
    func mimoRefreshable(action: @escaping (_ done: @escaping (Bool) -> Void) -> Void) -> some View {
        background(
            ScrollViewRefreshInstaller(action: action)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        )
    }
}

private struct ScrollViewRefreshInstaller: UIViewRepresentable {

    let action: (_ done: @escaping (Bool) -> Void) -> Void

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        uiView.control.onRefresh = { completion in action(completion) }
        // Re-applied on every update rather than only the first: SwiftUI owns
        // the scroll view and may hand us a different one after a rebuild.
        uiView.attach()
    }

    static func dismantleUIView(_ uiView: InstallerView, coordinator: ()) {
        uiView.control.detach()
    }

    final class InstallerView: UIView {

        let control = MimoRefreshControl()

        override func didMoveToWindow() {
            super.didMoveToWindow()
            attach()
        }

        func attach() {
            guard let scrollView = enclosingScrollView() else {
                // SwiftUI can mount a background before the scroll view is in
                // the tree; try again once this run loop has laid things out.
                DispatchQueue.main.async { [weak self] in
                    guard let self, let scrollView = self.enclosingScrollView() else { return }
                    self.control.attach(to: scrollView)
                }
                return
            }
            control.attach(to: scrollView)
        }

        /// Straight up the superview chain. We are mounted inside the scroll
        /// view's content, so the first UIScrollView above us is the one this
        /// content scrolls in - no searching, and never a neighbour's.
        private func enclosingScrollView() -> UIScrollView? {
            var view: UIView? = superview
            while let current = view {
                if let scrollView = current as? UIScrollView { return scrollView }
                view = current.superview
            }
            return nil
        }
    }
}
