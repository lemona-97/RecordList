//
//  AudioPlayerManager.swift
//  RecordList
//
//  Created by wooseob on 1/2/26.
//

import AVFoundation
import Combine

final class AudioPlayerManager: NSObject {

   enum State {
      case idle
      case playing
      case paused
      case finished
   }

   // MARK: - Output
   let state = CurrentValueSubject<State, Never>(.idle)
   let progress = CurrentValueSubject<Double, Never>(0) // 0.0 ~ 1.0
   let duration = CurrentValueSubject<TimeInterval, Never>(0)
   let amplitude = PassthroughSubject<Float, Never>()

   // MARK: - Private
   private var player: AVAudioPlayer?
   private var timer: Timer?

}

extension AudioPlayerManager {
   func play(record: RecordingObject) {
      configureAudioSession()
      
      if state.value == .paused { // 이어서 재생
         player?.play()
         state.send(.playing)
         startTimer()
         return
      }

      prepare(record) // 새로 재생
      player?.play()
      state.send(.playing)
      startTimer()
   }

   func pause() {
      player?.pause()
      state.send(.paused)
      stopTimer()
   }

   func seek(to time: TimeInterval) {
      guard let player else { return }
      player.currentTime = time
      if player.duration > 0 {
         progress.send(player.currentTime / player.duration)
      }
   }

   func stop() {
      player?.stop()
      cleanup()
      state.send(.idle)
   }
}

private extension AudioPlayerManager {
   func configureAudioSession() {
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(
         .playback,
         mode: .default,
         options: [.allowAirPlay, .allowBluetoothA2DP]
      )
      try? session.setActive(true)
   }
   
   func prepare(_ record: RecordingObject) {
      cleanup()
      do {
         print("파일 재생 준비\n파일경로:\(record.filePath)")
         let fileURL = URL(fileURLWithPath: record.filePath)
         guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cleanup()
            return
         }

         let player = try AVAudioPlayer(contentsOf: fileURL)
         player.delegate = self
         player.prepareToPlay()
         player.isMeteringEnabled = true
         self.player = player
         duration.send(player.duration)
         progress.send(0)
      } catch {
         cleanup()
      }
   }

   func startTimer() {
      stopTimer()
      print("타이머 시작")
      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
         
         guard let self, let player = self.player else { return }
         print("타이머 작동중: \(player.currentTime)")
         player.updateMeters()
         let power = player.averagePower(forChannel: 0)
         let normalized = max(0, min(1, (power + 60) / 60)) // -60dB ~ 0dB → 0~1
         self.amplitude.send(normalized)
         if player.duration > 0 {
            self.progress.send(player.currentTime / player.duration)
         }
      }
   }

   func stopTimer() {
      timer?.invalidate()
      timer = nil
   }

   func cleanup() {
      print("재생파일 정리")
      stopTimer()
      player = nil
      amplitude.send(0)
      progress.send(0)
      duration.send(0)
   }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
   func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      stopTimer()
      state.send(.finished)
      progress.send(1.0)
   }
}
