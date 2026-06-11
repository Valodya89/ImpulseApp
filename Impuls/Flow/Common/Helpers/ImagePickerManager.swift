//
//  ImagePickerManager.swift
//  MimoBike
//
//  Created by Vardan on 05.05.21.
//

import Foundation
import UIKit

public protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
}

final class ImagePickerManager: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(pickerController, animated: true)
        }
    }

    public func present(from sourceView: UIView) {

        var alertStyle = UIAlertController.Style.actionSheet
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: alertStyle)

        if let action = self.action(for: .camera, title: "MOBILE_registartion_photo_bottom_sheet_take_photo".localized()) {
            alertController.addAction(action)
        }
        
        if let action = self.action(for: .photoLibrary, title: "MOBILE_registartion_photo_bottom_sheet_choose_from_library".localized()) {
            
            alertController.addAction(action)
        }

        alertController.view.tintColor = .mimoBlackWith075alpha
        alertController.addAction(UIAlertAction(title: "MOBILE_global_cancel".localized(), style: .cancel, handler: nil))
        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        VibrateManager.vibrate()
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }
}

extension ImagePickerManager: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return pickerController(picker, didSelect: nil)
        }
        pickerController(picker, didSelect: image)
    }
}

extension ImagePickerManager: UINavigationControllerDelegate {
    
}
