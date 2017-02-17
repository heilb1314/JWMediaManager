//
//  MediaPlayerManager.swift
//  JWMediaManager
//
//  Created by Jianxiong Wang on 2/15/17.
//  Copyright © 2017 JianxiongWang. All rights reserved.
//

import Foundation
import AVFoundation

public enum PlayerStatus {
    case none, buffering, playing, paused
}

public enum PlayMode {
    case loop, one, shuffle
}

public protocol MediaPlayerManagerDelegate:class {

    /// Player play time did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - time: the new play time
    func mediaPlayerPlayTimeDidChange(sender: MediaPlayerManager, time:Double)


    /// Player current play item duration did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - duration: new duration
    func mediaPlayerDurationDidChange(sender: MediaPlayerManager, duration: Double)


    /// Player current play item available duration did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - duration: new available duration
    func mediaPlayerAvailableDurationDidChange(sender: MediaPlayerManager, duration: Double)


    /// Player Status did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - status: new status
    func mediaPlayerStatusDidChange(sender: MediaPlayerManager, status: PlayerStatus)

    /// Player play item did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - playItem: new playItem
    func mediaPlayerPlayURLDidChange(sender: MediaPlayerManager, playURL: URL?)
}


public class MediaPlayerManager:NSObject
{

    // MARK: USER Settings

    /// looping playlist or not. If true, when index passes the largest index, the index goes back to 0, and vice versa.
    public var loopingPlaylist:Bool = true

