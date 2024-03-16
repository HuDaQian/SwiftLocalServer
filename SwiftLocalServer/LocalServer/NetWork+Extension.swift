//
//  NetWork+Extension.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation
import Network

extension NWListener {
    func startListenerToIncommingConnection(_ newConnectionHandler: @escaping (NWConnection) -> Void) {
        self.stateUpdateHandler = { state in
            switch state {
            case .setup:
                print("Listener: setup")
            case .ready:
                print("Listener: receive new connection")
            case .waiting(let error):
                print("Listener: waiting \(error)")
            case .failed(let error):
                print("Listener: failed \(error)")
            case .cancelled:
                print("Listener: cancelled")
            @unknown default:
                fatalError()
            }
        }
        self.newConnectionHandler = { connection in
            print("Listener: new connection received.")
            newConnectionHandler(connection)
        }
        start(queue: .global())
    }
}

extension NWConnection {
    func confirm(_ completionHandler: @escaping () -> Void) {
        print("Connection: confirming")
        self.stateUpdateHandler = { state in
            switch state {
            case .setup:
                print("Connection: setup")
            case .preparing:
                print("Connection: preparing")
            case .waiting(let error):
                print("Connection: waiting \(error)")
            case .ready:
                completionHandler()
            case .failed(let error):
                print("Connection: failed \(error)")
            case .cancelled:
                print("Connection: cancelled")
            @unknown default:
                fatalError()
            }
        }
        start(queue: .global())
    }
    func receiveRequest(_ requestHandler: @escaping (HTTPMessage) -> Void) {
        print("Connection: receiving request")
        receive(minimumIncompleteLength: 1, maximumLength: 1024*8) { content, contentContext, isComplete, error in
            error.map{ print("Connection: receiving request error:\($0)") }
            if let content = content,
               let request = HTTPMessage.requestData(data: content) {
                print("Connection: request received")
                requestHandler(request)
            }
        }
    }
    func sendResponse(_ response: HTTPMessage, completion: @escaping () -> Void) {
        print("Connection: sending response")
        send(content: response.data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed({ error in
           print("Connection: response send")
            error.map{ print("Response: sending error:\($0)")}
            completion()
        }))
    }
    func close() {
        print("Connection: closing")
        cancel()
    }
}
