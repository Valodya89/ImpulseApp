//
//  DocumentUploadView.swift
//  Impuls
//
//  Identity document upload for the DOCUMENT and DOCUMENT_NUMBER rules. Any
//  document type satisfies them, so the type is never blocked here; a provider
//  that accepts one type only (Getnet: DNI) is pointed out as a hint.
//

import SwiftUI
import UIKit

final class DocumentUploadViewModel: ObservableObject {

    enum Side: Identifiable {
        case front, back

        var id: Int { hashValue }
    }

    @Published var type: IdentityDocumentType = .idCard
    @Published var front: UIImage?
    @Published var back: UIImage?
    @Published var documentNumber: String = ""

    @Published private(set) var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var saved: Bool = false

    let requiresPhoto: Bool
    let requiresNumber: Bool
    /// Shown when the action's provider accepts an ID card only.
    let hint: String?

    private let service = RequirementsProfileService()

    init(fields: [RequirementField], check: EligibilityCheck?) {
        let asksNumber = fields.contains(.documentNumber)
        // With nothing listed the rule is about the document itself.
        requiresPhoto = fields.contains(.document) || !asksNumber
        requiresNumber = asksNumber

        if case .attachCard(let provider)? = check, provider == "GETNET" {
            hint = "MOBILE_requirements_document_getnet".localized(fallback: "Use your ID card (DNI). The card provider does not accept passports.")
        } else {
            hint = nil
        }
    }

    var isValid: Bool {
        (!requiresPhoto || front != nil)
            && (!requiresNumber || !documentNumber.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func set(image: UIImage, for side: Side) {
        switch side {
        case .front: front = image
        case .back: back = image
        }
    }

    func save() {
        guard isValid, !isSaving else { return }

        isSaving = true
        service.uploadDocument(type: type,
                               front: front,
                               back: back,
                               documentNumber: documentNumber.trimmingCharacters(in: .whitespaces)) { [weak self] result in
            self?.isSaving = false

            switch result {
            case .success:
                self?.saved = true
            case .failure(let error):
                self?.errorMessage = error.message
            }
        }
    }
}

struct DocumentUploadView: View {

    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var viewModel: DocumentUploadViewModel

    @State private var sourceSide: DocumentUploadViewModel.Side?
    @State private var picker: PickerRequest?
    @State private var errorMessage: ErrorMessage?

    init(viewModel: DocumentUploadViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private struct PickerRequest: Identifiable {
        let side: DocumentUploadViewModel.Side
        let source: UIImagePickerController.SourceType

        var id: String { "\(side.id)-\(source.rawValue)" }
    }

    var body: some View {
        VStack(spacing: 0) {
            RequirementScreenHeader(title: RequirementField.document.title) {
                presentationMode.wrappedValue.dismiss()
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("MOBILE_document_verify_subtitle".localized(fallback: "Scan your identity document. It only takes a minute."))
                        .font(.robotoRegular15)
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)

                    if let hint = viewModel.hint {
                        Text(hint)
                            .font(.robotoRegular13)
                            .foregroundColor(.appLabel)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellowTint)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Picker("", selection: $viewModel.type) {
                        ForEach(IdentityDocumentType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        photoTile(title: "MOBILE_document_id_front".localized(fallback: "Front of the ID card"),
                                  image: viewModel.front,
                                  side: .front)

                        photoTile(title: "MOBILE_document_id_back".localized(fallback: "Back of the ID card"),
                                  image: viewModel.back,
                                  side: .back)
                    }

                    Text("MOBILE_document_tip_flat".localized(fallback: "Place the document on a flat surface"))
                        .font(.robotoRegular13)
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)

                    MimoTextField(title: documentNumberTitle,
                                  placeholder: "MOBILE_document_number_placeholder".localized(fallback: "As printed on the document"),
                                  text: $viewModel.documentNumber)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
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
                    Text("MOBILE_global_submit".localized())
                }
            }
            .buttonStyle(MimoButton(isEnabled: viewModel.isValid && !viewModel.isSaving))
            .disabled(!viewModel.isValid || viewModel.isSaving)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color.grayBackground.ignoresSafeArea())
        .actionSheet(item: $sourceSide) { side in
            var buttons: [ActionSheet.Button] = []

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                buttons.append(.default(Text("MOBILE_document_scan_section".localized(fallback: "Scan your document"))) {
                    picker = PickerRequest(side: side, source: .camera)
                })
            }

            buttons.append(.default(Text("MOBILE_requirements_document_upload".localized(fallback: "Upload"))) {
                picker = PickerRequest(side: side, source: .photoLibrary)
            })
            buttons.append(.cancel())

            return ActionSheet(title: Text(RequirementField.document.title), buttons: buttons)
        }
        .fullScreenCover(item: $picker) { request in
            RequirementImagePicker(source: request.source) { image in
                viewModel.set(image: image, for: request.side)
            }
            .ignoresSafeArea()
        }
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

    /// "Document number", marked optional when the rules do not ask for it.
    private var documentNumberTitle: String {
        let title = "MOBILE_document_number".localized(fallback: "Document number")
        guard !viewModel.requiresNumber else { return title }

        return title + " (" + "MOBILE_document_optional".localized(fallback: "Optional") + ")"
    }

    private func photoTile(title: String, image: UIImage?, side: DocumentUploadViewModel.Side) -> some View {
        Button {
            sourceSide = side
        } label: {
            ZStack {
                Color.appBackground

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 22))
                            .foregroundColor(.appSecondaryLabel)

                        Text(title)
                            .font(.robotoRegular13)
                            .foregroundColor(.appSecondaryLabel)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appLabel, lineWidth: 0.5)
            )
        }
        .accessibility(label: Text(title))
    }
}

private struct RequirementImagePicker: UIViewControllerRepresentable {

    let source: UIImagePickerController.SourceType
    let picked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(picked: picked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = source
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        private let picked: (UIImage) -> Void

        init(picked: @escaping (UIImage) -> Void) {
            self.picked = picked
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                picked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
