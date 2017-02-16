//
//  JWPlayerTrackSlider.swift
//  JWMediaManager
//
//  Created by Jianxiong Wang on 2/16/17.
//  Copyright © 2017 JianxiongWang. All rights reserved.
//

import UIKit

let COLOR_MAGNESIUM = UIColor(red: 179/255, green: 179/255, blue: 179/255, alpha: 1)
let COLOR_ORANGE = UIColor(red: 1, green: 102/255, blue: 0, alpha: 1)

class JWPlayerTrackSlider: UISlider {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    
    var bufferColor:UIColor = COLOR_ORANGE.withAlphaComponent(0.3) {
        willSet {
            bufferProgressView.progressTintColor = newValue
        }
    }
    
    var minTrackColor:UIColor = COLOR_ORANGE {
        willSet {
            self.minimumTrackTintColor = newValue
        }
    }
    
    var maxTrackColor:UIColor = COLOR_MAGNESIUM {
        willSet {
            bufferProgressView.backgroundColor = newValue
        }
    }
        
    var trackRectHeight:CGFloat = 2
    
    fileprivate var bufferProgressView:UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.minimumTrackTintColor = minTrackColor
        self.maximumTrackTintColor = UIColor.clear
        setupBufferProgressView()
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = CGRect(origin: CGPoint(x: bounds.minX, y: bounds.midY - trackRectHeight / 2), size: CGSize(width: bounds.width, height: trackRectHeight))
        return rect
    }
    
    fileprivate func setupBufferProgressView() {
        self.bufferProgressView = UIProgressView(frame: trackRect(forBounds: self.bounds))
        self.bufferProgressView.backgroundColor = COLOR_MAGNESIUM
        self.bufferProgressView.progressTintColor = bufferColor
        self.bufferProgressView.progress = 0
        self.addSubview(self.bufferProgressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.bufferProgressView.frame = trackRect(forBounds: self.bounds)
    }
    
    func updateBufferProgress(withProgress progress: Float) {
        self.bufferProgressView?.progress = progress
    }

}
