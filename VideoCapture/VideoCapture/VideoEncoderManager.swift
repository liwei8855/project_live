//
//  VideoEncoderManager.swift
//  VideoCapture
//
//  Created by 李威 on 2022/8/3.
//

import Foundation
import CoreMedia
import AVFoundation

class X264Manager {
    var framecnt: Int64 = 0
    var encoder_h264_frame_width: Int32 = 0
    var encoder_h264_frame_height: Int32 = 0
    var out_file: UnsafeMutablePointer<Int8>?
    var pFormatCtx: UnsafeMutablePointer<AVFormatContext>?
    var fmt: UnsafeMutablePointer<AVOutputFormat>?
    var video_st: UnsafeMutablePointer<AVStream>?
    var pCodecCtx: UnsafeMutablePointer<AVCodecContext>?
    var pCodec: UnsafeMutablePointer<AVCodec>?
    var pFrame: UnsafeMutablePointer<AVFrame>?
    var picture_buf: UnsafeMutablePointer<UInt8>?
    var pkt: AVPacket?
    var picture_size: Int?
    var y_size:Int32?
    
    //编码后文件的文件名，保存路径
    func setFileSavePath(_ path: String){
        out_file = nsstring2char(path)
    }
    func nsstring2char(_ path: String) -> UnsafeMutablePointer<Int8>{
        let charArray = path.cString(using: .utf8)!
        let length = charArray.count
        let pointer = UnsafeMutablePointer<Int8>.allocate(capacity: length)
        for i in 0..<length {
            pointer[i]=charArray[i]
        }
        return pointer
    }
    
    //设置X264
    func setX264Resource(_ width: Int,_ height: Int, _ bitrate: Int) -> Int {
        //默认从第0帧开始(记录当前的帧数)
        framecnt = 0
        //传入的宽高
        encoder_h264_frame_width = Int32(width)
        encoder_h264_frame_height = Int32(height)
        //注册FFmpeg所有编解码器(编码解码都需要)
        av_register_all()
        //初始化AVFormatContext: 用作之后写入视频帧并编码成 h264，贯穿整个工程当中(释放资源时需要销毁)
        pFormatCtx = avformat_alloc_context()
        guard let pFormatCtx = pFormatCtx else {
            return -1
        }
        //输出文件的路径
        let short_name = UnsafeMutablePointer<Int8>.allocate(capacity: 0)
        let mime_type = UnsafeMutablePointer<Int8>.allocate(capacity: 0)
        fmt = av_guess_format(short_name, out_file, mime_type)
        guard let fmt = fmt else {
            return -1
        }
 
        pFormatCtx.pointee.oformat = fmt
        //打开文件的缓冲区输入输出，flags 标识为  AVIO_FLAG_READ_WRITE ，可读写
//        guard let pb = pFormatCtx.pointee.pb else { return -1 }
        var ppb: UnsafeMutablePointer<AVIOContext>? = UnsafeMutablePointer.init(pFormatCtx.pointee.pb)
        let open_result = avio_open(&ppb, out_file, AVIO_FLAG_READ_WRITE)
        if (open_result < 0){
            print("Failed to open output file error:\(open_result)")
            return -1
        }
        //创建新的输出流, 用于写入文件
        let codec = UnsafePointer<AVCodec>.init(bitPattern: 0)
        video_st = avformat_new_stream(pFormatCtx, codec)
        guard let video_st = video_st else {
            return -1
        }
        //20 帧每秒 ，也就是 fps 为 20
        video_st.pointee.time_base.num = 1
        video_st.pointee.time_base.den = 25
        
        //pCodecCtx 用户存储编码所需的参数格式等等
        //从媒体流中获取到编码结构体，他们是一一对应的关系，一个 AVStream 对应一个  AVCodecContext
        pCodecCtx = video_st.pointee.codec
        guard let pCodecCtx = pCodecCtx else {
            return -1
        }
        //设置编码器的编码格式(是一个id)，每一个编码器都对应着自己的 id，例如 h264 的编码 id 就是 AV_CODEC_ID_H264
        pCodecCtx.pointee.codec_id = fmt.pointee.video_codec
        //设置编码类型为 视频编码
        pCodecCtx.pointee.codec_type = AVMEDIA_TYPE_VIDEO
        //设置像素格式为 yuv 格式
        pCodecCtx.pointee.pix_fmt = PIX_FMT_YUV420P
        //设置视频的宽高
        pCodecCtx.pointee.width = Int32(encoder_h264_frame_width)
        pCodecCtx.pointee.height = Int32(encoder_h264_frame_height)
        //设置帧率
        pCodecCtx.pointee.time_base.num = 1
        pCodecCtx.pointee.time_base.den = 25
        //设置码率（比特率
        pCodecCtx.pointee.bit_rate = Int32(bitrate)
        //视频质量度量标准(常见qmin=10, qmax=51)
        pCodecCtx.pointee.qmin = 10
        pCodecCtx.pointee.qmax = 51
        //设置图像组层的大小(GOP-->两个I帧之间的间隔)
        pCodecCtx.pointee.gop_size = 30
        // 设置 B 帧最大的数量，B帧为视频图片空间的前后预测帧， B 帧相对于 I、P 帧来说，压缩率比较大，也就是说相同码率的情况下，
        // 越多 B 帧的视频，越清晰，现在很多打视频网站的高清视频，就是采用多编码 B 帧去提高清晰度，
        // 但同时对于编解码的复杂度比较高，比较消耗性能与时间
        pCodecCtx.pointee.max_b_frames = 5
        //可选设置
        var param: UnsafeMutablePointer<AVDictionary>?
        // H.264
        if pCodecCtx.pointee.codec_id == AV_CODEC_ID_H264 {
            // 通过--preset的参数调节编码速度和质量的平衡
            av_dict_set(&param, "preset", "slow", 0)
            // 通过--tune的参数值指定片子的类型，是和视觉优化的参数，或有特别的情况。
            // zerolatency: 零延迟，用在需要非常低的延迟的情况下，比如视频直播的编码
            av_dict_set(&param, "tune", "zerolatency", 0)
        }
        //输出打印信息，内部是通过printf函数输出（不需要输出可以注释掉该局）
        av_dump_format(pFormatCtx, 0, out_file, 1)
        //通过 codec_id 找到对应的编码器
        pCodec = avcodec_find_encoder(pCodecCtx.pointee.codec_id)
        guard let pCodec = pCodec else {
            print("Can not find encoder! \n");
            return -1
        }
        //打开编码器，并设置参数 param
        let open2 = avcodec_open2(pCodecCtx, pCodec, &param)
        if open2 < 0 {
            print("Failed to open encoder! \n");
            return -1
        }
        //.初始化原始数据对象: AVFrame
        pFrame = av_frame_alloc()
        
        //通过像素格式(这里为 YUV)获取图片的真实大小，例如将 480 * 720 转换成 int 类型
//        avpicture_fill(pFramePicture, picture_buf, pCodecCtx.pointee.pix_fmt, pCodecCtx.pointee.width, pCodecCtx.pointee.height)
        guard let pFrame = pFrame else {
            return -1
        }
        
        var p1:[UnsafeMutablePointer<UInt8>?] = Array.init(unsafeUninitializedCapacity: Int(AV_NUM_DATA_POINTERS)) { buffer, initializedCount in
            for i in 0..<initializedCount {
                buffer[i] = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)
            }
        }
        var p2:[Int32] = Array.init(unsafeUninitializedCapacity: Int(AV_NUM_DATA_POINTERS)) { buffer, initializedCount in
            for i in 0..<initializedCount {
                buffer[i] = Int32()
            }
        }
        //pFrame.pointee.linesize
        
