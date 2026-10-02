//
//  RequirementsView.swift
//  Impuls
//
//  The checklist shown when an action is held back by unmet rules: every
//  failing rule as context, one button for the first rule's screen.
//

import SwiftUI

final class RequirementsViewModel: ObservableObject {

    @Published var violations: [EligibilityViolation]
    /// True while the rules are being re-read after the rider came back.
    @Published var isChecking: Bool = false
    /// True when the last re-check could not be read; cleared on the next one.
    @Published var checkFailed: Bool = false
    /// What the rider was about to do, e.g. "To start a bike ride".
    @Published var purpose: String

    var primaryAction: () -> Void = {}
    var close: () -> Void = {}

    init(violations: [EligibilityViolation], purpose: String) {
        self.violations = violations
        self.purpose = purpose
    }
}

struct RequirementsView: View {

    @ObservedObject var viewModel: RequirementsViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.violations.enumerated()), id: \.offset) { index, violation in
                        RequirementRow(violation: violation, isPrimary: index == 0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }

            if viewModel.checkFailed {
                Text("MOBILE_requirements_check_failed".localized(fallback: "We could not check again. Try once more."))
                    .font(.robotoRegular13)
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }

            if let primary = viewModel.violations.first {
                Button {
                    viewModel.primaryAction()
                } label: {
                    if viewModel.isChecking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .onBrandLabel))
                    } else {
                        Text(primary.actionTitle)
                    }
                }
                .buttonStyle(MimoButton(isEnabled: !viewModel.isChecking))
                .disabled(viewModel.isChecking)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
        .background(Color.appSecondaryBackground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                HStack {
                    Spacer()

                    Button {
                        viewModel.close()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.appLabel)
                            .frame(width: 16, height: 16)
                            .padding(10)
                    }
                }
                .padding(.horizontal, 10)

                Text("MOBILE_requirements_checklist_title".localized(fallback: "Before you continue"))
                    .font(.robotoBold17)
                    .foregroundColor(.appLabel)
            }
            .frame(height: 54)

            Text(viewModel.purpose)
                .font(.robotoMedium15)
                .foregroundColor(.appLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text("MOBILE_requirements_checklist_subtitle".localized(fallback: "A few things need your attention first."))
                .font(.robotoRegular15)
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        }
    }
}

private struct RequirementRow: View {

    let violation: EligibilityViolation
    let isPrimary: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: violation.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isPrimary ? .onBrandLabel : .appSecondaryLabel)
                .frame(width: 36, height: 36)
                .background(isPrimary ? Color.brandYellow : Color.appFill)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(violation.message)
                    .font(.robotoMedium15)
                    .foregroundColor(.appLabel)
                    .fixedSize(horizontal: false, vertical: true)

                if let details = violation.detailsLine {
                    Text(details)
                        .font(.robotoRegular13)
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
