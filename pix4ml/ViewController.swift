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
    
    override func viewDidLoad() {
    super.viewDidLoad()
    do {
      cameraManager = try CameraManager(containerView: cameraView)
      cameraManager.delegate = self
    } catch {
      print(error.localizedDescription)
    }
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    do {
      try cameraManager.startSession()
    } catch {
      print(error.localizedDescription)
    }
  }
  
  override func viewDidDisappear() {
    super.viewDidDisappear()
    do {
      try cameraManager.stopSession()
    } catch {
      print(error.localizedDescription)
    }
  }
    
    @IBAction private func capturePhoto(_ sender: NSButton) {
        NotificationCenter.default.post(name: Notification.Name("capturePhotoClicked"),
                                        object: nil)
    }
    
}

extension ViewController: CameraManagerDelegate {
    func takePhoto(image: NSImage) {
        // Obtaining the Location of the Documents Directory
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appPhotoDir = documents.path + "/pix4ML/\(getDate())/"
        do {
            try FileManager.default.createDirectory(atPath: appPhotoDir, withIntermediateDirectories: true)
        } catch {
            print("Unable to Create a directory at Documents")
        }

        let uuid = UUID().uuidString + ".png"
        let finalPath = "file://" + appPhotoDir + uuid
        let url = URL(string: finalPath)!
        
        if let imgRep = image.representations[0] as? NSBitmapImageRep
        {
            if let data = imgRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
            {
                do {
                    try data.write(to: url)
                } catch {
                    print("Unable to Write Image Data to Disk")
                }
            }
        }
    }
    
    func cameraManager(_ output: CameraCaptureOutput, didOutput sampleBuffer: CameraSampleBuffer, from connection: CameraCaptureConnection) {
        //print(Date())
    }
    
    func getDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-hh-mm"
        return dateFormatter.string(from: date)
    }
    
}
