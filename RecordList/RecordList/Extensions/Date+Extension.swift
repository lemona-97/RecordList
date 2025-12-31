//
//  Date+Extension.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import Foundation

extension Date {
    func toString(format: String, locale: Locale = Locale(identifier: "ko_KR")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
