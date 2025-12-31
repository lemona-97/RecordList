//
//  MainModel.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import Foundation
import RealmSwift

// 녹음 메타 데이터
final class RecordingObject: Object {
   // 고유 id
   @Persisted(primaryKey: true) var id: String
   // 녹음 파일 경로
   @Persisted var filePath: String
   // 녹음 시작 시각
   @Persisted var startedAt: Date
   // 녹음 종료 시각
   @Persisted var endedAt: Date
   @Persisted var duration: Double // 필요 할 수도 있음
}

extension RecordingObject {
   func mapToRecordingTableViewCellModel() -> RecordingTableViewCellModel {
      RecordingTableViewCellModel(
         startTime: startedAt,
         endTime: endedAt
      )
   }
}
