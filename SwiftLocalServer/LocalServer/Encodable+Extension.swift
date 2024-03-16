//
//  Encodable+Extension.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap{ $0 as? [String: Any] }
    }
}
