//
//  RequirementFieldsView.swift
//  Impuls
//
//  Profile and address inputs a rule asks for. Only the listed fields are
//  shown; an address is always edited as a whole, because it is saved as one
//  object.
//

import SwiftUI

final class RequirementFieldsViewModel: ObservableObject {

    /// Impulse offers only male and female when picking; OTHER stays a known
    /// value so a profile that already has it still shows and saves it.
    enum Gender: String, CaseIterable {
        case male = "MALE"
        case female = "FEMALE"
        case other = "OTHER"

        var title: String {
            switch self {
            case .male: return "MOBILE_registartion_sex_bottom_sheet_male".localized(fallback: "Male")
            case .female: return "MOBILE_registartion_sex_bottom_sheet_female".localized(fallback: "Female")
            case .other: return "MOBILE_requirements_gender_other".localized(fallback: "Other")
            }
        }

        /// Pills offered for picking; OTHER only when it is the current value.
        static func offered(current: String) -> [Gender] {
            var offered: [Gender] = [.male, .female]
            if current == Gender.other.title {
                offered.append(.other)
            }
            return offered
        }
    }

    struct Country: Identifiable, Hashable {
        /// ISO 3166-1 alpha-3, as the backend names countries ("ARG").
        let code: String
        let name: String

        var id: String { code }
    }

    /// Inputs on screen, in form order.
    let fields: [RequirementField]
    /// Inputs that must be filled before saving.
    let required: Set<RequirementField>
    let title: String
    /// "Personal details" or "Address", above the inputs.
    let section: String

    @Published var name: String = ""
    @Published var surname: String = ""
    @Published var gender: String = ""
    @Published var birthday: Date?
    @Published var email: String = ""
    @Published var country: String = ""
    @Published var addressCountry: String = ""
    @Published var city: String = ""
    @Published var street: String = ""
    @Published var postalCode: String = ""

    @Published private(set) var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var saved: Bool = false

    let countries: [Country]

    private let service = RequirementsProfileService()
    private var profile: [String: Any] = [:]

