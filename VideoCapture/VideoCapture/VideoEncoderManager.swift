//
//  VideoEncoderManager.swift
//  VideoCapture
//
//  Created by 李威 on 2022/8/3.
//

import Foundation

class X264Manager {
    var framecnt = 0
    var encoder_h264_frame_width = 0
    var encoder_h264_frame_height = 0
    
    func setX264Resource(_ width: Int,_ height: Int, _ bitrate: Int) -> Int {
        framecnt = 0
        encoder_h264_frame_width = width
        encoder_h264_frame_height = height
        
//        av_register_all()
        
        return 0
    }
}
class VideoEncodeManager {
    private lazy var encoder: X264Manager = {
        let m = X264Manager()
        return m
    }()
}
