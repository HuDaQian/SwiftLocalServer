//
//  LocalServer+Extension.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation

extension LocalServer {
    func makeResponse(default statusCode: ServerStatusCode) -> HTTPMessage {
        return makeResponse(status: getResponseFormat(default: statusCode), responseHeader: getDefaultResponseHeader())
    }
    func makeResponse(with statusCode: StatusCode) -> HTTPMessage {
        return makeResponse(status: getResponseFormat(statusCode), responseHeader: getDefaultResponseHeader())
    }
    func makeResponse(status: CallbackStatus, responseHeader: CustomHeader?) -> HTTPMessage {
        return makeResponse(status: status, responseHeader: responseHeader, data: "")
    }
    func makeResponse<T: Encodable>(status: CallbackStatus, responseHeader: CustomHeader?, data: T) -> HTTPMessage {
        return HTTPMessage.respone(statusCode: 200, statusDescription: "ok", format: status, responseValue: data, responseHeader: responseHeader)
    }
}
