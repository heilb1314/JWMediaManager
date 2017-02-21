//
//  MediaPlayerManager.swift
//  JWMediaManager
//
//  Created by Jianxiong Wang on 2/15/17.
//  Copyright © 2017 JianxiongWang. All rights reserved.
//

import Foundation
import AVFoundation

public enum PlayerStatus:Int {
    case none, buffering, playing, paused
}

public enum PlayMode:Int {
    case loop, one, shuffle
}

public protocol MediaPlayerManagerDelegate:class {

    /// Player play time did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - time: the new play time
    func mediaPlayerPlayTimeDidChange(_ sender: MediaPlayerManager, time:Double)


    /// Player current play item duration did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - duration: new duration
    func mediaPlayerDurationDidChange(_ sender: MediaPlayerManager, duration: Double)


    /// Player current play item available duration did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - duration: new available duration
    func mediaPlayerAvailableDurationDidChange(_ sender: MediaPlayerManager, duration: Double)


    /// Player Status did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - status: new status
    func mediaPlayerStatusDidChange(_ sender: MediaPlayerManager, status: PlayerStatus)

    /// Player play item did change
    ///
    /// - Parameters:
    ///   - sender: MediaPlayerManager
    ///   - playItem: new playItem
    func mediaPlayerPlayURLDidChange(_ sender: MediaPlayerManager, playURL: URL?)
}


open class MediaPlayerManager:NSObject
{

    // MARK: Public Fields

    /// looping playlist or not. If true, when index passes the largest index, the index goes back to 0, and vice versa.
    open var loopingPlaylist:Bool = true

    /// If true, next play item will be loaded automatically after the previous one.
    open var autoNextPlay:Bool = true
    
    /// Resume play after Interruption
    open var autoResumeAfterInterruptEvent:Bool = true
    
    /// Media Player Manager Delegate
    open weak var delegate: MediaPlayerManagerDelegate?
    
    /// Play mode
    open var playMode:PlayMode = .loop

    /// Player status
    public fileprivate(set) var status:PlayerStatus = .none {
        didSet {
            if oldValue != status {
                self.delegate?.mediaPlayerStatusDidChange(self, status: self.status)
            }
        }
    }
    
    /// Player
    public fileprivate(set) lazy var player:AVPlayer = AVPlayer()

    /// PlayerItem
    public fileprivate(set) var playerItem:AVPlayerItem?

    /// Playlist
    public fileprivate(set) lazy var playlist:[URL] = [URL]()

    /// Play index
    public fileprivate(set) lazy var playIndex: Int = 0

    /// Current play time
    public fileprivate(set) lazy var currentTime:Double = 0.0

    /// Current play duration
    public fileprivate(set) lazy var duration:Double = 0.0

    /// Current play available duration
    public fileprivate(set) lazy var availableDuration:Double = 0.0

    
    // MARK: Private Fields
    
    // Key-value observing context
    fileprivate var playerItemContext = 0
    
    /// Time Observer token for periodic time observer for the player. Use this property to remove the time observer.
    fileprivate var timeObserverToken:Any?
    
    
    // MARK: Init and Deinit
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receiveInterruptEvent), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
    }
    
    deinit {
        if playerItem != nil {
            removeNotificationsAndObservations()
        }
        NotificationCenter.default.removeObserver(self)
    }


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
        delegate?.mediaPlayerPlayURLDidChange(self, playURL: url)
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
        self.status = .buffering
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
        guard !playlist.isEmpty else { return }
        guard loopingPlaylist || (index >= 0 && index < self.playlist.count) else { return }
        self.playIndex = index < 0 ? (self.playlist.count - 1) : (index < self.playlist.count ? index : 0)
        prepareToPlay()
    }

    /// Set the playlist with given list
    fileprivate func setPlaylist(to list:[URL]) {
        self.playlist = list
    }

    /// Set the current play time to given time
    fileprivate func setCurrentTime(to time: Double = 0.0) {
        self.currentTime = time
        self.delegate?.mediaPlayerPlayTimeDidChange(self, time: self.currentTime)
    }

    /// Update the current play item duration
    fileprivate func setDuration() {
        self.duration = playerItem?.asset.duration.seconds ?? 0.0
        self.delegate?.mediaPlayerDurationDidChange(self, duration: self.duration)
    }

    /// Update the current play item available duration
    fileprivate func setAvailableDuration(with newValue:Double?) {
        self.availableDuration = newValue ?? 0.0
        self.delegate?.mediaPlayerAvailableDurationDidChange(self, duration: self.availableDuration)
    }
    

    // MARK: - Accessors

    /// get current play URL
    public func getPlayURL() -> URL? {
        guard self.playIndex >= 0 && self.playIndex < self.playlist.count else { return nil }
        return self.playlist[self.playIndex]
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
        self.status = .playing
    }

    /// Pauses playback of the current item.
    public func pause() {
        self.player.pause()
        self.status = .paused
    }

    /// Play next item in playlist
    public func next() {
        self.setPlayIndex(to: self.playMode == .shuffle ? self.getShufflePlayIndex() : self.playIndex + 1)
    }

    /// Play previous item in playlist
    public func previous() {
        self.setPlayIndex(to: self.playMode == .shuffle ? self.getShufflePlayIndex() : self.playIndex - 1)
    }
    
    /// Check if there is next media to play
    public func hasNext() -> Bool {
        if self.playlist.isEmpty { return false }
        if self.playMode == .shuffle { return true }
        if !loopingPlaylist {
            return self.playIndex < self.playlist.count - 1
        }
        return true
    }
    
    /// Check if there is previous media to play
    public func hasPrevious() -> Bool {
        if self.playlist.isEmpty { return false }
        if self.playMode == .shuffle { return true }
        if !loopingPlaylist {
            return self.playIndex > 0
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
        self.status = .none
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
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
                self.setDuration()
                self.addPeriodicTimeObserver()
                if self.status != .paused {
                    self.play()
                }
            case .failed:
                self.pause()
            case .unknown:
                self.pause()
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            if self.status == .playing && self.availableDuration > self.currentTime {
                play()
            } else {
                pause()
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            if self.status == .buffering && self.availableDuration > self.currentTime {
                play()
            }
        } else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            self.setAvailableDuration(with: (change?[NSKeyValueChangeKey.newKey] as? [NSValue])?.first?.timeRangeValue.duration.seconds)
        }
    }

    /// Resume Audio Session when interruption ends
    func receiveInterruptEvent(_ notification: Notification) {
        guard notification.name == Notification.Name.AVAudioSessionInterruption else { return }
        if self.autoResumeAfterInterruptEvent && (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue == AVAudioSessionInterruptionType.ended.rawValue {
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
            switch self.playMode {
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


// MARK: - Play mode extension

extension MediaPlayerManager {
    
    /// get shuffle play index.
    fileprivate func getShufflePlayIndex() -> Int {
        guard self.playlist.count > 1 else { return 0 }
        var randIndex = 0
        repeat {
            randIndex = Int(arc4random_uniform(UInt32(self.playlist.count)))
        } while randIndex == self.playIndex
        return randIndex
    }
    
}

