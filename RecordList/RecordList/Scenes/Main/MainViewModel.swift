//
//  MainViewModel.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import Foundation
import Combine

protocol MainViewModelType: AnyObject {
   associatedtype Input
   associatedtype Output
}

final class MainViewModel: MainViewModelType {
   private var cancellables = Set<AnyCancellable>()
   private var recorder: AudioRecorderManager
   private var player: AudioPlayerManager
   
   // MARK: - Recorder Outputs
   private let amplitudeSubject = PassthroughSubject<Float, Never>()
   
   // MARK: - Player Outputs
   
   // MARK: - Input
   struct Input {
      // Recorder
      let recordTap: AnyPublisher<Void, Never>
      let stopTap: AnyPublisher<Void, Never>
      let recordQualityIndex: AnyPublisher<Int, Never>
      let deleteTap: AnyPublisher<Void, Never>
      let saveTap: AnyPublisher<Void, Never>
      
      // Player
      let didClosePlayer: AnyPublisher<Void, Never>
      let didTapPlay: AnyPublisher<RecordingObject, Never>
      let didTapPause: AnyPublisher<Void, Never>
      let movedTime: AnyPublisher<TimeInterval, Never>
   }
   
   // MARK: - Output
   struct Output {
      // Recorder
      let recordState: AnyPublisher<RecordingState, Never>
      let amplitude: AnyPublisher<Float, Never>
      let recordings: AnyPublisher<[RecordingObject], Never>
      let hasInterruptedRecording: AnyPublisher<Bool, Never>
      
      // Player
      let playerState: AnyPublisher<AudioPlayerManager.State, Never>
      let playerCurrentTime: AnyPublisher<Double, Never>
      let playerAmplitude: AnyPublisher<Float, Never>
   }
   
   // MARK: - Initializers
   init() {
      recorder = AudioRecorderManager(quality: .medium)
      player = AudioPlayerManager()
      bindRecorder()
      bindPlayer()
   }
   
   func transform(input: Input) -> Output {
      input.recordTap
         .sink { [weak self] in
            guard let self else { return }
            
            
            if self.recorder.state.value == .interruptFinished,
               self.recorder.hasTempRecording {
               self.recorder.stop()
            }
            
            self.recorder.start()
         }.store(in: &cancellables)
      
      input.stopTap
         .sink { [weak self] in
            self?.recorder.stop()
         }.store(in: &cancellables)
      
      input.recordQualityIndex
         .map { index -> AudioQuality in
            switch index {
            case 0: return .low
            case 1: return .medium
            case 2: return .high
            default: return .medium
            }
         }.sink { [weak self] quality in
            self?.recorder.updateQuality(quality)
         }.store(in: &cancellables)
      
      input.deleteTap
         .sink { [weak self] in
            guard let self else { return }
            if self.recorder.state.value == .interruptFinished {
               self.recorder.discardCurrentRecording()
            }
         }
         .store(in: &cancellables)
      
      input.saveTap
         .sink { [weak self] in
            guard let self else { return }
            if self.recorder.state.value == .interruptFinished,
               self.recorder.hasTempRecording {
               self.recorder.stop()
            }
         }
         .store(in: &cancellables)
      
      
      input.didClosePlayer
         .sink { [weak self] in
            self?.player.stop()
         }
         .store(in: &cancellables)
      
      input.didTapPlay
         .sink { [weak self] record in
            self?.player.play(record: record)
         }
         .store(in: &cancellables)

      input.didTapPause
         .sink { [weak self] _ in
            self?.player.pause()
         }
         .store(in: &cancellables)

      input.movedTime
         .sink { [weak self] time in
            self?.player.seek(to: time)
         }
         .store(in: &cancellables)
      
      return Output(
         recordState: recorder.state.eraseToAnyPublisher(),
         amplitude: amplitudeSubject.eraseToAnyPublisher(),
         recordings: RecordingDBManager.shared.recordingListSubject.eraseToAnyPublisher(),
         hasInterruptedRecording: recorder.state
            .map { [weak recorder] state in
               guard state == .interruptFinished else { return false }
               return recorder?.hasTempRecording ?? false
            }
            .eraseToAnyPublisher(),
         
         playerState: player.state.eraseToAnyPublisher(),
         playerCurrentTime: player.progress.eraseToAnyPublisher(),
         playerAmplitude: player.amplitude.eraseToAnyPublisher(),
      )
   }
}

// MARK: - API Methods
private extension MainViewModel {
   // 녹음 완료 후 서버 전송 로직
   
   // CAF -> M4A 형태로 변환
   // 서버 전송
   func sendToServer() {
      
   }
}

// MARK: - Private Methods
private extension MainViewModel {
   func bindRecorder() {
      // 파형 값 전달
      recorder.onAmplitudeUpdate = { [weak self] amplitude in
         guard let self else { return }
         amplitudeSubject.send(amplitude)
      }
      
      recorder.onRecordingFinished = { [weak self] fileURL, startedAt, endedAt in
         RecordingDBManager.shared.saveRecording(
            fileURL: fileURL,
            startedAt: startedAt,
            endedAt: endedAt
         )
      }
   }
   
   func bindPlayer() {

   }
}
