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
   
   private let amplitudeSubject = PassthroughSubject<Float, Never>()
   
   
   // MARK: - Input
   struct Input {
      let recordTap: AnyPublisher<Void, Never>
      let stopTap: AnyPublisher<Void, Never>
      let qualityIndex: AnyPublisher<Int, Never>
      let deleteTap: AnyPublisher<Void, Never>
      let saveTap: AnyPublisher<Void, Never>
   }
   
   // MARK: - Output
   struct Output {
      let recordState: AnyPublisher<RecordingState, Never>
      let amplitude: AnyPublisher<Float, Never>
      let recordings: AnyPublisher<[RecordingObject], Never>
      let hasInterruptedRecording: AnyPublisher<Bool, Never>
   }
   
   // MARK: - Initializers
   init() {
      recorder = AudioRecorderManager(quality: .medium)
      bindRecorder()
   }
   
   func transform(input: Input) -> Output {
      input.recordTap
         .sink { [weak self] in
            guard let self else { return }
            if self.recorder.state.value == .interruptFinished {
               self.recorder.resumeIfPossible()
            } else {
               self.recorder.start()
            }
         }.store(in: &cancellables)
      
      input.stopTap
         .sink { [weak self] in
            self?.recorder.stop()
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
      
      input.qualityIndex
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
      
      return Output(
         recordState: recorder.state.eraseToAnyPublisher(),
         amplitude: amplitudeSubject.eraseToAnyPublisher(),
         recordings: RecordingDBManager.shared.recordingListSubject.eraseToAnyPublisher(),
         hasInterruptedRecording: recorder.state
            .map { [weak recorder] state in
               guard state == .interruptFinished else { return false }
               return recorder?.hasTempRecording ?? false
            }
            .eraseToAnyPublisher()
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
}
