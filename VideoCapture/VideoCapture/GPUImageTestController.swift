//
//  GPUImageTestController.swift
//  VideoCapture
//
//  Created by 李威 on 2022/7/27.
//

import UIKit
import GPUImage

class GPUImageTestController: UIViewController {

  @IBOutlet weak var testImageView: UIImageView!
  override func viewDidLoad() {
    super.viewDidLoad()

    process1()
  }
    
  private func process1(){
    let sourceImage = UIImage(named: "test")!
    let toonFilter = SmoothToonFilter()
    let filteredImage = sourceImage.filterWithOperation(toonFilter)
    self.testImageView.image = filteredImage
  }
   

}
