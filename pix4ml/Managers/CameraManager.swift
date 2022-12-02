//
//  CameraManager.swift
//  pix4ML
//
//  Created by Emre Kunt on 1.12.2022.
//

import AVFoundation
import Cocoa

enum CameraError: LocalizedError {
    case cannotDetectCameraDevice
    case cannotAddInput
    case previewLayerConnectionError
    case cannotAddOutput
    case videoSessionNil
  
    var localizedDescription: String {
        switch self {
            case .cannotDetectCameraDevice: return "Cannot detect camera device"
            case .cannotAddInput: return "Cannot add camera input"
            case .previewLayerConnectionError: return "Preview layer connection error"
            case .cannotAddOutput: return "Cannot add video output"
            case .videoSessionNil: return "Camera video session is nil"
        }
    }
}

typealias CameraCaptureOutput = AVCaptureOutput
typealias CameraSampleBuffer = CMSampleBuffer
typealias CameraCaptureConnection = AVCaptureConnection

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ output: CameraCaptureOutput, didOutput sampleBuffer: CameraSampleBuffer, from connection: CameraCaptureConnection)
    func capturePhoto(image: NSImage)
}

protocol CameraManagerProtocol: AnyObject {
    var delegate: CameraManagerDelegate? { get set }
  
    func startSession() throws
    func stopSession() throws
}

final class CameraManager: NSObject, CameraManagerProtocol {
  
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoSession: AVCaptureSession!
    private var cameraDevice: AVCaptureDevice!
    private let photoOutput = AVCapturePhotoOutput()

    private let cameraQueue: DispatchQueue

    private let containerView: NSView

    weak var delegate: CameraManagerDelegate?
  
    init(containerView: NSView) throws {
      self.containerView = containerView
      cameraQueue = DispatchQueue(label: "sample buffer delegate", attributes: [])
      super.init()

      NotificationCenter.default.addObserver(self,
                                             selector: #selector(self.capturePhotoClicked),
                                             name: Notification.Name("capturePhotoClicked"),
                                             object: nil)
      try prepareCamera()
    }
  
    deinit {
        previewLayer = nil
        videoSession = nil
        cameraDevice = nil
          
        NotificationCenter.default.removeObserver(self,
                                                name: Notification.Name("capturePhotoClicked"),
                                                object: nil)
            
    }
  
    @objc
    private func capturePhotoClicked(notification: NSNotification) {
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    
    private func prepareCamera() throws {
        videoSession = AVCaptureSession()
        videoSession.sessionPreset = AVCaptureSession.Preset.photo
        previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        previewLayer.videoGravity = .resizeAspectFill

        let devices = AVCaptureDevice.devices()

        cameraDevice = devices.filter { $0.hasMediaType(.video) }.compactMap { $0 }.last

        if cameraDevice != nil  {
            do {
                let input = try AVCaptureDeviceInput(device: cameraDevice)
                if videoSession.canAddInput(input) {
                    videoSession.addInput(input)
                } else {
                    throw CameraError.cannotAddInput
                }
            
                if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
                  connection.automaticallyAdjustsVideoMirroring = false
                  connection.isVideoMirrored = true
                } else {
                  throw CameraError.previewLayerConnectionError
                }
            
                previewLayer.frame = containerView.bounds
                containerView.layer = previewLayer
                containerView.wantsLayer = true
            
              } catch {
                throw CameraError.cannotDetectCameraDevice
              }
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        if videoSession.canAddOutput(videoOutput) {
            videoSession.addOutput(videoOutput)
        } else {
          throw CameraError.cannotAddOutput
        }
        
        if videoSession.canAddOutput(photoOutput) {
            videoSession.addOutput(photoOutput)
        } else {
          print("Could not add photo output to the session")
          return
        }
    }
  
    func startSession() throws {
        if let videoSession = videoSession {
          if !videoSession.isRunning {
              cameraQueue.async {
                  videoSession.startRunning()
              }
          }
        } else {
          throw CameraError.videoSessionNil
        }
    }
  
    func stopSession() throws {
        if let videoSession = videoSession {
          if videoSession.isRunning {
              cameraQueue.async {
                  videoSession.stopRunning()
              }
          }
        } else {
          throw CameraError.videoSessionNil
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(output, didOutput: sampleBuffer, from: connection)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard let data = photo.fileDataRepresentation(),
              let image =  NSImage(data: data)  else {
                return
        }
        delegate?.capturePhoto(image: image)
    }
}
