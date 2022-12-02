//
//  ViewController.swift
//  pix4ML
//
//  Created by Emre Kunt on 1.12.2022.
//

import Cocoa

final class ViewController: NSViewController {
    private var cameraManager: CameraManagerProtocol!

    @IBOutlet weak var cameraView: NSView!
    @IBOutlet weak var resolutionLabel: NSTextField!
    @IBOutlet weak var directoryTextField: NSTextField!
    @IBOutlet weak var errorTextField: NSTextField!
    
    private var imageWidth: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: need to refactor
        imageWidth = 512
        
        do {
            cameraManager = try CameraManager(containerView: cameraView)
            cameraManager.delegate = self
        } catch {
            setErrorLabel(message: error.localizedDescription)
        }
    }
  
    override func viewDidAppear() {
        super.viewDidAppear()
        do {
            try cameraManager.startSession()
        } catch {
            setErrorLabel(message: error.localizedDescription)
        }
    }
  
    override func viewDidDisappear() {
        super.viewDidDisappear()
        do {
            try cameraManager.stopSession()
        } catch {
            setErrorLabel(message: error.localizedDescription)
        }
    }
    
    @IBAction private func capturePhoto(_ sender: NSButton) {
        NotificationCenter.default.post(name: Notification.Name(AppConstant.Notifications.capturePhotoClicked),
                                        object: nil)
    }
    
}

extension ViewController: CameraManagerDelegate {
    func capturePhoto(image: NSImage) {
        
        var newImage = image
        let resizedImage = image.resize(width: imageWidth)
        if let resizedImage = resizedImage {
            newImage = resizedImage
        }
        
        resolutionLabel.cell?.title = "\(newImage.size.width) x \(newImage.size.height)"
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var appPhotoDir = documents.path + "/\(AppConstant.directoryName)/\(getDateAsString())/"
        if let cell = directoryTextField.cell {
            if cell.title != "" {
                appPhotoDir = documents.path + "/\(AppConstant.directoryName)/\(String(describing: cell.title))/"
            }
        }
        do {
            try FileManager.default.createDirectory(atPath: appPhotoDir, withIntermediateDirectories: true)
        } catch {
            setErrorLabel(message: "Unable to Create a directory at Documents")
        }

        let uuid = UUID().uuidString + ".png"
        let finalPath = "file://" + appPhotoDir + uuid
        guard let url = URL(string: finalPath) else { return }
        
        if let data = newImage.pngData(size: CGSize(width: newImage.size.width, height: newImage.size.height)) {
            do {
                try data.write(to: url)
            } catch {
                setErrorLabel(message: "Unable to Write Image Data to Disk")
            }
        } else {
            print("data is null")
        }
    }
    
    func cameraManager(_ output: CameraCaptureOutput, didOutput sampleBuffer: CameraSampleBuffer, from connection: CameraCaptureConnection) {
        //print(Date())
    }
    
    func getDateAsString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-hh-mm"
        return dateFormatter.string(from: date)
    }
    
    func setErrorLabel(message: String) {
        errorTextField.cell?.title = message
    }
    
}
