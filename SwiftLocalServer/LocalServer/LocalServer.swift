//
//  LocalServer.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation
import Network

class LocalServer {
    static let server = LocalServer()
    static func create() -> LocalServer {
        return server
    }
    
    let listener = try! NWListener(using: .tcp, on: 3000)
    
    // header check
    private var baseHeaderCheckRuler = [HeaderCheckRuler]()
    func addBaseHeaderCheckRuler(_ ruler: HeaderCheckRuler...) {
        baseHeaderCheckRuler.append(contentsOf: ruler)
    }
    
    // query check
    private var baseQueryCheckRuler = [QueryCheckRuler]()
    func addBaseQueryCheckRuler(_ ruler: QueryCheckRuler...) {
        baseQueryCheckRuler.append(contentsOf: ruler)
    }
    
    // response status code
    private var responseStatusList = [StatusCode: CallbackStatus]()
    func setResponseStatus(_ info: [StatusCode: CallbackStatus]) {
        for (key, value) in info {
            responseStatusList[key] = value
        }
    }
    
    // default response header
    private var defaultResponseHeader: CustomHeader?
    func setDefaultResponseHeader(_ header: CustomHeader) {
        defaultResponseHeader = header
    }
    func getDefaultResponseHeader() -> CustomHeader? {
        return defaultResponseHeader
    }
    
    // server function list
    private var serverFunctionList = [String: ServerFunction]()
    func addServerFunction(_ info: [String: ServerFunction]) {
        for (path, function) in info {
            addServerFunction(path, function: function)
        }
    }
    func addServerFunction(_ name: String, function: ServerFunction) {
        serverFunctionList[name] = function
    }
    func getServerFunction(_ path: String) -> ServerFunction? {
        return serverFunctionList[path]
    }
    
    // default response status
    // user can change or delete some status callback
    // be careful if use ! to unwrapper status value
    private var responseFormatList = [StatusCode: CallbackStatus]()
    func addResponseFormat(_ info: [StatusCode: CallbackStatus?]?) {
        guard let info = info else { return }
        for (code, status) in info {
            addResponseFormat(code, status: status)
        }
    }
    func addResponseFormat(_ code: StatusCode, status: CallbackStatus?) {
        responseFormatList[code] = status
    }
    func getResponseFormat(_ code: StatusCode) -> CallbackStatus {
        return responseFormatList[code] ?? CallbackStatus.error(num: ServerStatusCode.config.rawValue, numberKey: nil, value: "Config error", valueKey: nil)
    }
    func getResponseFormat(default code: ServerStatusCode) -> CallbackStatus {
        return responseFormatList[code.rawValue] ?? CallbackStatus.error(num: ServerStatusCode.server.rawValue, numberKey: nil, value: "Server error", valueKey: nil)
    }
    
    func defaultConfig() {
        responseFormatList.removeAll()
        addResponseFormat([
            ServerStatusCode.ok.rawValue: CallbackStatus.success(num: ServerStatusCode.ok.rawValue, numberKey: nil, value: "Success", valueKey: nil),
            ServerStatusCode.server.rawValue: CallbackStatus.error(num: ServerStatusCode.server.rawValue, numberKey: nil, value: "Server error", valueKey: nil),
            ServerStatusCode.agreement.rawValue: CallbackStatus.error(num: ServerStatusCode.agreement.rawValue, numberKey: nil, value: "Agreement error", valueKey: nil),
            ServerStatusCode.method.rawValue: CallbackStatus.error(num: ServerStatusCode.method.rawValue, numberKey: nil, value: "Method error", valueKey: nil),
            ServerStatusCode.header.rawValue: CallbackStatus.error(num: ServerStatusCode.header.rawValue, numberKey: nil, value: "Header error", valueKey: nil),
            ServerStatusCode.path.rawValue: CallbackStatus.error(num: ServerStatusCode.path.rawValue, numberKey: nil, value: "Path error", valueKey: nil),
            ServerStatusCode.param.rawValue: CallbackStatus.error(num: ServerStatusCode.param.rawValue, numberKey: nil, value: "Param error", valueKey: nil),
            ServerStatusCode.config.rawValue: CallbackStatus.error(num: ServerStatusCode.config.rawValue, numberKey: nil, value: "Config error", valueKey: nil)
        ])
    }
    
    func startServer() {
        defaultConfig()
        startServer(with: nil)
    }
    func startServer(with config: [StatusCode: CallbackStatus]?) {
        addResponseFormat(config)
        listener.startListenerToIncommingConnection { connection in
            unowned let connection = connection
            connection.confirm {
                connection.receiveRequest { [self] request in
                    guard let funcName = request.requestUrl?.relativePath else {
                        closeWithResponse(connection, makeResponse(default: ServerStatusCode.server))
                        return
                    }
                    // function check
                    guard let serverFunction = getServerFunction(funcName) else {
                        closeWithResponse(connection, makeResponse(default: ServerStatusCode.method))
                        return
                    }
                    // method check
                    let configMethod = serverFunction.method.finalValue
                    guard let requestMethod = request.requestMethod,
                          requestMethod != configMethod else {
                        closeWithResponse(connection, makeResponse(default: ServerStatusCode.method))
                        return
                    }
                    // header check
                    var headerCheckRulers = serverFunction.headerCheck
                    headerCheckRulers?.append(contentsOf: baseHeaderCheckRuler)
                    if let headerCheckRulers = headerCheckRulers {
                        for (key, ruler) in headerCheckRulers {
                            if let checkStatus = ruler(request.value(forHeaderField: key)) {
                                closeWithResponse(connection, makeResponse(with: checkStatus))
                                return
                            }
                        }
                    }
                    // query check
                    if let queryCheckRulers = serverFunction.queryCheck {
                        for (key, ruler) in queryCheckRulers {
                            if let checkStatus = ruler(request.value(forQueryField: key)) {
                                closeWithResponse(connection, makeResponse(with: checkStatus))
                                return
                            }
                        }
                    }
                    // success
                    closeWithResponse(connection, makeResponse(default: ServerStatusCode.ok))
                }
            }
        }
    }
    
    
    func closeWithResponse(_ connection: NWConnection, _ response: HTTPMessage) {
        connection.sendResponse(response) {
            connection.close()
        }
    }
}
 
