import UIKit
import XCTest
import JWMediaManager
import AVFoundation
import Nimble

class Tests: XCTestCase {
    
    let testNotificationPlayTimeDidChange = Notification(name: Notification.Name(rawValue: "testNotificationPlayTimeDidChange"))
    let testNotificationPlayURLDidChange = Notification(name: Notification.Name(rawValue: "testNotificationPlayURLDidChange"))
    let testNotificationPlayDurationDidChange = Notification(name: Notification.Name(rawValue: "testNotificationPlayDurationDidChange"))
    let testNotificationPlayStatusDidChange = Notification(name: Notification.Name(rawValue: "testNotificationPlayStatusDidChange"))
    let testNotificationPlayAvailableDurationDidChange = Notification(name: Notification.Name(rawValue: "testNotificationPlayAvailableDurationDidChange"))
    
    var manager:MediaPlayerManager!
    var list:[URL]!
    
    /// local sample play files
    func initPlaylist() -> [URL] {
        
        // online musics
        return [
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

    }
    
    override func setUp() {
        super.setUp()
        manager = MediaPlayerManager()
        list = initPlaylist()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        manager = nil
        list = nil
    }
    
//    func testExample() {
//        // This is an example of a functional test case.
//        XCTAssert(true, "Pass")
//    }
//    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    func testInitialStates() {
        expect(self.manager.status).to(equal(PlayerStatus.none))
        expect(self.manager.playMode).to(equal(PlayMode.loop))
        expect(self.manager.player.currentItem).to(beNil())
        expect(self.manager.playlist).to(equal([URL]()))
        expect(self.manager.playIndex).to(equal(0))
        expect(self.manager.currentTime).to(equal(0.0))
        expect(self.manager.duration).to(equal(0.0))
        expect(self.manager.availableDuration).to(equal(0.0))
        expect(self.manager.loopingPlaylist).to(equal(true))
        expect(self.manager.autoNextPlay).to(equal(true))
        expect(self.manager.autoResumeAfterInterruptEvent).to(equal(true))
    }
    
    
    var playerURLDidChangeContext = 0
    
    func testSetPlayer() {
        manager = MediaPlayerManager()
        let testIndexes = [-2, -1, 0, 5, 10, 11, 15]
        let indexesWithoutLoopingPlaylist = [0,0,0,5,10,10,10]
        let indexesWithLoopingPlaylist = [10,10,0,5,10,0,0]
        
        // case when playlist is the same
        manager.delegate = self
        self.manager.setPlayer(with: self.list, playAt: 0)
        expect(self.playerURLDidChangeContext).toEventually(equal(1), timeout: 1, pollInterval: 1, description: nil)
        self.manager.setPlayer(with: self.list, playAt: 0)
        expect(self.playerURLDidChangeContext).toEventually(equal(1), timeout: 1, pollInterval: 1, description: nil)
        self.manager.setPlayer(with: self.list, playAt: 2)
        expect(self.playerURLDidChangeContext).toEventually(equal(2), timeout: 1, pollInterval: 1, description: nil)
        self.manager.setPlayer(with: Array(self.list[0...5]), playAt: 2)
        expect(self.playerURLDidChangeContext).toEventually(equal(3), timeout: 1, pollInterval: 1, description: nil)
        self.manager.delegate = nil
        
        // case where loopingPlaylist is true
        for i in 0..<testIndexes.count {
            manager.setPlayer(with: self.list, playAt: testIndexes[i])
            expect(self.manager.playlist).to(equal(self.list))
            expect(self.manager.playIndex).to(equal(indexesWithLoopingPlaylist[i]))
        }

        // case where loopingPlaylist is false
        manager.loopingPlaylist = false
        for i in 0..<testIndexes.count {
            manager.setPlayer(with: self.list, playAt: testIndexes[i])
            expect(self.manager.playlist).to(equal(self.list))
            expect(self.manager.playIndex).to(equal(indexesWithoutLoopingPlaylist[i]))
        }

    }
    
    func testSetPlayIndex() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        let testIndexes = [-2, -1, 0, 5, 10, 11, 15]
        let indexesWithoutLoopingPlaylist = [0,0,0,5,10,10,10]
        let indexesWithLoopingPlaylist = [10,10,0,5,10,0,0]
        
        // case where loopingPlaylist is true
        for i in 0..<testIndexes.count {
            self.manager.setPlayIndex(to: testIndexes[i])
            expect(self.manager.playIndex).to(equal(indexesWithLoopingPlaylist[i]))
        }
        
