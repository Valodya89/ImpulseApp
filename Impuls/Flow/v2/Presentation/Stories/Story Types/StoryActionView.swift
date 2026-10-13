//
//  StoryActionView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 24.12.23.
//
//  The foreground of a LINK page: title, text and the call-to-action button.
//  The card draws the background and the touch layer underneath; the texts
//  let touches through so a tap anywhere but the button moves the story on.
//

import SwiftUI

struct StoryActionView: View {

    let page: StoryPage
    /// Opens the page's link (the CTA button).
    let onOpenLink: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hintRaised = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(page.title)
                .multilineTextAlignment(.center)
                .font(.robotoSemibold40)
                .foregroundColor(.alwaysWhite)
                .shadow(color: .alwaysBlack.opacity(0.3), radius: 3, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(page.content)
                .multilineTextAlignment(.center)
                .font(.robotoRegular20)
                .foregroundColor(.alwaysWhite.opacity(0.85))
                .shadow(color: .alwaysBlack.opacity(0.3), radius: 3, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            if page.linkURL != nil {
                // Swipe up opens the link too.
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.alwaysWhite.opacity(0.85))
                    .shadow(color: .alwaysBlack.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(y: hintRaised ? -4 : 0)
                    .padding(.bottom, 8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            hintRaised = true
                        }
                    }

                Button(action: onOpenLink) {
                    Text(buttonTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(MimoButton())
                .padding(.bottom, 16)
                .accessibilityIdentifier("storyLinkButton")
            }
        }
        .padding(.bottom, 74)
        // Room for the progress bars and the header: a long text or many
        // options shrink instead of running under them.
        .padding(.top, 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var buttonTitle: String {
        let name = page.urlButtonName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "MOBILE_story_open_link".localized(fallback: "Open link") : name
    }
}
