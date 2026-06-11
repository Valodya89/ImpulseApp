//
//  ImageField.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit
import AVKit

protocol ImageFieldDelegate: AnyObject {
    func didPickImage(imagePicker: ImageField, _ image: UIImage)
    func didDeleteImage(imagePicker: ImageField)
}


final class ImageField: UIView {

    private enum FieldState {
        case hasImage
        case closed
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var addPhotoButton: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var labelToSaveAreaBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageToSaveAreaBottomConstraint: NSLayoutConstraint!

    @IBInspectable var title: String = "Pick image" {
        didSet {
            titleLabel.text = title.localized()
        }
    }
    @IBInspectable var isQr: Bool = false {
        didSet {
            self.addPhotoButton.image = (isQr) ? #imageLiteral(resourceName: "ic_scan") : #imageLiteral(resourceName: "ic_add_photo")
        }
    }
    
    private var state: FieldState = .closed
    private var imagePickerController = UIImagePickerController()
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    weak var delegate: ImageFieldDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    private func commonInit() {
        loadFromNib()
        imagePickerController.delegate = self
        deleteImage()

        state = .closed
    }
    
    func setImage(_ image: UIImage) {
        contentImageView.isHidden = false
        contentImageView.image = image
        deleteButton.isHidden = false
        labelToSaveAreaBottomConstraint.priority = .init(990)
        imageToSaveAreaBottomConstraint.priority = .init(993)
        state = .hasImage
        delegate?.didPickImage(imagePicker: self, image)
    }
    
    func deleteImage() {
        contentImageView.isHidden = false
        contentImageView.image = nil
        deleteButton.isHidden = true
        labelToSaveAreaBottomConstraint.priority = .init(993)
        imageToSaveAreaBottomConstraint.priority = .init(990)
        state = .hasImage
        delegate?.didDeleteImage(imagePicker: self)
    }
    
    @IBAction func didTappInView() {
//        guard let rootController = window?.rootViewController else { return }
        UINavigationBar.appearance().setBackgroundImage(nil, for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = nil

        if isQr {
            let scannerViewController = UIStoryboard(name: "Scanner", bundle: nil).instantiateViewController(withIdentifier: "ScannerViewController") as? ScannerViewController
            scannerViewController?.qrImageResult = { [weak self] (qrImage) in
                self?.state = .hasImage
                self?.setImage(qrImage)
                scannerViewController?.dismiss(animated: true, completion: nil)
                UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                UINavigationBar.appearance().shadowImage = UIImage()
            }
            UIApplication.topController()?.present(scannerViewController!, animated: true, completion: nil)
            
            return
        }
        
        self.superview?.endEditing(true)
        UIApplication.topController()?.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func shouldDeleteImage(_ sender: UIButton) {
        
        deleteImage()
    }
}

extension ImageField: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerController.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        state = .hasImage
        setImage(image)
        imagePickerController.dismiss(animated: true, completion: nil)
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = UIImage()

    }
}
