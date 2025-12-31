//
//  AudioRecorderManager.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//

import Foundation
import AVFoundation
import Combine

enum RecordingState {
   case idle // 유휴 상태 (대기)
   case recording
   case interrupted
   case interruptFinished
   
   var stateDescription: String {
      switch self {
      case .idle: return "Idle"
      case .recording: return "Recording"
      case .interrupted: return "Interrupted"
      case .interruptFinished: return "Interrupt Finished"
      }
   }
}

enum AudioQuality {
   case low
   case medium
   case high
   
   var sampleRate: Double {
      switch self {
      case .low: return 22050
      case .medium: return 44100
      case .high: return 48000
      }
   }
   
   var bufferSize: AVAudioFrameCount {
      switch self {
      case .low: return 2048
      case .medium: return 1024
      case .high: return 512
      }
   }
}

final class AudioRecorderManager {
   static let shared = AudioRecorderManager(quality: .medium)
   var state = CurrentValueSubject<RecordingState, Never>(.idle)
   private let audioEngine = AVAudioEngine()
   private var quality: AudioQuality
   
   private var recordingStartDate: Date?
   private var recordingFileURL: URL?
   
   var hasTempRecording: Bool {
      recordingFileURL != nil && recordingStartDate != nil
   }
   
   var onAmplitudeUpdate: ((Float) -> Void)?
   var onRecordingFinished: ((URL, Date, Date) -> Void)?
   
   init(quality: AudioQuality) {
      self.quality = quality
      setupSession()
      registNotifications()
   }
   
   func updateQuality(_ quality: AudioQuality) {
      self.quality = quality
      stop()
      setupSession()
   }
   
   private func setupSession() {
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.record,
                               mode: .default)
      try? session.setPreferredSampleRate(quality.sampleRate)
      try? session.setActive(true)
   }
   
   func start() {
      guard state.value == .idle else { return } // 유휴 상태일때만 동작하도록
      recordingStartDate = Date()
      recordingFileURL = makeRecordingFileURL()
      
      let inputNode = audioEngine.inputNode
      let format = inputNode.inputFormat(forBus: 0)
      
      inputNode.installTap(
         onBus: 0,
         bufferSize: quality.bufferSize,
         format: format
      ) { [weak self] buffer, _ in
         let amplitude = self?.rms(from: buffer) ?? 0
         DispatchQueue.main.async {
            self?.onAmplitudeUpdate?(amplitude)
         }
      }
      
      try? audioEngine.start()
      state.send(.recording)
   }
   
   // 종료 버튼을 눌렀을때만 동작
   // idle 상태로 전환
   // 기록 추가
   func stop() {
      let endDate = Date()
      stopInternal()
      state.send(.idle)
      if let url = recordingFileURL,
         let startDate = recordingStartDate {
         onRecordingFinished?(url, startDate, endDate)
      }
   }
   
   func discardCurrentRecording() {
      stopInternal()
      if let url = recordingFileURL {
         try? FileManager.default.removeItem(at: url)
      }
      recordingStartDate = nil
      recordingFileURL = nil
      state.send(.idle)
   }
   
   func resumeIfPossible() {
      guard state.value == .interrupted else { return }
      start()
   }
   
   // Root Mean Square
   private func rms(from buffer: AVAudioPCMBuffer) -> Float {
      guard let channelData = buffer.floatChannelData?[0] else { return 0 }
      let frameLength = Int(buffer.frameLength)
      
      var sum: Float = 0
      for i in 0..<frameLength {
         sum += channelData[i] * channelData[i]
      }
      
      let rms = sqrt(sum / Float(frameLength))
      return min(rms * 30, 1) // 시각화용 스케일링
   }
   
   private func makeRecordingFileURL() -> URL {
      // 서버 전송시 변환 예정
      let fileName = UUID().uuidString + ".caf"
      let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      return documents.appendingPathComponent(fileName)
   }
}

private extension AudioRecorderManager {
   func registNotifications() {
      NotificationCenter.default.addObserver(
         self,
         selector: #selector(handleInterruption),
         name: AVAudioSession.interruptionNotification,
         object: nil
      )
   }
   
   @objc
   func handleInterruption(_ notification: Notification) {
      guard
         let info = notification.userInfo,
         let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
         let type = AVAudioSession.InterruptionType(rawValue: typeValue)
      else { return }
      
      switch type {
      case .began:
         if state.value == .recording {
            stopInternal()
            state.send(.interrupted)
         }
         
      case .ended:

         state.send(.interruptFinished)
      @unknown default:
         break
      }
   }
   
   func stopInternal() {
      audioEngine.inputNode.removeTap(onBus: 0)
      audioEngine.stop()
   }
}
