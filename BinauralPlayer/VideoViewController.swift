//
//  VideoViewController.swift
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 5. 21..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import Photos
import AVKit
import AssetsLibrary

class VideoViewController: UIViewController {
    
    var joystick1 = JoyStickView()
    
    var binaural = Binaural()
    
    var audioAsset : AVAssetTrack!
    var audioMix : AVMutableAudioMix!
    var audioMixParam: [AVMutableAudioMixInputParameters] = []
    let composition: AVMutableComposition = AVMutableComposition()
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isPlaying = false
    var isBinaural = true
    
    /* 파일 생성 관련 변수 */
    var vtitle: String?
    var vUrl: URL!
    var filename : String?
    var fileURL: URL!
    var outputURL: URL!
    var mergedAudioVideoURl = NSURL()
    var exportAudioURL : URL!

    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var nowTime: Float64 = 0.0
    var durationTime: Float64 = 0.0
    
    var nowAngle: CGFloat = 0.0
    var nowElev: Float = 0.0
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var joystickView: UIView!
    @IBOutlet weak var navBarItem: UINavigationItem!
    @IBOutlet weak var spinnerView: UIView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var saveBtn: UIButton! {
        didSet{
            saveBtn.isEnabled = false
        }
    }
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var elevUpBtn: UIButton!
    @IBOutlet weak var elevDownBtn: UIButton!
    
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    
    @IBOutlet weak var thetaLabel: UILabel!

    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var elevSlider: UISlider! {
        didSet{
            // 수직 슬라이더 설정
            elevSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
            elevSlider.maximumValue = 90
            elevSlider.minimumValue = -45
        }
    }
    @IBAction func elevSlide(_ sender: UISlider) {
        elevSlider.addTarget(self, action: #selector(handleElevation), for: .valueChanged)
    }
    
    @IBAction func videoSlide(_ sender: Any) {
        videoSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
    }
    
    /*
     * elevation 조작 버튼
     * elevation 값을 5단위로 조정 및 터치 이벤트시 버튼 색상 변경
     */
    @IBAction func elevUp(_ sender: UIButton) {
        elevSlider.setValue(elevSlider.value + 5, animated: true)
        elevUpBtn.setImage(UIImage(named: "btn_volup_magenta.9"), for: .highlighted)
        handleElevation()
    }
    @IBAction func elevDown(_ sender: UIButton) {
        elevSlider.setValue(elevSlider.value - 5, animated: true)
        elevDownBtn.setImage(UIImage(named: "btn_voldown_magenta.9"), for: .highlighted)
        handleElevation()
    }

    /*
     * 영상 재생시간을 10초 간격으로 조정
     * videoSilder와 스케일을 맞추기 위해 전체 영상 길이로 나눈 값을 적용
     */
    @IBAction func nextPressed(_ sender: UIButton) {
        videoSlider.setValue(videoSlider.value + Float(10/durationTime), animated: true)
        nextBtn.setImage(UIImage(named: "btn_next_magenta.9"), for: .highlighted)
        handleSliderChange()
        
    }
    @IBAction func prevPressed(_ sender: UIButton) {
        videoSlider.setValue(videoSlider.value - Float(10/durationTime), animated: true)
        prevBtn.setImage(UIImage(named: "btn_prev_magenta.9"), for: .highlighted)
        handleSliderChange()
    }
    
    /*
     * 영상 재생 버튼
     */
    @IBAction func playPressed(_ sender: Any) {
        if !isPlaying{
            playBtn.setImage(UIImage(named: "btn_pause_magenta.9"), for: .normal)
            saveBtn.setBackgroundImage(UIImage(named: "btn_magenta.9"), for: .normal)
            saveBtn.isEnabled = true
            player.play()
        }else{
            player.pause()
            playBtn.setImage(UIImage(named: "btn_play_blue.9"), for: .normal)
        }
        isPlaying = !isPlaying
        
    }
 
    /*
     * binaural, original 모드 설정
     * binaural 모드 : elevation, angle 조작 버튼 활성화
     * original 모드 : elevation, angle 조작 버튼 비활성화 및 숨김
     */
    @IBAction func editPressed(_ sender: UIButton) {
        if isBinaural {
            editBtn.setTitle("ORIGINAL", for: .normal)
            editBtn.setBackgroundImage(UIImage(named: "btn_green.9"), for: .normal)
            
            elevUpBtn.isHidden = true
            elevDownBtn.isHidden = true
            elevSlider.isHidden = true
            joystickView.isHidden = true
            binaural.setElev(0)
            binaural.setAngle(0)
        }else {
            editBtn.setTitle("EDIT", for: .normal)
            editBtn.setBackgroundImage(UIImage(named: "btn_magenta.9"), for: .normal)
            
            elevUpBtn.isHidden = false
            elevDownBtn.isHidden = false
            elevSlider.isHidden = false
            joystickView.isHidden = false
        }
        binaural.modeBinaural()
        isBinaural = !isBinaural
    }
    
    /*
     * 영상 재생 버튼
     * binaural 오디오 생성 -> 오디오 인코딩 -> 생성 파일명 입력 -> 오디오&영상 합성 순으로 동작
     * 영상 생성이 끝날때 까지 Loading Spinner을 띄움
     */
    @IBAction func savePressed(_ sender: UIButton) {
        
        player.pause()
        playBtn.setImage(UIImage(named: "btn_play_blue.9"), for: .normal)
        isPlaying = !isPlaying
        
        spinnerView.isHidden = false
        spinner.startAnimating()

        // 파일명 입력 팝업
        let alert = UIAlertController(title: "Write File", message: "파일명을 입력해주세요.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Filename"
        }
        let write = UIAlertAction(title: "Write", style: .default) { (ok) in
            self.filename = alert.textFields?[0].text
            
            print("Write......\n")
            
            self.binaural.renderingBinaural() // Binaural을 적용한 오디오 파일 생성
            print("Write Done\n")
            
            // 오디오 인코딩
            print("Convert Audio\n")
            self.convertCAFtoM4a()
            
            print("Merge Video....\n")
            self.mergeVideo(videoURL: self.vUrl) // 오디오, 비디오를 합침
            
            print("Merge Done\n")
        }

        alert.addAction(write)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleElevation(){
        nowElev = floor(elevSlider.value)
        binaural.setElev(Int32(nowElev)) //set Elev value -45 ~ 90
    }
    
    @objc func handleSliderChange(){
        if let duration = player.currentItem?.duration{
            let totalSeconds = CMTimeGetSeconds(duration)
            let seekTime = CMTime(value: Int64(Float64(videoSlider.value)*totalSeconds), timescale:1)
            player.seek(to: seekTime, completionHandler: {(completedSeek) in
            })
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let naviBar = self.navigationController?.navigationBar
        naviBar?.setBackgroundImage(UIImage(), for: .default)
        naviBar?.shadowImage = UIImage()
        naviBar?.isTranslucent = true
        spinnerView.isHidden = true
        spinner.transform = CGAffineTransform(scaleX: 2, y: 2)
        setPlayerView()
        
    }
    
    /*
     * Video List 버튼 동작시 재생 중이던 영상을 정지하고 비디오 리스트 화면으로 넘어감
     * 새로 추가된 비디오를 AppDelegate에서 관리함으로써 비디오 리스트 갱신
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if (self.isMovingFromParentViewController || self.isBeingDismissed) {
            self.binaural.setMode()
            if isPlaying{
                player.pause()
                isPlaying = !isPlaying
                
            }
            if outputURL != nil && filename != nil{
                appDelegate!.videoList.append(outputURL)
                appDelegate!.videoNames.append(filename! + ".mp4")
            }
        }
    }
    
    /*
     * joystick 생성하고 joystickView에 등록시켜 관리
     * joystickView에 등록시켜 관리 함으로써 autolayout 적용이 용이및 다양한 디바이스 대응 가능
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let size = CGSize(width: 180.0, height: 180.0)
        
        let joystick1Frame = CGRect(origin: CGPoint(x: 0, y: 40),size: size)
        joystick1 = JoyStickView(frame: joystick1Frame)
        joystick1.movable = false
        joystick1.onoff = true
        joystick1.alpha = 1
        joystick1.baseAlpha = 0.2
        
        joystick1.handleTintColor = UIColor(red: 213/255, green: 85/255, blue: 42/255, alpha: 1)
        joystick1.monitor = { angle, displacement in
            self.thetaLabel.text = "\(floor(360-angle))"
            self.binaural.setAngle(Int32(360-angle)) // set Angle value 0 ~ 360
            self.nowAngle = floor(360-angle)
            
        }
        joystickView.addSubview(joystick1)
    }
    
    private func setPlayerView(){
        player = AVPlayer(url: vUrl)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new,.initial], context: nil)
        audioAsset = player.currentItem?.asset.tracks(withMediaType: AVMediaType.audio).first
        
        let interval = CMTime(value:1, timescale:600)
        let sampleRate : Float64 = Float64(audioAsset.naturalTimeScale)
        player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main , using: {(progressTime) in
            self.currentTimeLabel.text = self.getTimeString(from: progressTime)
            
            if let duration = self.player.currentItem?.duration{
                let durationSeconds = CMTimeGetSeconds(duration)
                let seconds = CMTimeGetSeconds(progressTime)
                
                self.durationTime = durationSeconds
                self.nowTime = floor(seconds/0.001)*0.001
                self.videoSlider.value = Float(seconds / durationSeconds)
                
                let nowFrames : Float64 = sampleRate * Float64(self.nowTime) // 현재 프레임
                self.binaural.setFrames(nowFrames)
            }
        })
        
        // Binaural을 설정하고 콜백 등록
        exportAudioFile(asset: (player.currentItem?.asset)!)
        binaural.setBinaural(exportAudioURL, audioAsset: audioAsset)
        audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [(binaural.getAudioParameter())]

        player.currentItem?.audioMix = audioMix
        
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        videoView.layer.insertSublayer(playerLayer, at: 0)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            videoDurationLabel.text = getTimeString(from: player.currentItem!.duration)
        }
        
    }
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes,seconds])
        }else {
            return String(format: "%02i:%02i", arguments: [minutes,seconds])
        }
    }
    
    /*
     * AVAssetExportSession 을 이용하여 오디오 분리
     */
    func exportAudioFile(asset : AVAsset){
        
        let mixComposition = AVMutableComposition.init()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryURL = urls[0]
        exportAudioURL = documentsDirectoryURL.appendingPathComponent("exportAudio.m4a")
        NSLog("outputURL \(exportAudioURL)")
        
        if FileManager.default.fileExists(atPath: (exportAudioURL.path)) {
            try? FileManager.default.removeItem(atPath: (exportAudioURL.path))
        }
        
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio)[0]
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        mutableCompositionAudioTrack.append(audioCompositionTrack!)
        
        do {
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                videoTrack.timeRange.duration),
                                                                of: audioTrack,
                                                                at: kCMTimeZero)
        } catch {
            print(error.localizedDescription)
        }
        
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough)!
        guard
            exportSession.supportedFileTypes.contains(AVFileType.m4a) else{
                return
        }
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = exportAudioURL
        exportSession.exportAsynchronously {
            if exportSession.status == AVAssetExportSessionStatus.failed {
                NSLog("fali")
            }
        }
        NSLog("export Audio sucess")
        
    }
    
    /*
     * CAF 오디오 파일 인코딩
     */
    func convertCAFtoM4a(){
        let mixComposition = AVMutableComposition.init()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryURL = urls[0]
        let audioURL = documentsDirectoryURL.appendingPathComponent("audio.caf")
        
        NSLog("audioURL \(audioURL)")
        
        let audioAsset = AVURLAsset(url: audioURL)
        let audioTrack = audioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        audioCompositionTrack?.preferredTransform = audioTrack.preferredTransform
        
        mutableCompositionAudioTrack.append(audioCompositionTrack!)
        
        do {
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                audioAsset.duration),
                                                                of: audioTrack,
                                                                at: kCMTimeZero)
        } catch {
            print(error.localizedDescription)
        }
        
        let outputURL = documentsDirectoryURL.appendingPathComponent("audio.m4a")
        
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A)!
        guard
            exportSession.supportedFileTypes.contains(AVFileType.m4a) else{
                return
        }
        // 임시파일 제거
        if FileManager.default.fileExists(atPath: (outputURL.path)) {
            try? FileManager.default.removeItem(atPath: (outputURL.path))
        }
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputURL
        let semaphore = DispatchSemaphore.init(value: 0)
        exportSession.exportAsynchronously {
            NSLog("outputURL \(outputURL)")
            if exportSession.status == AVAssetExportSessionStatus.failed {
                NSLog("fail")
            }
            else if exportSession.status == AVAssetExportSessionStatus.completed{
                NSLog("Convert success")
                semaphore.signal()
            }
            
        }
        semaphore.wait(timeout: .distantFuture)
        
        //임시파일 제거
        if FileManager.default.fileExists(atPath: (audioURL.path)) {
            try? FileManager.default.removeItem(atPath: (audioURL.path))
        }
        
        
    }
    
    /*
     * AVAssetExportSession 을 이용하여 영상, 오디오를 합침
     */
    func mergeVideo(videoURL : URL){
        
        let mixComposition = AVMutableComposition.init()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryURL = urls[0]
        let audioURL = documentsDirectoryURL.appendingPathComponent("audio.m4a")
        NSLog("audioURL \(audioURL)")
        
        let audioAsset = AVURLAsset(url: audioURL)
        let videoAsset = AVURLAsset(url: videoURL)
        
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let audioTrack = audioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        videoCompositionTrack?.preferredTransform = videoTrack.preferredTransform
        
        mutableCompositionVideoTrack.append(videoCompositionTrack!)
        mutableCompositionAudioTrack.append(audioCompositionTrack!)
        
        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                videoTrack.timeRange.duration),
                                                                of: videoTrack,
                                                                at: kCMTimeZero)
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                                                                                videoTrack.timeRange.duration),
                                                                of: audioTrack,
                                                                at: kCMTimeZero)
        } catch {
            print(error.localizedDescription)
        }
        
        outputURL = documentsDirectoryURL.appendingPathComponent(filename!+".mp4")
        
        // 임시파일 제거
        if FileManager.default.fileExists(atPath: (audioURL.path)) {
            try? FileManager.default.removeItem(atPath: (audioURL.path))
        }
        if FileManager.default.fileExists(atPath: (outputURL.path)) {
            try? FileManager.default.removeItem(atPath: (outputURL.path))
        }
        if FileManager.default.fileExists(atPath: (exportAudioURL.path)) {
            try? FileManager.default.removeItem(atPath: (exportAudioURL.path))
        }
        
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough)!
        guard
            exportSession.supportedFileTypes.contains(AVFileType.mp4) else{
                return
        }
        exportSession.outputFileType = AVFileType.mp4
        exportSession.outputURL = outputURL
        exportSession.exportAsynchronously {
            NSLog("outputURL \(self.outputURL!)")
            if exportSession.status == AVAssetExportSessionStatus.failed {
                NSLog("fail")
            }else{
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL!)
                }){
                    saved, error in
                    if saved{
                        let alertController = UIAlertController(title: "video successfully saved", message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        self.present(alertController, animated: true, completion: nil)

                    }
                }
            }
        }
        self.spinner.stopAnimating()
        self.spinnerView.isHidden = true
        NSLog("success")
    }
    
}


