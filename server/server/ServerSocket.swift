//
//  ServerSocket.swift
//  server
//
//  Created by liwei on 2022/7/10.
//

import Foundation
class ServerSocket: NSObject, ClientManagerDelegate {
  
  func removeClient(_ client: ClientManager) {
    if let index = clients.firstIndex(of: client) {
      clients.remove(at: index)
    }
  }
    
  func sendMsgToClient(_ data: Data) {
    for client in clients {
      let result = client.tcpClient?.send(data: data)
      if !result!.isSuccess {
        print("server send error")
      }
    }
  }
  
  private lazy var serverSocket: TCPServer = TCPServer(address: "127.0.0.1", port: 7878)
  private var isServerRunning : Bool = false
  private var clients : [ClientManager] = [ClientManager]()
  
  private func handleClient(client: TCPClient) {
    let clientMgr = ClientManager()
    clientMgr.socketServer = self
    clientMgr.tcpClient = client
    clientMgr.isClientRunning = true
    clients.append(clientMgr)
    clientMgr.startReadMsg()
  }
}

extension ServerSocket {
  func start() {
    switch serverSocket.listen() {
    case .success:
      isServerRunning = true
      DispatchQueue.global().async {
        while self.isServerRunning {
          let client = self.serverSocket.accept()
          if let client = client {
            DispatchQueue.global().async {
                self.handleClient(client: client)
            }
          }
        }
      }
    case .failure(let error):
      print(error)
    }
  }
    
  func stop(){
    isServerRunning = false
  }
    
  func removeClient(clientMgr: ClientManager) {
    if let index = clients.firstIndex(of: clientMgr) {
      clients.remove(at: index)
    }
  }
  
}
