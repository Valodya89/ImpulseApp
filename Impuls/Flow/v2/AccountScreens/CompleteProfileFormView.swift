//
//  CompleteProfileFormView.swift
//  Impuls
//
//  The redesigned "edit profile" form. Purely presentational: every value is
//  written straight back into the storyboard fields of
//  `CompleteProfileViewController`, and every action calls the view
//  controller's existing method. The gender row focuses the legacy text field
//  so the *same* `PickerViewManager` wheel appears; the date-of-birth row
//  opens `MimoDateOfBirthSheet`.
//

import SwiftUI
import Kingfisher

/// Presentation state of the edit-profile form. It owns no rules: the
/// validator that decides whether Save is enabled is still the screen's
/// `CompleteAccountViewModel`, and this only renders what it reported.
final class CompleteProfileFormModel: ObservableObject {

    enum Field: Hashable {
        case name
        case surname
        case email
        case dateOfBirth
        case gender
    }

    @Published var name: String = ""
    @Published var surname: String = ""
    @Published var email: String = ""
    @Published var bio: String = ""
    @Published var gender: String = ""
    @Published var dateOfBirth: String = ""
    @Published var phone: String = ""
    @Published var avatar: UIImage?
    @Published var avatarURL: URL?
    @Published var isSaveEnabled: Bool = false

    /// Message from the screen's own validator, verbatim. Empty when valid.
    @Published var validationMessage: String = ""

    /// Fields the rider has already visited. Errors stay quiet until then, so a
    /// freshly opened form is not painted red.
    @Published var touched: Set<Field> = []

    // Wired by the view controller; the view never decides anything itself.
    var onEdit: () -> Void = {}
    var onPickDateOfBirth: () -> Void = {}
    var onPickGender: () -> Void = {}
    var onPickPhoto: () -> Void = {}
    var onSave: () -> Void = {}

    func markTouched(_ field: Field) {
        touched.insert(field)
    }

    /// Maps the validator's message onto the field it came from. The validator
    /// stops at the first failure, so at most one row is ever marked.
    func error(for field: Field) -> String? {
        guard touched.contains(field), !validationMessage.isEmpty else { return nil }

        switch validationMessage {
        case "First name can not be empty":
            return field == .name
                ? "MOBILE_validation_first_name_required".localized(fallback: "First name can not be empty")
                : nil

        case "Last name can not be empty":
            return field == .surname
                ? "MOBILE_validation_last_name_required".localized(fallback: "Last name can not be empty")
                : nil

        case "Can not contain space":
            // The validator checks the first name before the last name, so the
            // offending row is the first of the two that actually has a space.
            let offender: Field = name.contains(" ") ? .name : .surname
            return field == offender
                ? "MOBILE_validation_no_space".localized(fallback: "Can not contain space")
                : nil

        case "Invalid email address":
            return field == .email
                ? "MOBILE_validation_invalid_email".localized(fallback: "Invalid email address")
                : nil

        case "Please select date of birth":
            return field == .dateOfBirth
                ? "MOBILE_validation_dob_required".localized(fallback: "Please select date of birth")
                : nil

        case "Please select your sex":
            return field == .gender
                ? "MOBILE_validation_gender_required".localized(fallback: "Please select your gender")
                : nil

        default:
            return nil
        }
    }
}

struct CompleteProfileFormView: View {

    @ObservedObject var model: CompleteProfileFormModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                avatar

                VStack(spacing: 0) {
                    MimoFormTextRow(
                        title: "MOBILE_registartion_first_name".localized(),
                        placeholder: "MOBILE_registartion_first_name".localized(),
                        text: Binding(
                            get: { model.name },
                            set: { model.name = $0; model.markTouched(.name); model.onEdit() }
                        ),
                        error: model.error(for: .name)
                    )

                    MimoFormDivider()

                    MimoFormTextRow(
                        title: "MOBILE_registartion_last_name".localized(),
                        placeholder: "MOBILE_registartion_last_name".localized(),
                        text: Binding(
                            get: { model.surname },
                            set: { model.surname = $0; model.markTouched(.surname); model.onEdit() }
                        ),
                        error: model.error(for: .surname)
                    )

                    MimoFormDivider()

                    MimoFormTextRow(
                        title: "MOBILE_registartion_email".localized(),
                        placeholder: "MOBILE_registartion_email".localized(),
                        text: Binding(
                            get: { model.email },
                            set: { model.email = $0; model.markTouched(.email); model.onEdit() }
                        ),
                        keyboard: .emailAddress,
                        autocapitalization: .none,
                        error: model.error(for: .email)
                    )

                    MimoFormDivider()

                    MimoFormPickerRow(
                        title: "MOBILE_registartion_dob".localized(),
                        placeholder: "MOBILE_registartion_dob".localized(),
                        value: model.dateOfBirth,
                        glyph: "calendar",
                        error: model.error(for: .dateOfBirth)
                    ) {
                        model.markTouched(.dateOfBirth)
                        model.onPickDateOfBirth()
                    }

                    MimoFormDivider()

                    MimoFormPickerRow(
                        title: "MOBILE_registartion_sex".localized(),
                        placeholder: "MOBILE_registartion_sex".localized(),
                        value: model.gender,
                        error: model.error(for: .gender)
                    ) {
                        model.markTouched(.gender)
                        model.onPickGender()
                    }

                    MimoFormDivider()

                    MimoFormTextRow(
                        title: "MOBILE_registartion_bio".localized(),
                        placeholder: "MOBILE_registartion_bio".localized(),
                        text: Binding(
                            get: { model.bio },
                            set: { model.bio = $0; model.onEdit() }
                        ),
                        autocapitalization: .sentences
                    )

                    if !model.phone.isEmpty {
                        MimoFormDivider()

                        MimoFormStaticRow(
                            title: "MOBILE_sign_in_phone_number".localized()
                                .replacingOccurrences(of: "\n", with: ""),
                            value: model.phone
                        )
                    }
                }
                .mimoCard()

                Button {
                    VibrateManager.vibrate()
                    model.onSave()
                } label: {
                    Text("MOBILE_registartion_save_button".localized())
                }
                // Styled blocked, but still tappable: the storyboard `SaveButton`
                // only ever changed colour - it never stopped accepting taps, and
                // `saveTapped` re-validates. Disabling it here would refuse a
                // submit the screen used to allow.
                .buttonStyle(MimoButton(isEnabled: model.isSaveEnabled))
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color.appSecondaryBackground.ignoresSafeArea())
    }

    private var avatar: some View {
        Button {
            VibrateManager.vibrate()
            model.onPickPhoto()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let picked = model.avatar {
                        Image(uiImage: picked)
                            .resizable()
                            .scaledToFill()
                    } else if let url = model.avatarURL {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person")
                            .font(.system(size: 34, weight: .light))
                            .foregroundColor(.gray5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.appFill)
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.brandYellow, lineWidth: 2))

                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.onBrandLabel)
                    .frame(width: 30, height: 30)
                    .background(Color.brandYellow)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.appSecondaryBackground, lineWidth: 2))
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
}
