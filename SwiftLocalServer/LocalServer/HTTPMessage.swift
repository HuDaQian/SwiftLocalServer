//
//  HTTPMessage.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation
import CFNetwork

typealias HTTPMessage = CFHTTPMessage

extension HTTPMessage {
    var requestUrl: URL? {
        return CFHTTPMessageCopyRequestURL(self).map{ $0.takeRetainedValue() as URL}
    }
    var requestMethod: String? {
        return CFHTTPMessageCopyRequestMethod(self).map{ $0.takeRetainedValue() as String}
    }
    var data: Data? {
        return CFHTTPMessageCopySerializedMessage(self).map{ $0.takeRetainedValue() as Data}
    }
    func setBody(data: Data) {
        CFHTTPMessageSetBody(self, data as CFData)
    }
    func setValue(_ value: String?, forHeaderField field: String) {
        CFHTTPMessageSetHeaderFieldValue(self, field as CFString, value as CFString?)
    }
    func value(forHeaderField field: String) -> String? {
        return CFHTTPMessageCopyHeaderFieldValue(self, field as CFString).map{ $0.takeRetainedValue() as String}
    }
    func value(forQueryField field: String) -> String? {
        if let data = CFHTTPMessageCopyBody(self).map({ $0.takeRetainedValue() as Data}),
           let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return dic[field] as! String?
        }
        return nil
    }
    static func requestData(data: Data) -> HTTPMessage? {
        let request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
        let bytes = data.withUnsafeBytes({ $0.bindMemory(to: UInt8.self).baseAddress! })
        
        return CFHTTPMessageAppendBytes(request, bytes, data.count) ? request : nil
    }
    
    static func respone<T: Encodable>(statusCode: Int, statusDescription: String?, format status: CallbackStatus, responseValue: T, responseHeader: CustomHeader?) -> HTTPMessage {
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, statusDescription as CFString?, kCFHTTPVersion1_1).takeRetainedValue()
        
        var formatCode = 0
        var formatMessage = ""
        var codeKey: String?
        var msgKey: String?
        switch status {
        case let .success(num, numberKey, value, valueKey):
            formatCode = num
            formatMessage = value
            codeKey = numberKey
            msgKey = valueKey
        case let .error(num, numberKey, value, valueKey):
            formatCode = num
            formatMessage = value
            codeKey = numberKey
            msgKey = valueKey
        }
        
        let result = ResponseValue(statusCode: formatCode, message: formatMessage, data: responseValue)
        let encoder = JSONEncoder()
        let config = ResponseValue.UserConfiguration(codeKey: codeKey, messageKey: msgKey)
        let body = try? encoder.encode(result, configuration: config)
        if let body = body {
            response.setBody(data: body)
        }
        
        if let responseHeader = responseHeader,
        let dictionary = responseHeader.dictionary{
            for (key, value) in dictionary {
                response.setValue(value as? String, forHeaderField: key.transToRequestHeader())
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE', 'dd' 'MM' 'yyyy HH':'mm':'ss zzz"
            formatter.locale = Locale(identifier: "en_ZH_CN")
            let dateString = formatter.string(from: Date())
            response.setValue(dateString, forHeaderField: "Date")
            response.setValue("Swift Local Server", forHeaderField: "Server")
            response.setValue("close", forHeaderField: "Connection")
            response.setValue("text/plain", forHeaderField: "Content-Type")
        }
        return response
    }
}
