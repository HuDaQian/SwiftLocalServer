//
//  String+Extension.swift
//  SwiftLocalServer
//
//  Created by GraceMiloy on 2024/3/16.
//

import Foundation

// 首字母大小写转换
extension String {
    var upperFirstLetter: String {
        return self.count >= 0 ? String(self.prefix(1).capitalized + self.dropFirst()) : self
    }
    var lowwerFirstLetter: String {
        return self.count >= 0 ? String(self.prefix(1).lowercased() + self.dropFirst()) : self
    }
}

extension String {
    func transToRequestHeader(_ reverse: Bool = true) -> String {
        if reverse {
            return self.upperFirstLetter.replacingOccurrences(of: "_", with: "-")
        } else {
            return self.upperFirstLetter.replacingOccurrences(of: "-", with: "_")
        }
    }
}
