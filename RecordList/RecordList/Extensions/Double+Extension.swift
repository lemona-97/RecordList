//
//  Double+Extension.swift
//  RecordList
//
//  Created by wooseob on 1/2/26.
//

import Foundation

extension TimeInterval {

   /// HH:mm:ss 형식 문자열로 변환
   var toTimeString: String {
      let totalSeconds = Int(self)

      let hours = totalSeconds / 3600
      let minutes = (totalSeconds % 3600) / 60
      let seconds = totalSeconds % 60

      if hours > 0 {
         return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
      } else {
         return String(format: "%02d:%02d", minutes, seconds)
      }
   }
}