    /// If true, next play item will be loaded automatically after the previous one.
    public var autoNextPlay:Bool = true

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receiveInterruptEvent), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Key-value observing context
    fileprivate var playerItemContext = 0

    /// Player status
    fileprivate var status:PlayerStatus = .none

    /// Play mode
    fileprivate var playMode:PlayMode = .loop
    
    /// Player
    fileprivate lazy var player:AVPlayer = AVPlayer()

    /// PlayerItem
    fileprivate var playerItem:AVPlayerItem?

    /// Playlist
    fileprivate lazy var playlist:[URL] = [URL]()
    
    /// Shuffled Indexes
    fileprivate var shuffledPlaylist:[URL]?

    /// Play index
    fileprivate lazy var playIndex: Int = 0

    /// Current play time
    fileprivate var currentTime:Double = 0.0

    /// Current play duration
    fileprivate var duration:Double = 0.0

    /// Current play available duration
    fileprivate var availableDuration:Double = 0.0

    /// Time Observer token for periodic time observer for the player. Use this property to remove the time observer.
    fileprivate var timeObserverToken:Any?

    public weak var delegate: MediaPlayerManagerDelegate?

    // MARK: Setup methods

    /// Add a periodic time observer to track the current play time.
    fileprivate func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        if timeObserverToken != nil {
            player.removeTimeObserver(timeObserverToken!)
        }
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            self?.setCurrentTime(to: time.seconds)
        }
    }

    /// Prepare to play new URL
    fileprivate func prepareToPlay() {
        guard let url = self.getPlayURL() else { return }
        self.pause()
        delegate?.mediaPlayerPlayURLDidChange(sender: self, playURL: url)
        removeNotificationsAndObservations()
        self.playerItem = nil
        setCurrentTime()
        setDuration()
        setAvailableDuration(with: 0)

        // Create asset to be played
        let asset = AVAsset(url: url)

        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        self.playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)

        addNotificationsAndObservations()

        // Associate the player item with the player
        player = AVPlayer(playerItem: self.playerItem)
    }


    // MARK: - Mutators

    /// Set Player with new playlist and play index.
    /// Only set the playlist when the new playlist has different URL(s)
    /// index will be setted when it has a different index.
    ///
    /// - Parameters:
    ///   - newPlaylist: the new playlist
    ///   - index: the new index
    public func setPlayer(with newPlaylist:[URL], playAt index:Int = 0) {
        if newPlaylist == self.playlist {
            if index != self.playIndex {
                self.setPlayIndex(to: index)
            }
        } else {
            self.setPlaylist(to: newPlaylist)
            self.setPlayIndex(to: index)
        }
    }

    /// set playIndex.
    /// If `loopingPlaylist` is true, off boundary index will be convert to either 0 or the playlist count - 1.
    /// Else remain unchange.
    ///
    /// - Parameter index: new index
    public func setPlayIndex(to index:Int) {
        guard !getPlaylist().isEmpty else { return }
        guard loopingPlaylist || (index >= 0 && index < self.playlist.count) else { return }
        self.playIndex = index < 0 ? (self.playlist.count - 1) : (index < self.playlist.count ? index : 0)
        prepareToPlay()
    }

    /// Set the playlist with given list
    fileprivate func setPlaylist(to list:[URL]) {
        self.playlist = list
    }

    /// Set the player status to given status
    fileprivate func setPlayerStatus(to status: PlayerStatus) {
        self.status = status
        self.delegate?.mediaPlayerStatusDidChange(sender: self, status: self.status)
    }

    /// Set the current play time to given time
    fileprivate func setCurrentTime(to time: Double = 0.0) {
        self.currentTime = time
        self.delegate?.mediaPlayerPlayTimeDidChange(sender: self, time: self.currentTime)
    }

    /// Update the current play item duration
    fileprivate func setDuration() {
        self.duration = playerItem?.asset.duration.seconds ?? 0.0
        self.delegate?.mediaPlayerDurationDidChange(sender: self, duration: self.duration)
    }

    /// Update the current play item available duration
    fileprivate func setAvailableDuration(with newValue:Double?) {
        self.availableDuration = newValue ?? 0.0
        self.delegate?.mediaPlayerAvailableDurationDidChange(sender: self, duration: self.availableDuration)
    }
    

    // MARK: - Accessors

    /// get player status
    public func getPlayerStatus() -> PlayerStatus {
        return self.status
    }

    /// get current playlist
    public func getPlaylist() -> [URL] {
        return self.playlist
    }

    /// get current play index
    public func getPlayIndex() -> Int {
        return self.playIndex
    }

    /// get current play URL
    public func getPlayURL() -> URL? {
        guard self.getPlayIndex() < self.getPlaylist().count else { return nil }
        return (self.getPlayMode() == .shuffle ? self.getShuffledPlaylist() : self.getPlaylist())[self.getPlayIndex()]
    }

    /// get current play time
    public func getCurrentTime() -> Double {
        return self.currentTime
    }

    /// Get duration
    public func getDuration() -> Double {
        return self.duration
    }

    /// Get available duration
    public func getAvailableDuration() -> Double {
        return self.availableDuration
    }

    // MARK: - Remote Control Methods

    /// Toggle Between Play and Pause
    public func togglePlayPause() {
        status == .playing ? pause() : play()
    }

    /// Begins playback of the current item.
    public func play() {
        if timeObserverToken == nil {
            self.addPeriodicTimeObserver()
        }
        guard playerItem != nil else { return }
        self.player.play()
        self.setPlayerStatus(to: .playing)
    }

    /// Pauses playback of the current item.
    public func pause() {
        self.player.pause()
        self.setPlayerStatus(to: .paused)
    }

    /// Play next item in playlist
    public func next() {
        self.setPlayIndex(to: self.getPlayIndex() + 1)
    }

    /// Play previous item in playlist
    public func previous() {
        self.setPlayIndex(to: self.getPlayIndex() - 1)
    }
    
    /// Check if there is next media to play
    public func hasNext() -> Bool {
        if self.getPlaylist().isEmpty { return false }
        if !loopingPlaylist {
            return self.getPlayIndex() < self.getPlaylist().count - 1
        }
        return true
    }
    
    /// Check if there is previous media to play
    public func hasPrevious() -> Bool {
        if self.getPlaylist().isEmpty { return false }
        if !loopingPlaylist {
            return self.getPlayIndex() > 0
        }
        return true
    }

    /// Play at specific time. When seek to time, player will pause automatically. To resume play call play()
    public func seekToTime(time: Double, resumePlay: Bool = true) {
        guard playerItem != nil else { return }
        if timeObserverToken != nil {
            player.removeTimeObserver(timeObserverToken!)
            timeObserverToken = nil
        }
        pause()
        let timescale = playerItem!.asset.duration.timescale
        self.player.seek(to: CMTimeMakeWithSeconds(time, timescale), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) {[weak self] (completed) in
            if completed {
                self?.setCurrentTime(to: time)
                if resumePlay {
                    self?.play()
                }
            }
        }
    }

}


