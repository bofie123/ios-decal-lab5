//
//  ImagePickerViewController.swift
//  Snapchat Camera Lab
//
//  Created by Paige Plander on 3/11/17.
//  Copyright © 2017 org.iosdecal. All rights reserved.
//

import UIKit
import AVFoundation

class ImagePickerViewController: UIViewController,AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var imageViewOverlay: UIImageView!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // manages real time capture activity from input devices to create output media (photo/video)
    let captureSession = AVCaptureSession()
    
    // the device we are capturing media from (i.e. front camera of an iPhone 7)
    var captureDevice : AVCaptureDevice?
    
    // view that will let us preview what is being captured from the captureSession
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    // Object used to capture a single photo from our capture device
    let photoOutput = AVCapturePhotoOutput()
    
    // The image to send as a Snap
    var selectedImage = UIImage()
    
    var currentPosition = AVCaptureDevicePosition.front
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        captureNewSession(devicePostion: nil)
        toggleUI(isInPreviewMode: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // hide the navigation bar while we are in this view
        navigationController?.navigationBar.isHidden = true
    }
    
    /// Creates a new capture session, and starts updating it using the user's
    /// input device
    ///
    /// - Parameter devicePostion: location of user's camera - you'll need to figure out how to use this
    func captureNewSession(devicePostion: AVCaptureDevicePosition?) {
        
        // specifies that we want high quality video captured from the device
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        if let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                                        mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified) {
            
            // Iterate through available devices until we find one that works
            for device in deviceDiscoverySession.devices {
                
                // only use device if it supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    if (device.position == currentPosition) {
                        
                        captureDevice = device
                        if captureDevice != nil {
                            // Now we can begin capturing the session using the user's device!
                            do {
                                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                                
                                if captureSession.canAddOutput(photoOutput) {
                                    captureSession.addOutput(photoOutput)
                                }
                            }
                            catch {
                                print(error.localizedDescription)
                            }
                            
                            if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {                                 view.layer.addSublayer(previewLayer)
                                previewLayer.frame = view.layer.frame
                                captureSession.startRunning()
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func selectImage(_ image: UIImage) {
        //The image being selected is passed in as "image".
        selectedImage = image
    }
    
    
    @IBAction func takePhoto(_ sender: UIButton) {
        let settingsForMonitoring = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with:settingsForMonitoring,
                     delegate: self)
    }
    
    /// Provides the delegate a captured image in a processed format (such as JPEG).
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let photoSampleBuffer = photoSampleBuffer {
            // First, get the photo data using the parameters above
            let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer,previewPhotoSampleBuffer: previewPhotoSampleBuffer)
                // Then use this data to create a UIImage, and set it equal to `selectedImage`
            selectedImage = UIImage(data:photoData!)!
                    // This method updates the UI so the send button appears (no need to edit it)
                    toggleUI(isInPreviewMode: true)
        }
    }
    
    
    /// If the front camera is being used, switches to the back camera,
    /// and vice versa
    ///
    /// - Parameter sender: The flip camera button in the top left of the view
    @IBAction func flipCamera(_ sender: UIButton) {
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureInput)
        }
        captureSession.stopRunning()
        if currentPosition == AVCaptureDevicePosition.front {
            currentPosition = AVCaptureDevicePosition.back
        } else {
            currentPosition = AVCaptureDevicePosition.front
        }
        captureNewSession(devicePostion: currentPosition)
    }

    
    
    /// Toggles the UI depending on whether or not the user is
    /// viewing a photo they took, or is currently taking a photo.
    ///
    /// - Parameter isInPreviewMode: true if they just took a photo (and are viewing it)
    func toggleUI(isInPreviewMode: Bool) {
        if isInPreviewMode {
            imageViewOverlay.image = selectedImage
            takePhotoButton.isHidden = true
            sendImageButton.isHidden = false
            cancelButton.isHidden = false
            flipCameraButton.isHidden = true
            
        }
        else {
            takePhotoButton.isHidden = false
            sendImageButton.isHidden = true
            cancelButton.isHidden = true
            imageViewOverlay.image = nil
            flipCameraButton.isHidden = false
        }
        
        // Makes sure that all of the buttons appear in front of the previewLayer
        view.bringSubview(toFront: imageViewOverlay)
        view.bringSubview(toFront: sendImageButton)
        view.bringSubview(toFront: takePhotoButton)
        view.bringSubview(toFront: flipCameraButton)
        view.bringSubview(toFront: cancelButton)
    }
    
    @IBAction func cancelButtonWasPressed(_ sender: UIButton) {
        selectedImage = UIImage()
        toggleUI(isInPreviewMode: false)
    }
    
    @IBAction func sendImage(_ sender: UIButton) {
        performSegue(withIdentifier: "imagePickerToChooseThread", sender: nil)
    }
    
    // Called when we unwind from the ChooseThreadViewController
    @IBAction func unwindToImagePicker(segue: UIStoryboardSegue) {
        toggleUI(isInPreviewMode: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.navigationBar.isHidden = false
        let destination = segue.destination as! ChooseThreadViewController
        destination.chosenImage = selectedImage
        toggleUI(isInPreviewMode: false)
    }
}
