//
//  ClientManager.swift
//  server
//
//  Created by liwei on 2022/7/10.
//

import Foundation

protocol ClientManagerDelegate: AnyObject {
  func sendMsgToClient(_ data: Data)
  func removeClient(_ client : ClientManager)
}

class ClientManager: NSObject {
  var tcpClient : TCPClient?
  var username : String = ""
  var isClientRunning = false
  weak var socketServer : ClientManagerDelegate?
}

extension ClientManager {
  func startReadMsg() {
    isClientRunning = true
    
    //心跳包
    let timer = Timer(fireAt: Date(), interval: 1, target: self, selector: #selector(checkHeartBeat), userInfo: nil, repeats: true)
    RunLoop.current.add(timer, forMode: .common)
    timer.fire()
    
    while isClientRunning {
      if let lMsg = tcpClient?.read(4) {
        // 1.读取长度的data
        let headData = Data(bytes: lMsg, count: 4)
        var length: Int = 0
        (headData as NSData).getBytes(&length, length: 4)
        
        // 2.读取类型
        guard let typeMsg = tcpClient?.read(2) else {
            return
        }
        let typeData = Data(bytes: typeMsg, count: 2)
        var type : Int = 0
        (typeData as NSData).getBytes(&type, length: 2)
        print(type)
        
        // 2.根据长度, 读取真实消息
        guard let msg = tcpClient?.read(length) else {
            return
        }
        let data = Data(bytes: msg, count: length)
        /*
        switch type {
        case 0, 1:
            let user = try! UserInfo.parseFrom(data: data)
            print(user.name)
            print(user.level)
        default:
            print("未知类型")
        }
        */
        let totalData = headData + typeData + data
        socketServer?.sendMsgToClient(totalData)

      }else{
        socketServer?.removeClient(self)
        break
      }
    }

  }
  
  @objc func checkHeartBeat() {
      
  }
  
  private func removeClient() {
    socketServer?.removeClient(self)
    isClientRunning = false
    print("客户端断开了连接")
    tcpClient?.close()
  }
  
  func sendMsg(_ data : Data) {
    let result = tcpClient?.send(data: data)
    if ((result?.isFailure) != nil) {
      print("client send error")
    }
  }
  
  private func readMsg() -> [String : Any]? {
      guard let data = tcpClient?.read(4) else {
          return nil
      }
      guard data.count == 4 else {
          return nil
      }
      
      let hdata = Data(bytes: data, count: data.count)
      
      var length : Int32 = 0
      (hdata as NSData).getBytes(&length, length: data.count)
      
      guard let buff = tcpClient?.read(Int(length)) else {
          return nil
      }
      
      let msgData = Data(bytes: buff, count: buff.count)
      let msgDict = try! JSONSerialization.jsonObject(with: msgData, options: .mutableContainers) as! [String : Any]
      
      return msgDict
  }
}
