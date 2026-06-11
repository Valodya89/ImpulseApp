//
//  ParkingPhotoView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.05.24.
//

import SwiftUI
import SwiftMessages

struct ParkingPhotoView: View {
    
    @ObservedObject var viewModel: ParkingPhotoViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State var errorMessage: ErrorMessage?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    CameraView(image: $viewModel.viewfinderImage)
                    
                    LinearGradient(colors: [.black.opacity(0.45), .black2.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    
                    if !viewModel.isAuthorized {
                        VStack(spacing: 30) {
                            Text("MOBILE__global_camera_access".localized())
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                            } label: {
                                Text("MOBILE_global_settings".localized())
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.brandYellow)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, -20)
                .overlay(
                    Text("SCOOTER_global_parking_photo".localized())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.top, 48)
                    , alignment: .top
                )
                
                ZStack {
                    VStack(spacing: 24) {
                        Text("SCOOTER_global_send_photo_info".localized() + " " + "SCOOTER_global_correct_photo".localized())
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(10)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        
                        if viewModel.isRunning {
                            ZStack {
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        viewModel.switchFlashLight()
                                    } label: {
                                        if viewModel.isFlashOn {
                                            Image(systemName: "flashlight.on.circle.fill")
                                                .resizable()
                                                .foregroundColor(.white)
                                                .frame(width: 42, height: 42)
                                        } else {
                                            Image(systemName: "flashlight.off.circle.fill")
                                                .resizable()
                                                .foregroundColor(.white)
                                                .frame(width: 42, height: 42)
                                        }
                                    }
                                    .disabled(!viewModel.isAuthorized)
                                    .opacity(viewModel.isAuthorized ? 1 : 0.6)
                                }
                                .padding(.horizontal, 32)
                                
                                ZStack {
                                    Button {
                                        viewModel.camera.takePhoto()
                                        viewModel.stop()
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .padding(4)
                                        }
                                    }
                                    .disabled(!viewModel.isAuthorized)
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.9), lineWidth: 3)
                                )
                                .opacity(viewModel.isAuthorized ? 1 : 0.6)
                            }
                            .padding(.bottom, 20)
                        } else {
                            ZStack {
                                HStack(spacing: 20) {
                                    Button {
                                        viewModel.start()
                                    } label: {
                                        ZStack {
                                            Color.white
                                            HStack(spacing: 12) {
                                                Image(systemName: "return")
                                                    .resizable()
                                                    .frame(width: 18, height: 14)
                                                    .foregroundColor(.gray9)
                                                    .font(Font.title.weight(.medium))
                                                
                                                Text("SCOOTER_global_retake_photo".localized())
                                                    .lineLimit(2)
                                                    .minimumScaleFactor(0.5)
                                                    .font(.system(size: 17, weight: .medium))
                                                    .foregroundColor(.gray9)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.leading, 20)
                                            .padding(.trailing, 8)
                                        }
                                        .clipShape(Capsule())
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Button {
                                        MILoader.show()
                                        viewModel.finishTrip()
                                    } label: {
                                        ZStack {
                                            Color.white
                                            HStack(spacing: 12) {
                                                Image(systemName: "camera")
                                                    .resizable()
                                                    .frame(width: 20, height: 16)
                                                    .foregroundColor(.gray9)
                                                    .font(Font.title.weight(.medium))
                                                
                                                Text("SCOOTER_global_send_a_photo".localized())
                                                    .lineLimit(2)
                                                    .minimumScaleFactor(0.5)
                                                    .font(.system(size: 17, weight: .medium))
                                                    .foregroundColor(.gray9)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.leading, 20)
                                            .padding(.trailing, 8)
                                        }
                                        .clipShape(Capsule())
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 6)
                            }
                            .frame(height: 64)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .background(Color.black2)
                .cornerRadius(20, corners: [.topLeft, .topRight])
            }
        }
        .background(Color.black2.ignoresSafeArea(edges: .bottom))
        .overlay(
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                ZStack {
                    Image(systemName: "xmark")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                }
                .frame(width: 24, height: 24)
                    
            })
            .padding(.leading, 20)
            .padding(.top, 16)
            , alignment: .topLeading
        )
        .onReceive(viewModel.$errorMessage) { error in
            if let errorMessage = error {
                MILoader.hide()
                self.errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: errorMessage.localized())
            }
        }
        .onReceive(viewModel.finishData) { data in
            if let trip = data {
                MILoader.hide()
                presentationMode.wrappedValue.dismiss()
            }
        }
        .swiftMessage(message: $errorMessage)
        .onDisappear(perform: {
            // TODO: - Full Refactoring
            if let trip = viewModel.finishData.value {
                let vc = ThanksForTheRideViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                vc.modalPresentationStyle = .fullScreen
                let model = TripScooterSocketDataModel(
                    state: nil,
                    scooter: nil,
                    data: SocketData(
                        billingModeTariff: nil,
                        end: trip.start,
                        endMileage: trip.endMileage,
                        endPosition: nil,
                        id: trip.id,
                        pauses: trip.pauses,
                        scan: trip.scan,
                        speedModeTariff: nil,
                        start: trip.start,
                        startMileage: trip.startMileage,
                        startPosition: nil,
                        user: trip.user,
                        distance: ((trip.endMileage ?? 0) - (trip.startMileage ?? 0)),
                        amount: trip.payment?.amount
                    )
                )
                
                vc.tripEndData = model
                vc.view.backgroundColor = .white
                vc.updateUI(data: model)
                UIApplication.topController()?.present(vc, animated: true)
            }
        })
    }
}
