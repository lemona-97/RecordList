//
//  MainViewController.swift
//  RecordList
//
//  Created by wooseob on 12/29/25.
//  Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//
//

import UIKit
import Combine

final class MainViewController: UIViewController {
   // MARK: - Properties
   private let viewModel = MainViewModel()
   private var cancellables = Set<AnyCancellable>()
   
   // MARK: - Properties - Records
   private var recordDataSources: [RecordingObject] = [] {
      didSet {
         recordsTableView.reloadData()
      }
   }
   private let recordTapSubject = PassthroughSubject<Void, Never>()
   private let stopTapSubject = PassthroughSubject<Void, Never>()
   private let qualityIndexSubject = PassthroughSubject<Int, Never>()
   private let deleteCurrentRecordSubject = PassthroughSubject<Void, Never>()
   private let saveCurrentRecordSubject = PassthroughSubject<Void, Never>()
   
   // MARK: - Properties - Player
   private var lastPlayedRecord: RecordingObject?
   
   // MARK: - Outlets - Records
   @IBOutlet weak var recordsTableView: UITableView!
   @IBOutlet weak var recordStateGraphView: GraphView!
   
   @IBOutlet weak var recordQualitySegmentControl: UISegmentedControl!
   // 녹음 퀄리티는 녹음중에 변경 불가
   @IBAction func recordQualityChanged(_ sender: UISegmentedControl) {
      // 0 low, 1 medium, 2 high
      print("selected: \(sender.selectedSegmentIndex)")
      qualityIndexSubject.send(sender.selectedSegmentIndex)
   }
   
   
   @IBOutlet weak var startRecordButton: CustomButton!
   @IBAction func startRecordButtonAction(_ sender: Any) {
      // idle 또는 interrupted 상태에서 녹음 시작/재개
      recordTapSubject.send(())
   }
   
   @IBOutlet weak var stopRecordButton: CustomButton!
   
   @IBAction func stopRecordButtonAction(_ sender: Any) {
      stopTapSubject.send(())
   }
   
   @IBOutlet weak var deleteCurrentRecordButton: CustomButton!
   @IBAction func deleteCurrentRecordButtonAction(_ sender: Any) {
      deleteCurrentRecordSubject.send(())
   }
   @IBOutlet weak var saveCurrentRecordButton: CustomButton!
   @IBAction func saveCurrentRecordButtonAction(_ sender: Any) {
      saveCurrentRecordSubject.send(())
   }
   
   // MARK: - Outlets - Audio Player
   @IBOutlet weak var recordPlayerView: UIView!
   @IBAction func recodePlayerButtonAction(_ sender: Any) {
      recordPlayerView.isHidden = true
      // 재생 중지
      // 최근 재생 정보 삭제
      lastPlayedRecord = nil
   }
   @IBOutlet weak var playerDateLabel: UILabel!
   @IBOutlet weak var playerSlider: UISlider!

   // 슬라이더 움직이기 시작 감지
   @IBAction func playerTouchDown(_ sender: Any) {
      print("슬라이더 조작 시작")
   }
   
   @IBAction func playerSliderValueChanged(_ sender: UISlider) {
      playerCurrentTimeLabel.text = "\( sender.value)"
   }
   // 슬라이더 움직이는 중
   
   // 슬라이더에서 손 떼고 바로
   @IBAction func playerTouchUpInside(_ sender: Any) {
      // 마지막 위치로 재생 위치 이동
      print("4")
   }
   
   @IBOutlet weak var playerCurrentTimeLabel: UILabel!
   @IBOutlet weak var playerTotalTimeLabel: UILabel!
   
   @IBOutlet weak var playerPlayButton: CustomButton!
   @IBAction func playerPlayButtonAction(_ sender: Any) {
      playerPauseButton.isHidden = false
   }
   @IBOutlet weak var playerPauseButton: CustomButton!
   @IBAction func playerPauseButtonAction(_ sender: Any) {
      playerPauseButton.isHidden = true
   }
   
   // MARK: - Life Cycles
   override func viewDidLoad() {
      super.viewDidLoad()
      setUpDefault()
      bind()
      setRecordsTableView()
      setPlayerSlider()
      RecordingDBManager.shared.fetchRecordings()
   }
}

