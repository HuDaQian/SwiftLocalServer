//
//  Config.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation

typealias StatusCode = Int
typealias HeaderCheckRuler = (key: String, ruler: (String?) -> StatusCode?)
typealias QueryCheckRuler = (key: String, ruler: (String?) -> StatusCode?)

enum CallbackStatus {
    case success(num: StatusCode, numberKey: String?, value: String, valueKey: String?)
    case error(num: StatusCode, numberKey: String?, value: String, valueKey: String?)
}

enum RequestMethod {
    case get, post, other(String)
    
    var finalValue: String {
        switch self {
        case .get:
            return "get"
        case .post:
            return "post"
        case .other(let method):
            return method
        }
    }
}

enum ServerStatusCode: StatusCode {
    // normal
    case ok = 0
    // server
    case server
    // protocol
    case agreement
    // method
    case method
    // header
    case header
    // path
    case path
    // query
    case param
    // config
    case config
}

struct ServerFunction {
    var path: String
    var method: RequestMethod
    var headerCheck: [HeaderCheckRuler]?
    var queryCheck: [QueryCheckRuler]?
    var responseHeader: CustomHeader?
    var response: Encodable
}

struct ResponseValue: Encodable, EncodableWithConfiguration {
    var statusCode: Int
    var message: String
    var data: Encodable?
    
    enum InternalKey: String, CodingKey {
        case errorCode = "status", message = "msg", data
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: InternalKey.self)
        try container.encode(statusCode, forKey: .errorCode)
        try container.encode(message, forKey: .message)
        
        let data = self.data ?? Data()
        try container.encode(data, forKey: .data)
    }
    
    struct ExtraKeys: CodingKey {
        var intValue: Int? { return nil }
        init?(intValue: Int) {return nil }
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        static let content = ExtraKeys(stringValue: "content")!
    }
    struct UserConfiguration {
        let codeKey: String?
        let messageKey: String?
    }
    func encode(to encoder: Encoder, configuration: UserConfiguration) throws {
        var internalcontainer = encoder.container(keyedBy: InternalKey.self)
        var extraContainer = encoder.container(keyedBy: ExtraKeys.self)
        
        if let codekey = configuration.codeKey,
           let exKey = ExtraKeys(stringValue: codekey) {
            try extraContainer.encode(statusCode, forKey: exKey)
        } else {
            try internalcontainer.encode(statusCode, forKey: .errorCode)
        }
        if let messageKey = configuration.messageKey,
           let exKey = ExtraKeys(stringValue: messageKey) {
            try extraContainer.encode(message, forKey: exKey)
        } else {
            try internalcontainer.encode(message, forKey: .message)
        }
        let data = self.data ?? Data()
        try internalcontainer.encode(data, forKey: .data)
    }
}

struct CustomHeader: Encodable {
    var accept: String?
    var accept_Charset: String?
    var accept_Encoding: String?
    var accept_Language: String?
    var authorization: String?
    var cache_Control: String?
    var connection: String?
    var cookie: String?
    var content_Length: String?
    var content_Type: String?
    var data: String?
    var expect: String?
    var host: String?
    var if_Match: String?
    var if_Modified_Since: String?
    var if_None_Match: String?
    var if_Range: String?
    var user_Agent: String?
    var origin: String?
    var extraInfo: [String: String]?
  
}
