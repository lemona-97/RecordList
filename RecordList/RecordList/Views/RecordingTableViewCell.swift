//
//  RecordingTableViewCell.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import UIKit

// 오후 10시 이전은 시간 바가 가장 앞단에 붙어있음. 오후 10시 이후부터 이동
final class RecordingTableViewCell: UITableViewCell {
   static let CELL_ID = "RecordingTableViewCell"
   static let NIB_NAME = "RecordingTableViewCell"
   
   // 오후 10시 기준
   private let standardStartHour = 22
   // 오전 6시 기준
   private let standardEndHour = 6
   @IBOutlet weak var recordedDateLabel: UILabel!
   
   @IBOutlet weak var leadingSpaceConstraint: NSLayoutConstraint!
   @IBOutlet weak var sleepTimeViewWidth: NSLayoutConstraint!
   
   @IBOutlet weak var startTimeLabel: UILabel!
   @IBOutlet weak var endTimeLabel: UILabel!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
   }
   
   func configure(with model: RecordingTableViewCellModel) {
      let calendar = Calendar.current
      
      // 수면 기준: 오전 6시
      let startComponents = calendar.dateComponents([.hour], from: model.startTime)
      let displayBaseDate: Date
      
      if let hour = startComponents.hour, hour < 6 {
         // 00:00 ~ 05:59 에 시작한 수면은 전날 기준
         displayBaseDate = calendar.date(byAdding: .day, value: -1, to: model.startTime)!
      } else {
         // 06:00 이후에 시작한 수면은 당일 기준
         displayBaseDate = model.startTime
      }
      
      recordedDateLabel.text = displayBaseDate.toString(format: "E M/d")
      
      startTimeLabel.text = model.startTime.toString(format: "HH:mm")
      endTimeLabel.text = model.endTime.toString(format: "HH:mm")
      
      // 기준 시간 Date 생성
      let startStandardDate = calendar.date(
         bySettingHour: standardStartHour,
         minute: 0,
         second: 0,
         of: model.startTime
      )!
      
      // 분 단위 차이 계산
      let startDiffMinutes = calendar.dateComponents([.minute], from: startStandardDate, to: model.startTime).minute ?? 0
      
      // 1분당 0.5 증가
      let startSpacing = CGFloat(startDiffMinutes) * 0.5
      
      // 시작 시간 기준으로 지난 전체 시간(분) 계산
      let durationMinutes = calendar.dateComponents([.minute], from: model.startTime, to: model.endTime).minute ?? 0
      
      // 1분당 0.5씩 너비 증가 (최소 길이 90)
      let recordWidth = CGFloat(max(240, durationMinutes)) * 0.5
      sleepTimeViewWidth.constant = recordWidth
      
      leadingSpaceConstraint.constant = max(0, startSpacing)
   }
}

struct RecordingTableViewCellModel {
   let startTime: Date
   let endTime: Date
}
