//
//  CMTime+NSTimeIntervalValue.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 11/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import CoreMedia

extension CMTime {
    var timeIntervalValue: NSTimeInterval? {
        let seconds = CMTimeGetSeconds(self)
        if !isnan(seconds) {
            return NSTimeInterval(seconds)
        }
        return nil
    }
}
