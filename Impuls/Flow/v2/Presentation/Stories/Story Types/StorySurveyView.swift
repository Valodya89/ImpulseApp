//
//  StorySurveyView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 24.12.23.
//
//  The foreground of a QUESTIONNAIRE page: title, text and the options.
//  Answers are kept per story and page; tapping a chosen option deselects it,
//  tapping another adds it, and the page's whole list is sent each time.
//  Choosing does not move the story on - the page keeps playing.
//

import SwiftUI

struct StorySurveyView: View {

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    let storyId: String
    let page: StoryPage
    @ObservedObject var viewModel: StoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(page.title)
                .multilineTextAlignment(.center)
                .font(.robotoSemibold40)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .foregroundColor(.alwaysWhite)
                .shadow(color: .alwaysBlack.opacity(0.3), radius: 3, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
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

            if page.options.count > 3 {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(page.options, id: \.self) { option in
                        optionButton(option, alignment: .center)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            } else {
                VStack(spacing: 16) {
                    ForEach(page.options, id: \.self) { option in
                        optionButton(option, alignment: .leading)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
                // A frosted plate on the media; stays light-on-media in both modes.
                .background(Color.alwaysWhite.opacity(0.3))
                .cornerRadius(32)
                .padding(.bottom, 24)
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 74)
        // Room for the progress bars and the header: a long text or many
        // options shrink instead of running under them.
        .padding(.top, 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func optionButton(_ option: String, alignment: Alignment) -> some View {
        let isSelected = viewModel.isOptionSelected(option, storyId: storyId, pageNumber: page.number)

        return Button {
            let nowSelected = viewModel.toggle(option: option, storyId: storyId, pageNumber: page.number)
            MimoFeedback.shared.impactLight()
            if nowSelected {
                StoryAnalytics.optionSelect(storyId: storyId, pageNumber: page.number)
            }
        } label: {
            HStack(spacing: 8) {
                Text(option)
                    .font(.robotoMedium16)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: alignment)

                if isSelected, alignment == .leading {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            // On the media in both appearances: a white pill with dark text,
            // yellow with the on-brand text once chosen.
            .foregroundColor(isSelected ? Color.onBrandLabel : Color.black075)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 42)
            .background(isSelected ? Color.brandYellow : Color.alwaysWhite)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