// MARK: Notifications and KVO

extension MediaPlayerManager {

    /// add notification and observers for playerItem
    fileprivate func addNotificationsAndObservations() {
        // Register as an observer of the player item's status property
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: NSKeyValueObservingOptions.new, context: &playerItemContext)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: NSKeyValueObservingOptions.new, context: &playerItemContext)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: NSKeyValueObservingOptions.new, context: &playerItemContext)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    /// remove all notifications nad observers for playerItem
    fileprivate func removeNotificationsAndObservations() {
        // remove time observer and reset time, duration and availableDuration
        if timeObserverToken != nil {
            self.player.removeTimeObserver(timeObserverToken!)
            timeObserverToken = nil
        }
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }


    /// KVO
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus

            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over the status
            switch status {
            case .readyToPlay:
                self.setPlayerStatus(to: .buffering)
                self.setDuration()
                self.addPeriodicTimeObserver()
                self.play()
            case .failed:
                self.pause()
            case .unknown:
                self.pause()
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            if self.getPlayerStatus() == .playing && self.getAvailableDuration() > self.getCurrentTime() {
                play()
            } else {
                pause()
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            if self.getPlayerStatus() == .buffering && self.getAvailableDuration() > self.getCurrentTime() {
                play()
            }
        } else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            self.setAvailableDuration(with: (change?[NSKeyValueChangeKey.newKey] as? [NSValue])?.first?.timeRangeValue.duration.seconds)
        }
    }

    /// Resume Audio Session when interruption ends
    func receiveInterruptEvent(_ notification: Notification) {
        guard notification.name == Notification.Name.AVAudioSessionInterruption else { return }
        if (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue == AVAudioSessionInterruptionType.ended.rawValue {
            self.play()
        }
    }

    /// Player did finish playing current Item. If `autoNextPlay`, Player will automatically play next item, else pause and set time back to 0.0. 
    func playerDidFinishPlaying(_ notification: Notification) {
        self.pause()
        guard self.hasNext() else {
            self.seekToTime(time: 0.0, resumePlay: false)
            return
        }
        if autoNextPlay {
            switch self.getPlayMode() {
            case .loop, .shuffle:
                self.next()
            case .one:
                self.seekToTime(time: 0.0)
            }
        } else {
            self.seekToTime(time: 0.0, resumePlay: false)
        }
    }
}


extension MediaPlayerManager {
    
    /// set play mode
    public func setPlayMode(to mode: PlayMode) {
        self.playMode = mode
    }
    
    /// get play mode
    public func getPlayMode() -> PlayMode {
        return self.playMode
    }
    
    /// get shuffled playlist
    public func getShuffledPlaylist() -> [URL] {
        if self.shuffledPlaylist == nil {
            initShuffledPlaylist()
        }
        return self.shuffledPlaylist!
    }
    
    
    /// Initialize shuffled playlist
    fileprivate func initShuffledPlaylist() {
        if self.getPlaylist().count < 2 {
            self.shuffledPlaylist = self.playlist
        } else {
            repeat {
                self.shuffledPlaylist = self.getPlaylist().shuffled()
            } while self.shuffledPlaylist! == self.playlist
            
        }
    }
    
    
}


// MARK: Extensions for Shuffle Array

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in startIndex ..< endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
            if i != j {
                swap(&self[i], &self[j])
            }
        }
    }
}

extension Collection {
    /// Return a copy of `self` with its elements shuffled
    func shuffled() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffle()
        return list
    }
}
