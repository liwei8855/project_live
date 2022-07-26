//
//  ViewController.swift
//  server
//
//  Created by liwei on 2022/7/7.
//

import Cocoa

class ViewController: NSViewController {


    @IBOutlet weak var testField: NSTextField!
    private lazy var serverSocket: ServerSocket = {
    return ServerSocket()
  }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func startServer(_ sender: Any) {
        serverSocket.start()
        testField.stringValue = "服务器已经开启ing"
    }
    @IBAction func stopServer(_ sender: Any) {
        serverSocket.stop()
        testField.stringValue = "服务器未开启"
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

}

