//
//  ViewController.swift
//  Demo
//
//  Created by Jianxiong Wang on 2/16/17.
//  Copyright © 2017 JianxiongWang. All rights reserved.
//

import UIKit
import JWMediaManager

class ViewController: UIViewController {
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var slider: JWPlayerTrackSlider!
    
    var playerManager = MediaPlayerManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.delegate = self
        slider.addTarget(self, action: #selector(sliderValueDidChange(sender:)), for: UIControlEvents.valueChanged)
        slider.addTarget(self, action: #selector(sliderDidFinishSlide(sender:)), for: [.touchUpInside, .touchUpOutside])
        initPlaylist()
    }
    
    
    
    /// local sample play files
    func initPlaylist() {
        var arr = [URL]()
        guard let path1 = Bundle.main.path(forResource: "stronger", ofType: "mp3") else { return }
        guard let path2 = Bundle.main.path(forResource: "heartbeat", ofType: "mp3") else { return }
        guard let path3 = Bundle.main.path(forResource: "becauseOfYou", ofType: "mp3") else { return }
        arr = [path1,path2,path3].map{URL(fileURLWithPath: $0)}
        playerManager.setPlayer(with: arr, playAt: 0)
        playerManager.setPlayMode(to: .shuffle)
    }

    // Slider Methods
    
    func sliderValueDidChange(sender: UISlider) {
        playerManager.seekToTime(time: playerManager.getDuration()*Double(sender.value))
    }

    // Resume From seek to time when finish sliding (Must call to keep the current time update correct)
    func sliderDidFinishSlide(sender: UISlider) {
//        playerManager.resumeFromSeekToTime()
    }

    @IBAction func togglePlayPause(_ sender: UIButton) {
        playerManager.togglePlayPause()
    }

    @IBAction func playPrevious(_ sender: UIButton) {
        playerManager.previous()
    }
    
    @IBAction func playNext(_ sender: UIButton) {
        playerManager.next()
    }
}

extension ViewController: MediaPlayerManagerDelegate {
    
    func getReadableTimeString(withDurationInSeconds duration:Int) -> String {
        let hour = duration / 60 / 60
        let minute = duration / 60 % 60
        let second = duration % 60
        
        let format = hour > 0 ? "%02d:%02d:%02d" : "%02d:%02d"
        let args:[CVarArg] = hour > 0 ? [hour,minute,second] : [minute,second]
        return String(format: format, arguments: args)
    }
    
    func mediaPlayerPlayURLDidChange(sender: MediaPlayerManager, playURL: URL?) {
        self.urlLabel.text = playURL?.lastPathComponent
    }
    
    func mediaPlayerPlayTimeDidChange(sender: MediaPlayerManager, time: Double) {
        self.currentTimeLabel.text = getReadableTimeString(withDurationInSeconds: Int(time))
        if !self.slider.isHighlighted {
            self.slider.value = Float(time / playerManager.getDuration())
        }
    }
    
    func mediaPlayerDurationDidChange(sender: MediaPlayerManager, duration: Double) {
        self.durationLabel.text = getReadableTimeString(withDurationInSeconds: Int(duration))
    }
    
    func mediaPlayerStatusDidChange(sender: MediaPlayerManager, status: PlayerStatus) {
        if status == .none {
            slider.isUserInteractionEnabled = false
            playPauseButton.isUserInteractionEnabled = false
            nextButton.isUserInteractionEnabled = false
            previousButton.isUserInteractionEnabled = false
        } else {
            slider.isUserInteractionEnabled = true
            playPauseButton.isUserInteractionEnabled = true
            nextButton.isUserInteractionEnabled = true
            previousButton.isUserInteractionEnabled = true
        }
        playPauseButton.setImage(UIImage(named: status == .playing ? "ic_pause" : "ic_play"), for: UIControlState())
    }
    
    func mediaPlayerAvailableDurationDidChange(sender: MediaPlayerManager, duration: Double) {
        self.slider.updateBufferProgress(withProgress: Float(duration / playerManager.getDuration()))
    }
}