    private static let birthdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    init(fields requested: [RequirementField], isAddress: Bool) {
        var required = Set(requested.filter { $0 != .document && $0 != .documentNumber })
        if isAddress, required.isEmpty {
            required = Set(RequirementField.addressFields)
        }

        var shown = required
        if !shown.isDisjoint(with: RequirementField.addressFields) {
            shown.formUnion(RequirementField.addressFields)
        }

        self.required = required
        self.fields = RequirementField.allCases.filter { shown.contains($0) }
        self.title = "MOBILE_requirements_title".localized(fallback: "Complete your profile")
        self.section = isAddress
            ? "MOBILE_requirements_section_address".localized(fallback: "Address")
            : "MOBILE_requirements_section_personal".localized(fallback: "Personal details")

        let language = StorageManager().fetch(key: .language, type: String.self) ?? Locale.current.identifier
        let locale = Locale(identifier: language)
        self.countries = Locale.isoRegionCodes
            .compactMap { region -> Country? in
                guard let code = CountryUtilities.getAlphaThreeCode(byAlpha2Code: region),
                      let name = locale.localizedString(forRegionCode: region) else { return nil }
                return Country(code: code, name: name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func load() {
        service.loadProfile { [weak self] profile in
            guard let self else { return }

            guard let profile else {
                self.errorMessage = "MOBILE_requirements_load_failed".localized(fallback: "Your profile could not be loaded. Check your connection and try again.")
                return
            }

            self.profile = profile
            let address = profile["address"] as? [String: Any] ?? [:]

            // Never overwrite what the rider has already typed.
            func fill(_ keyPath: ReferenceWritableKeyPath<RequirementFieldsViewModel, String>, _ value: Any?) {
                if self[keyPath: keyPath].isEmpty, let value = value as? String {
                    self[keyPath: keyPath] = value
                }
            }

            fill(\.name, profile["name"])
            fill(\.surname, profile["surname"])
            fill(\.email, profile["email"])
            fill(\.country, profile["country"])
            fill(\.addressCountry, address["country"])
            fill(\.city, address["city"])
            fill(\.street, address["street"])
            fill(\.postalCode, address["postalCode"])

            if self.gender.isEmpty, let value = profile["gender"] as? String,
               let gender = Gender(rawValue: value.uppercased()) {
                self.gender = gender.title
            }

            if self.birthday == nil, let value = profile["birthday"] as? String {
                self.birthday = Self.birthdayFormatter.date(from: value)
            }
        }
    }

    var isValid: Bool {
        required.allSatisfy { isFilled($0) }
    }

    /// Why the form cannot be saved yet, or nil when it can.
    var validationMessage: String? {
        if required.contains(.email), !email.trimmed.isEmpty, !isFilled(.email) {
            return "MOBILE_requirements_email_invalid".localized(fallback: "Enter a valid email address.")
        }

        let missing = fields.filter { required.contains($0) && !isFilled($0) }
        guard !missing.isEmpty else { return nil }

        if missing.count == 1, let field = missing.first {
            return field.title + ": " + "MOBILE_requirements_field_required".localized(fallback: "This field is required.")
        }

        return "MOBILE_requirements_fix_fields".localized(fallback: "Please check the highlighted fields.")
    }

    private func isFilled(_ field: RequirementField) -> Bool {
        switch field {
        case .name: return !name.trimmed.isEmpty
        case .surname: return !surname.trimmed.isEmpty
        case .gender: return !gender.isEmpty
        case .birthday: return birthday != nil
        case .email: return email.trimmed.contains("@") && email.trimmed.contains(".")
        case .country: return !country.isEmpty
        case .addressCountry: return !addressCountry.isEmpty
        case .city: return !city.trimmed.isEmpty
        case .street: return !street.trimmed.isEmpty
        case .postalCode: return !postalCode.trimmed.isEmpty
        case .document, .documentNumber: return true
        }
    }

    func save() {
        guard !isSaving else { return }

        if let validationMessage {
            errorMessage = validationMessage
            return
        }

        var body: [String: Any] = [:]

        // Name and surname go with every update, as on the other profile screens.
        let name = fields.contains(.name) ? self.name.trimmed : (profile["name"] as? String ?? "")
        let surname = fields.contains(.surname) ? self.surname.trimmed : (profile["surname"] as? String ?? "")
        if !name.isEmpty { body["name"] = name }
        if !surname.isEmpty { body["surname"] = surname }

        if fields.contains(.gender), let gender = Gender.allCases.first(where: { $0.title == self.gender }) {
            body["gender"] = gender.rawValue
        }

        if fields.contains(.birthday), let birthday {
            body["birthday"] = Self.birthdayFormatter.string(from: birthday)
        }

        if fields.contains(.email), !email.trimmed.isEmpty {
            body["email"] = email.trimmed
        }

        if fields.contains(.country), !country.isEmpty {
            body["country"] = country
        }

        if !Set(fields).isDisjoint(with: RequirementField.addressFields) {
            var address: [String: Any] = [:]
            if !addressCountry.isEmpty { address["country"] = addressCountry }
            if !city.trimmed.isEmpty { address["city"] = city.trimmed }
            if !street.trimmed.isEmpty { address["street"] = street.trimmed }
            if !postalCode.trimmed.isEmpty { address["postalCode"] = postalCode.trimmed }
            body["address"] = address
        }

        isSaving = true
        service.updateProfile(body) { [weak self] result in
            self?.isSaving = false

            switch result {
            case .success:
                NotificationCenter.default.post(name: Constant.Notifications.updateUserUI, object: nil)
                self?.saved = true
            case .failure(let error):
                self?.errorMessage = error.message
            }
        }
    }
}

struct RequirementFieldsView: View {

    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var viewModel: RequirementFieldsViewModel
    @State private var errorMessage: ErrorMessage?

    init(viewModel: RequirementFieldsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            RequirementScreenHeader(title: viewModel.title) {
                presentationMode.wrappedValue.dismiss()
            }

            ScrollView(.vertical) {
                VStack(spacing: 15) {
                    Text("MOBILE_requirements_subtitle".localized(fallback: "We need a few more details. It only takes a minute, and you will not be asked again."))
                        .font(.robotoRegular15)
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(viewModel.section)
                        .font(.robotoBold17)
                        .foregroundColor(.appLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(viewModel.fields, id: \.self) { field in
                        input(for: field)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            Button {
                viewModel.save()
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .onBrandLabel))
                } else {
                    Text("MOBILE_global_save".localized(fallback: "Save"))
                }
            }
            .buttonStyle(MimoButton(isEnabled: !viewModel.isSaving))
            .disabled(viewModel.isSaving)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color.grayBackground.ignoresSafeArea())
        .onAppear { viewModel.load() }
        .onReceive(viewModel.$saved) { saved in
            if saved { presentationMode.wrappedValue.dismiss() }
        }
        .onReceive(viewModel.$errorMessage) { message in
            if let message {
                errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: message)
            }
        }
        .swiftMessage(message: $errorMessage)
    }

    @ViewBuilder
    private func input(for field: RequirementField) -> some View {
        switch field {
        case .name:
            MimoTextField(title: field.title, placeholder: field.title, text: $viewModel.name)
        case .surname:
            MimoTextField(title: field.title, placeholder: field.title, text: $viewModel.surname)
        case .gender:
            MimoWheelPickerTextField(title: field.title,
                                     placeholder: field.title,
                                     items: RequirementFieldsViewModel.Gender.offered(current: viewModel.gender).map(\.title),
                                     selectedItem: $viewModel.gender)
        case .birthday:
            MimoDatePickerTextField(title: field.title, placeholder: field.title, date: $viewModel.birthday)
        case .email:
            MimoTextField(title: field.title, placeholder: field.title, text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        case .country:
            RequirementCountryField(title: field.title, countries: viewModel.countries, code: $viewModel.country)
        case .addressCountry:
            RequirementCountryField(title: field.title, countries: viewModel.countries, code: $viewModel.addressCountry)
        case .city:
            MimoTextField(title: field.title, placeholder: field.title, text: $viewModel.city)
        case .street:
            MimoTextField(title: field.title, placeholder: field.title, text: $viewModel.street)
        case .postalCode:
            MimoTextField(title: field.title, placeholder: field.title, text: $viewModel.postalCode)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
        case .document, .documentNumber:
            EmptyView()
        }
    }
}

struct RequirementScreenHeader: View {

    let title: String
    let close: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .resizable()
                        .foregroundColor(.appLabel)
                        .frame(width: 18, height: 18)
                        .padding(8)
                }

                Spacer()
            }
            .padding(.horizontal, 15)

            Text(title)
                .font(.robotoBold17)
                .foregroundColor(.appLabel)
        }
        .frame(height: 54)
        .background(Color.appBackground)
    }
}

private struct RequirementCountryField: View {

    let title: String
    let countries: [RequirementFieldsViewModel.Country]
    @Binding var code: String

    var body: some View {
        ZStack {
            Color.appBackground

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.robotoLight13)

                    Spacer()
                }

                Menu {
                    Picker(title, selection: $code) {
                        ForEach(countries) { country in
                            Text(country.name).tag(country.code)
                        }
                    }
                } label: {
                    HStack {
                        Text(countries.first(where: { $0.code == code })?.name ?? title)
                            .font(.robotoRegular17)
                            .foregroundColor(code.isEmpty ? .label05 : .label075)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .resizable()
                            .foregroundColor(.label05)
                            .frame(width: 12, height: 7)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appLabel, lineWidth: 0.5)
        )
        .frame(height: 63)
        .frame(maxWidth: .infinity)
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
