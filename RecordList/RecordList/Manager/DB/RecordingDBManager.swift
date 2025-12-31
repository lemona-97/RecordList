//
//  RecordingDBManager.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import Foundation
import Combine
import RealmSwift

// DB Manager - 오디오 파일 메타데이터 저장
// File Manager - 오디오 파일 저장
final class RecordingDBManager {
   static let shared = RecordingDBManager()
   
   let recordingListSubject = CurrentValueSubject<[RecordingObject], Never>([])
}

extension RecordingDBManager {
   func saveRecording(
      fileURL: URL,
      startedAt: Date,
      endedAt: Date
   ) {
      let object = RecordingObject()
      object.id = UUID().uuidString
      object.filePath = fileURL.path
      object.startedAt = startedAt
      object.endedAt = endedAt
      object.duration = endedAt.timeIntervalSince(startedAt)
      
      let realm = try! Realm()
      try! realm.write {
         print("db에 녹음 파일 메타 데이터 저장 성공")
         realm.add(object)
      }
      
      fetchRecordings()
   }
   
   func deleteRecording(id: String) {
      let realm = try! Realm()
      
      guard let target =
               realm.object(ofType: RecordingObject.self, forPrimaryKey: id)
      else { return }
      
      // 파일 삭제
      let url = URL(fileURLWithPath: target.filePath)
      try? FileManager.default.removeItem(at: url)
      
      // DB 삭제
      try! realm.write {
         realm.delete(target)
      }
      
      fetchRecordings()
   }
   
   func migrationCheck() {
      print(#function, "Realm 초기 설정")

      let config = Realm.Configuration(
         schemaVersion: 1,
         migrationBlock: { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
               // 지금은 아무 것도 안 해도 됨
               // Realm은 필드 추가/삭제는 자동 처리
            }
         }
      )
      Realm.Configuration.defaultConfiguration = config
   }
   func fetchRecordings() {
      
      let realm = try! Realm()
      
      let results = realm.objects(RecordingObject.self)
         .sorted(byKeyPath: "startedAt", ascending: true)
      print("DB에서 녹음파일 메타데이터 조회")
      print("갯수: ", results.count)
      recordingListSubject.send(Array(results))
   }
}

private extension RecordingDBManager {

}
