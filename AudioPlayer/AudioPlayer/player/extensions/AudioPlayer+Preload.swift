//
//  AudioPlayer+Preload.swift
//  AudioPlayer
//
//  Created by Daniel Dam Freiling on 11/05/2017.
//  Copyright © 2017 Kevin Delannoy. All rights reserved.
//

import Foundation
import AVFoundation

extension AudioPlayer {
    
    public static let assetPreloadKeys = ["tracks", "playable"]
    
    public func clearAssetCache() {
        cachedAssets = [:]
    }
    
    public func getAVURLAsset(forUrl: URL) -> AVURLAsset {
        if let asset = cachedAssets[forUrl],
               asset.isPlayable {
            return asset
        } else {
            let asset = AVURLAsset(url: forUrl)
            cachedAssets[forUrl] = asset
            return asset
        }
    }
    
    public func getPlayerItem(forUrl: URL) -> AVPlayerItem {
        let asset = getAVURLAsset(forUrl: forUrl)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: AudioPlayer.assetPreloadKeys)
        return playerItem
    }
    
    public func preloadItemAsset(asset: AVURLAsset, onComplete: @escaping (AVURLAsset?) -> Void) {
        asset.loadValuesAsynchronously(forKeys: AudioPlayer.assetPreloadKeys) {
            if (self.assetPreloadKeysAreLoaded(asset: asset) == false) {
                //loading failed, invalidate cached asset
                self.cachedAssets.removeValue(forKey: asset.url)
                onComplete(nil)
            } else {
                onComplete(asset)
            }
        }
    }
    
    public func preloadNextItemAsset() {
        if hasNext, let queue = queue {
            let nextPosition = queue.nextPosition
            let item = queue.items[nextPosition]
            let urlInfo = item.highestQualityURL
            let asset = getAVURLAsset(forUrl: urlInfo.url)
            print("preloading queue idx: \(nextPosition)")
            preloadItemAsset(asset: asset) { asset in
                if (asset == nil) {
                    print("error preloading queue idx: \(nextPosition)")
                } else {
                    print("preloaded queue idx: \(nextPosition)!")
                }
            }
        }
    }
    
    private func assetPreloadKeysAreLoaded(asset: AVURLAsset) -> Bool {
        for key in AudioPlayer.assetPreloadKeys {
            var error: NSError?
            let result = asset.statusOfValue(forKey: key, error: &error)
            if (result != .loaded || error != nil) {
                print("AVAsset failed to load key '\(key)': (\(String(describing: result))) \(String(describing: error?.localizedDescription))")
                return false
            }
        }
        return true
    }
}