// MARK: - Private Methods
private extension MainViewController {
   func setUpDefault() {
      recordQualitySegmentControl.selectedSegmentIndex = 1 // default: medium
   }
   
   func setRecordsTableView() {
      recordsTableView.delegate = self
      recordsTableView.dataSource = self
      recordsTableView.register(
         UINib(nibName: RecordingTableViewCell.NIB_NAME, bundle: nil),
         forCellReuseIdentifier: RecordingTableViewCell.CELL_ID
      )
   }
   
   func setPlayerSlider() {
      let thumbImage = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysTemplate)
      playerSlider.setThumbImage(thumbImage, for: .normal)
   }
}

// MARK: - Bind
private extension MainViewController {
   func bind() {
      let input = MainViewModel.Input(
         recordTap: recordTapSubject.eraseToAnyPublisher(),
         stopTap: stopTapSubject.eraseToAnyPublisher(),
         qualityIndex: qualityIndexSubject.eraseToAnyPublisher(),
         deleteTap: deleteCurrentRecordSubject.eraseToAnyPublisher(),
         saveTap: saveCurrentRecordSubject.eraseToAnyPublisher()
      )
      
      let output = viewModel.transform(input: input)
      bind(for: output)
      viewBind()
      dataBind()
   }
   
   func viewBind() {
      
   }
   
   func bind(for output: MainViewModel.Output) {
      output.recordState
         .receive(on: RunLoop.main)
         .sink { [weak self] state in
            guard let self else { return }
            print(state.stateDescription)
            switch state {
            case .idle:
               recordStateGraphView.reset()
               startRecordButton.isHidden = false
               startRecordButton.isEnabled = true
               recordQualitySegmentControl.isHidden = false
               deleteCurrentRecordButton.isHidden = true
               saveCurrentRecordButton.isHidden = true
            case .recording:
               startRecordButton.isHidden = true
               recordQualitySegmentControl.isHidden = true
               deleteCurrentRecordButton.isHidden = true
               saveCurrentRecordButton.isHidden = true
            case .interrupted:
               startRecordButton.isHidden = false
               startRecordButton.isEnabled = false
               recordQualitySegmentControl.isHidden = true
               deleteCurrentRecordButton.isHidden = true
               saveCurrentRecordButton.isHidden = true
            case .interruptFinished:
               startRecordButton.isHidden = false
               startRecordButton.isEnabled = true
               /*
                녹음중이 아니었더라도 interrupt가 발생 했을 수 있기 떄문에
               삭제 & 저장 버튼 노출 여부는 output.hasInterruptedRecording 스트림에서 제어
                */
               break
            }
         }
         .store(in: &cancellables)
      
      output.hasInterruptedRecording
         .receive(on: RunLoop.main)
         .sink { [weak self] hasRecording in
            guard let self else { return }
            deleteCurrentRecordButton.isHidden = !hasRecording
            saveCurrentRecordButton.isHidden = !hasRecording
         }
         .store(in: &cancellables)
      
      output.amplitude.receive(on: RunLoop.main)
         .sink { [weak self] amplitude in
            self?.recordStateGraphView.addAmplitude(amplitude)
         }
         .store(in: &cancellables)
   }
   
   func dataBind() {
      RecordingDBManager.shared.recordingListSubject
         .sink { [weak self] recordDataSources in
            guard let self else { return }
            
            print("DB갱신, 갯수\(recordDataSources.count)")
            self.recordDataSources = recordDataSources
         }
         .store(in: &cancellables)
   }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      recordDataSources.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.CELL_ID, for: indexPath) as? RecordingTableViewCell else {
         return UITableViewCell()
      }
      
      let data = recordDataSources[indexPath.row]
      let model = data.mapToRecordingTableViewCellModel()
      
      cell.configure(with: model)
      
      return cell
   }
   
   // 녹음 건 별 재생기능
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let data = recordDataSources[indexPath.row]
      
      recordPlayerView.isHidden = false
   }
   
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      42
   }
}
