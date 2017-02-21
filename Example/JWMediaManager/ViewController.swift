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
    @IBOutlet weak var playModeButton: UIButton!
    @IBOutlet weak var playlistButton: UIButton!
    
    var playerManager = MediaPlayerManager()
    
    var selectedIndex:Int? {
        didSet {
            if selectedIndex != nil {
                playerManager.setPlayIndex(to: selectedIndex!)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.delegate = self
        slider.addTarget(self, action: #selector(sliderValueDidChange(sender:)), for: UIControlEvents.valueChanged)
        slider.addTarget(self, action: #selector(sliderDidFinishSlide(sender:)), for: [.touchUpInside, .touchUpOutside])
        initPlaylist()
    }
    
    
    
    
    /// local sample play files
    func initPlaylist() {
        let testURLs:[URL] = [
            "http://www.stephaniequinn.com/Music/Allegro%20from%20Duet%20in%20C%20Major.mp3",
            "http://www.stephaniequinn.com/Music/Canon.mp3",
            "http://www.stephaniequinn.com/Music/Pachelbel%20-%20Canon%20in%20D%20Major.mp3",
            "http://www.stephaniequinn.com/Music/Handel%20-%20Entrance%20of%20the%20Queen%20of%20Sheba.mp3",
            "http://www.stephaniequinn.com/Music/Hungarian%20Dance.mp3",
            "http://www.stephaniequinn.com/Music/Bach%20-%20Jesu,%20Joy%20of%20Man's%20Desiring.mp3",
            "http://www.stephaniequinn.com/Music/Scheherezade%20Theme.mp3",
            "http://www.stephaniequinn.com/Music/Commercial%20DEMO%20-%2005.mp3",
            "http://www.stephaniequinn.com/Music/Commercial%20DEMO%20-%2011.mp3",
            "http://www.stephaniequinn.com/Music/Commercial%20DEMO%20-%2017.mp3",
            "http://www.stephaniequinn.com/Music/Commercial%20DEMO%20-%2008.mp3"
            ].map({URL(string:$0)!})
        
        guard let path1 = Bundle.main.path(forResource: "stronger", ofType: "mp3") else { return }
        guard let path2 = Bundle.main.path(forResource: "heartbeat", ofType: "mp3") else { return }
        guard let path3 = Bundle.main.path(forResource: "becauseOfYou", ofType: "mp3") else { return }
        let arr = [path1,path2,path3].map{URL(fileURLWithPath: $0)} + testURLs
        
        playerManager.setPlayer(with: arr, playAt: 0)
    }

    // Slider Methods
    
    func sliderValueDidChange(sender: UISlider) {
        playerManager.seekToTime(time: playerManager.duration*Double(sender.value))
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
    
    @IBAction func playModeButtonDidClicked(_ sender: UIButton) {
        playerManager.playMode = PlayMode(rawValue: (playerManager.playMode.rawValue + 1) % 3)!
        switch playerManager.playMode {
        case .loop: self.playModeButton.setImage(UIImage(named: "ic_loop"), for: UIControlState.normal)
        case .one: self.playModeButton.setImage(UIImage(named: "ic_loop_one"), for: UIControlState.normal)
        case .shuffle: self.playModeButton.setImage(UIImage(named: "ic_shuffle"), for: UIControlState.normal)
        }
    }
    
    @IBAction func menuButtonDidClicked(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showPlaylist", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPlaylist" {
            let svc = segue.destination as! PlaylistTableViewController
            svc.playlist = playerManager.playlist
        }
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
    
    func mediaPlayerPlayURLDidChange(_ sender: MediaPlayerManager, playURL: URL?) {
        self.urlLabel.text = playURL?.lastPathComponent
    }
    
    func mediaPlayerPlayTimeDidChange(_ sender: MediaPlayerManager, time: Double) {
        self.currentTimeLabel.text = getReadableTimeString(withDurationInSeconds: Int(time))
        if !self.slider.isHighlighted {
            self.slider.value = Float(time / playerManager.duration)
        }
    }
    
    func mediaPlayerDurationDidChange(_ sender: MediaPlayerManager, duration: Double) {
        self.durationLabel.text = getReadableTimeString(withDurationInSeconds: Int(duration))
    }
    
    func mediaPlayerStatusDidChange(_ sender: MediaPlayerManager, status: PlayerStatus) {
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
    
    func mediaPlayerAvailableDurationDidChange(_ sender: MediaPlayerManager, duration: Double) {
        self.slider.updateBufferProgress(withProgress: Float(duration / playerManager.duration))
    }
}



