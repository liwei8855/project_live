//
//  ViewController.swift
//  VideoCapture
//
//  Created by liwei on 2022/7/27.
//

import UIKit
import AVFoundation

class RecordController: UIViewController {
  private lazy var session : AVCaptureSession = AVCaptureSession()
  private var videoOutput : AVCaptureVideoDataOutput?
  private var previewLayer : AVCaptureVideoPreviewLayer?
  private var videoInput : AVCaptureDeviceInput?
  private var movieOutput : AVCaptureMovieFileOutput?
  
  let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! + "/abc.h264"

  override func viewDidLoad() {
    super.viewDidLoad()
      
    setupVideoInputOutput()
    setupAudioInputOutput()
    
  }

  @IBAction func start(_ sender: Any) {
    session.startRunning()
    setupPreviewLayer()
//    setupMovieFileOutput()
    VideoEncodeManager.instance.setupEncoder(filePath)
    let result = VideoEncodeManager.instance.setX264Resource(480, 640, 1500000)
    if result != 0 {
      print("error \(result)")
    }
  }
  
  @IBAction func stop(_ sender: Any) {
    movieOutput?.stopRecording()
    session.stopRunning()
    previewLayer?.removeFromSuperlayer()
    VideoEncodeManager.instance.freeX264Resource()
  }
  
  @IBAction func `switch`(_ sender: Any) {
    guard let videoInput = videoInput else {
        return
    }
    let postion : AVCaptureDevice.Position = videoInput.device.position == .front ?  .back : .front
    let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: postion).devices
    guard let device = devices.first else { return }
    guard let newInput = try? AVCaptureDeviceInput(device: device) else { return }
    
    session.beginConfiguration()
    session.removeInput(videoInput)
    if session.canAddInput(newInput) {
        session.addInput(newInput)
    }
    session.commitConfiguration()
    
    self.videoInput = newInput
  }
    
    
  private func setupVideoInputOutput() {
    if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
      return
    }
    
    let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: .front).devices
    guard let device = devices.first else { return }
    
    guard let input = try? AVCaptureDeviceInput(device: device) else { return }
    self.videoInput = input
    
    let output = AVCaptureVideoDataOutput()
    let queue = DispatchQueue.global()
    output.setSampleBufferDelegate(self, queue: queue)
    self.videoOutput = output
    
    addInputOutputToSesssion(input, output)
  }
  
  private func setupAudioInputOutput(){
    guard let device = AVCaptureDevice.default(for: .audio) else { return }
    guard let input = try? AVCaptureDeviceInput(device: device) else { return }
    
    let output = AVCaptureAudioDataOutput()
    let queue = DispatchQueue.global()
    output.setSampleBufferDelegate(self, queue: queue)
    
    addInputOutputToSesssion(input, output)
  }

  private func setupPreviewLayer(){
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.frame = view.bounds
    view.layer.insertSublayer(previewLayer, at: 0)
    self.previewLayer = previewLayer
  }

  private func addInputOutputToSesssion(_ input : AVCaptureInput, _ output : AVCaptureOutput) {
      session.beginConfiguration()
      if session.canAddInput(input) {
          session.addInput(input)
      }
      if session.canAddOutput(output) {
          session.addOutput(output)
      }
      session.commitConfiguration()
  }
  
  private func setupMovieFileOutput() {
    if let movieOutput = movieOutput {
      session.removeOutput(movieOutput)
    }
    
    let fileOutput = AVCaptureMovieFileOutput()
    self.movieOutput = fileOutput
    
    let connection = fileOutput.connection(with: .video)
    connection?.automaticallyAdjustsVideoMirroring = true
    
    if session.canAddOutput(fileOutput) {
        session.addOutput(fileOutput)
    }
    
   
    let fileURL = URL(fileURLWithPath: filePath)
    fileOutput.startRecording(to: fileURL, recordingDelegate: self)
  }

}

extension RecordController : AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if videoOutput?.connection(with: .video) == connection {
      print("采集视频数据")
      VideoEncodeManager.instance.encoderToH264(sampleBuffer)
    } else {
      print("采集音频数据")
    }
  }
}

extension RecordController : AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    print("开始写入文件")
  }
  
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    print("完成写入文件")
  }
}