        av_image_fill_arrays(&p1, &p2, picture_buf, pCodecCtx.pointee.pix_fmt, pCodecCtx.pointee.width, pCodecCtx.pointee.height, 1)
        (pFrame.pointee.data.0,pFrame.pointee.data.1) = (p1[0],p1[1])
        
        //获取指针的值 获取内存地址
//        withUnsafePointer(to: &pFrame) {
//
//        }
        
        //h264 封装格式的文件头部，基本上每种编码都有着自己的格式的头部，想看具体实现的同学可以看看 h264 的具体实现
    
        avformat_write_header(pFormatCtx, UnsafeMutablePointer.allocate(capacity: 0))
        //创建编码后的数据 AVPacket 结构体来存储 AVFrame 编码后生成的数据
        if pkt == nil {
            return -1
        }
        av_new_packet(&pkt!, Int32(picture_size!))
        //设置 yuv 数据中 y 图的宽高
        y_size = pCodecCtx.pointee.width * pCodecCtx.pointee.height
        return 0
    }
    
    //将CMSampleBufferRef格式的数据编码成h264并写入文件
    func encoderToH264(_ sampleBuffer: CMSampleBuffer) {
        //通过CMSampleBufferRef对象获取CVPixelBufferRef对象
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        guard let imageBuffer = imageBuffer else { return }
        let lockFlag = CVPixelBufferLockFlags.init(rawValue: 0)
        //锁定imageBuffer内存地址开始进行编码
        if CVPixelBufferLockBaseAddress(imageBuffer, lockFlag) == kCVReturnSuccess {
            //从CVPixelBufferRef读取YUV的值
            //NV12和NV21属于YUV格式，是一种two-plane模式，即Y和UV分为两个Plane，但是UV（CbCr）为交错存储，而不是分为三个plane
            //获取Y分量的地址
            let bufferPtr:UnsafeMutableRawPointer? = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
            //获取UV分量的地址
            let bufferPtr1:UnsafeMutableRawPointer? = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1)
            //根据像素获取图片的真实宽度&高度
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            //获取Y分量长度
            let bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
            let bytesrow1 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1)
            let yuv420_data:UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer.allocate(capacity: width*height*3/2)
            //将NV12数据转成YUV420P(I420)数据
            let pY:UnsafeMutablePointer<UInt8>? = bufferPtr?.assumingMemoryBound(to: UInt8.self)
            var pUV:UnsafeMutablePointer<UInt8>? = bufferPtr1?.assumingMemoryBound(to: UInt8.self)
            guard let yuv420_data = yuv420_data, let pY = pY else {
                return
            }
            
            let pU:UnsafeMutablePointer = yuv420_data + width*height
            let pV =  pU + width*height/4
            for i in 0..<height {
                memcpy(yuv420_data+i*width, pY+i*bytesrow0, width)
            }
            if pUV == nil {
                return
            }
            for _ in 0..<height/2 {
                for i in 0..<width/2 {
                    pU.advanced(by: 1).pointee = pUV!.advanced(by: i*2).pointee
                    pV.advanced(by: 1).pointee = pUV!.advanced(by: i*2+1).pointee
                }
                pUV! = pUV! + bytesrow1
//                pUV.advanced(by: bytesrow1)
            }
            //分别读取YUV的数据
            guard let pFrame = pFrame else {
                return
            }
            picture_buf = yuv420_data
            guard let picture_buf = picture_buf else {
                return
            }
            pFrame.pointee.data.0 = picture_buf //y
            guard let y_size = y_size else {
                return
            }
            pFrame.pointee.data.1 = picture_buf.advanced(by: Int(y_size))//u
            pFrame.pointee.data.2 = picture_buf.advanced(by: Int(y_size*5/4)) //v
            
            //设置当前帧
            pFrame.pointee.pts = framecnt
            let got_picture: UnsafeMutablePointer<Int32> = UnsafeMutablePointer.allocate(capacity: 0)
            //设置宽度高度以及YUV各式
            pFrame.pointee.width = encoder_h264_frame_width
            pFrame.pointee.height = encoder_h264_frame_height
            pFrame.pointee.format  = AV_PIX_FMT_YUVA420P.rawValue
            
            if pkt == nil {
                return
            }
            //对编码前的原始数据(AVFormat)利用编码器进行编码，将 pFrame 编码后的数据传入pkt 中
            var ret = avcodec_encode_video2(pCodecCtx, &pkt!, pFrame, got_picture)
            if ret < 0 {
                print("Failed to encode! \n");
            }
            //编码成功后写入 AVPacket 到 输入输出数据操作着 pFormatCtx 中，当然，记得释放内存
            guard let video_st = video_st else {
                return
            }
            if got_picture.pointee == 1 {
                framecnt += 1
                pkt!.stream_index = video_st.pointee.index
                ret = av_write_frame(pFormatCtx, &pkt!)
                av_free_packet(&pkt!)
            }
            got_picture.deallocate()
            yuv420_data.deallocate()
            //释放yuv数据
            free(yuv420_data)
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, lockFlag)
    }
    
    func freeX264Resource() {
        //释放AVFormatContext
        guard let pFormatCtx = pFormatCtx else {
            return
        }
        let ret = flush_encoder(pFormatCtx, 0)
        if ret < 0 {
            print("Flushing encoder failed\n");
        }
        //将还未输出的AVPacket输出出来
        av_write_trailer(pFormatCtx)
        //关闭资源
        if let video_st = video_st {
            avcodec_close(video_st.pointee.codec)
            av_free(pFrame)
        }
        avio_close(pFormatCtx.pointee.pb)
        avformat_free_context(pFormatCtx)
    }
    
    func flush_encoder(_ fmt_ctx: UnsafeMutablePointer<AVFormatContext>, _ stream_index: Int) -> Int32 {
        var ret: Int32 = 0
        var got_frame: Int32 = 0
        var enc_pkt = AVPacket()
        guard let streams = fmt_ctx.pointee.streams else { return -1 }
        guard let stream = streams[stream_index] else { return -1 }
        let capa = stream.pointee.codec.pointee.codec.pointee.capabilities
        
        let result = capa & CODEC_CAP_DELAY
        if result == 0 {
            return 0
        }
        
        while (true) {
            enc_pkt.data = UnsafeMutablePointer.allocate(capacity: 0)
            enc_pkt.size = 0
            av_init_packet(&enc_pkt)
            var frame:UnsafeMutablePointer<AVFrame>? = UnsafeMutablePointer.allocate(capacity: 0)
            ret = avcodec_encode_video2(stream.pointee.codec, &enc_pkt, frame, &got_frame)
            av_frame_free(&frame)
            
            if ret < 0 {
                break
            }
            if got_frame != 0 {
                ret = 0
                break
            }
            ret = av_write_frame(fmt_ctx, &enc_pkt)
            if ret < 0 {
                break
            }
        }
        enc_pkt.data.deallocate()
        return ret
    }
}
class VideoEncodeManager {
    
    static let instance = VideoEncodeManager()
    
    func setupEncoder(_ path: String) {
        encoder.setFileSavePath(path)
    }
    
    func setX264Resource(_ width: Int,_ height: Int, _ bitrate: Int) -> Int {
        let result = encoder.setX264Resource(width, height, bitrate)
        return result
    }
   
    func encoderToH264(_ sampleBuffer: CMSampleBuffer) {
        encoder.encoderToH264(sampleBuffer)
    }
    
    func freeX264Resource() {
        encoder.freeX264Resource()
    }
    
    private lazy var encoder: X264Manager = {
        let m = X264Manager()
        return m
    }()
}