        // case where loopingPlaylist is false
        manager.loopingPlaylist = false
        for i in 0..<testIndexes.count {
            self.manager.setPlayIndex(to: testIndexes[i])
            expect(self.manager.playIndex).to(equal(indexesWithoutLoopingPlaylist[i]))
        }
    }
    
    func testGetPlayURL() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        let testIndexes = [-2, -1, 0, 5, 10, 11, 15]
        let indexesWithoutLoopingPlaylist = [0,0,0,5,10,10,10]
        let indexesWithLoopingPlaylist = [10,10,0,5,10,0,0]
        
        // case where loopingPlaylist is true
        for i in 0..<testIndexes.count {
            self.manager.setPlayIndex(to: testIndexes[i])
            expect(self.manager.getPlayURL()).to(equal(self.list[indexesWithLoopingPlaylist[i]]))
        }
        
        // case where loopingPlaylist is false
        manager.loopingPlaylist = false
        for i in 0..<testIndexes.count {
            self.manager.setPlayIndex(to: testIndexes[i])
            expect(self.manager.getPlayURL()).to(equal(self.list[indexesWithoutLoopingPlaylist[i]]))
        }
    }
    
    
    func testPause() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        expect(self.manager.player.rate).toEventually(equal(1.0), timeout: 5, pollInterval: 1)
        expect(self.manager.status).to(equal(PlayerStatus.playing))
        self.manager.pause()
        expect(self.manager.player.rate).to(equal(0.0))
        expect(self.manager.status).to(equal(PlayerStatus.paused))
    }
    
    func testPlay() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        expect(self.manager.player.rate).toEventually(equal(1.0), timeout: 5, pollInterval: 1)
        expect(self.manager.status).to(equal(PlayerStatus.playing))
        self.manager.pause()
        expect(self.manager.player.rate).to(equal(0.0))
        expect(self.manager.status).to(equal(PlayerStatus.paused))
        self.manager.play()
        expect(self.manager.player.rate).to(equal(1.0))
        expect(self.manager.status).to(equal(PlayerStatus.playing))
    }
    
    func testNext() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        manager.next()
        expect(self.manager.playIndex).to(equal(1))
        manager.setPlayIndex(to: self.list.count - 1)
        manager.loopingPlaylist = false
        manager.next()
        expect(self.manager.playIndex).to(equal(self.list.count - 1))
        manager.loopingPlaylist = true
        manager.next()
        expect(self.manager.playIndex).to(equal(0))
    }

    func testPrevious() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list, playAt: self.list.count - 1)
        manager.previous()
        expect(self.manager.playIndex).to(equal(self.list.count - 2))
        manager.setPlayIndex(to: 0)
        manager.loopingPlaylist = false
        manager.previous()
        expect(self.manager.playIndex).to(equal(0))
        manager.loopingPlaylist = true
        manager.previous()
        expect(self.manager.playIndex).to(equal(self.list.count - 1))
    }
    
    func testTogglePlayPause() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        expect(self.manager.player.rate).toEventually(equal(1.0), timeout:5)
        manager.togglePlayPause()
        expect(self.manager.player.rate).to(equal(0.0))
        manager.togglePlayPause()
        expect(self.manager.player.rate).to(equal(1.0))
    }
    
    func testHasNext() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list, playAt: 5)
        expect(self.manager.hasNext()).to(beTrue())
        manager.setPlayIndex(to: self.list.count - 1)
        expect(self.manager.hasNext()).to(beTrue())
        manager.loopingPlaylist = false
        expect(self.manager.hasNext()).to(beFalse())
    }
    
    func testHasPrevious() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list, playAt: 5)
        expect(self.manager.hasPrevious()).to(beTrue())
        manager.setPlayIndex(to: 0)
        expect(self.manager.hasPrevious()).to(beTrue())
        manager.loopingPlaylist = false
        expect(self.manager.hasPrevious()).to(beFalse())
    }
    
    func testSeekToTime() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        expect(self.manager.player.rate).toEventually(equal(1.0), timeout:5)
        manager.seekToTime(time: 5, resumePlay: false)
        expect(self.manager.player.currentTime().seconds).toEventually(beCloseTo(5))
        expect(self.manager.player.rate).toEventually(equal(0.0), timeout:3)
        
        manager.seekToTime(time: 10, resumePlay: true)
        expect(self.manager.player.currentTime().seconds).toEventually(beCloseTo(10))
        expect(self.manager.player.rate).toEventually(equal(1.0), timeout: 5)
    }
    
    func testDuration() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        expect(self.manager.duration).toNotEventually(equal(0.0), timeout:5)
        let duration = self.manager.duration
        manager.next()
        expect(self.manager.duration).to(equal(0.0))
        expect(self.manager.duration).toNotEventually(equal(0.0), timeout:5)
        expect(self.manager.duration).toNot(equal(duration))
    }
    
    func testAvailableDuration() {
        manager = MediaPlayerManager()
        manager.setPlayer(with: self.list)
        expect(self.manager.availableDuration).toNotEventually(equal(0.0), timeout: 5)
        let duration = self.manager.availableDuration
        expect(self.manager.player.currentItem?.loadedTimeRanges.first?.timeRangeValue.duration.seconds).to(beCloseTo(duration))
        manager.next()
        expect(self.manager.availableDuration).to(equal(0.0))
        expect(self.manager.availableDuration).toNotEventually(equal(0.0), timeout:5)
        expect(self.manager.player.currentItem?.loadedTimeRanges.first?.timeRangeValue.duration.seconds).to(beCloseTo(self.manager.availableDuration))
    }

}


// MARK: - Media Player Manager Delegates

extension Tests: MediaPlayerManagerDelegate {
    
    func mediaPlayerPlayTimeDidChange(_ sender: MediaPlayerManager, time: Double) {
        print("Time changed: \(time)")
        NotificationCenter.default.post(testNotificationPlayTimeDidChange)
    }
    
    func mediaPlayerPlayURLDidChange(_ sender: MediaPlayerManager, playURL: URL?) {
        print("Play url did change: \(playURL?.path)")
        self.playerURLDidChangeContext += 1
//        NotificationCenter.default.post(testNotificationPlayURLDidChange)
    }
    
    func mediaPlayerDurationDidChange(_ sender: MediaPlayerManager, duration: Double) {
        print("Play Duration changed: \(duration)")
        NotificationCenter.default.post(testNotificationPlayDurationDidChange)
    }
    
    func mediaPlayerStatusDidChange(_ sender: MediaPlayerManager, status: PlayerStatus) {
        print("Player Status did change: \(status)")
        NotificationCenter.default.post(testNotificationPlayStatusDidChange)

    }
    
    func mediaPlayerAvailableDurationDidChange(_ sender: MediaPlayerManager, duration: Double) {
        print("Available duration changed: \(duration)")
        NotificationCenter.default.post(testNotificationPlayAvailableDurationDidChange)

    }
}
