//
//  AudioItem.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 26/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import Foundation
#endif
import AVFoundation

// MARK: - AudioQuality

/**
`AudioQuality` differentiates qualities for audio.

- `High`:   The highest quality.
- `Medium`: The quality between highest and lowest.
- `Low`:    The lowest quality.
*/
public enum AudioQuality {
    case High
    case Medium
    case Low
}


// MARK: - AudioItemURL

/**
`AudioItemURL` contains information about an Item URL such as its
quality.
*/
public struct AudioItemURL {
    public let quality: AudioQuality
    public let URL: NSURL

    public init?(quality: AudioQuality, URL: NSURL?) {
        if let URL = URL {
            self.quality = quality
            self.URL = URL
        }
        else {
            return nil
        }
    }
}


// MARK: - AudioItem

/**
An `AudioItem` instance contains every piece of information needed for an `AudioPlayer` to play.

URLs can be remote or local.
*/
public class AudioItem: NSObject {
    /// Returns the available qualities
    public let soundURLs: [AudioQuality: NSURL]


    // MARK: Initialization

    /**
    Initializes an AudioItem.

    - parameter highQualitySoundURL:   The URL for the high quality sound.
    - parameter mediumQualitySoundURL: The URL for the medium quality sound.
    - parameter lowQualitySoundURL:    The URL for the low quality sound.

    - returns: An initialized `AudioItem` if there is at least a non-null URL.
    */
    public convenience init?(highQualitySoundURL: NSURL? = nil, mediumQualitySoundURL: NSURL? = nil, lowQualitySoundURL: NSURL? = nil) {
        var URLs = [AudioQuality: NSURL]()
        if let highURL = highQualitySoundURL {
            URLs[.High] = highURL
        }
        if let mediumURL = mediumQualitySoundURL {
            URLs[.Medium] = mediumURL
        }
        if let lowURL = lowQualitySoundURL {
            URLs[.Low] = lowURL
        }
        self.init(soundURLs: URLs)
    }

    /**
    Initializes an `AudioItem`.

    - parameter soundURLs: The URLs of the sound associated with its quality wrapped in a `Dictionary`.

    - returns: An initialized `AudioItem` if there is at least an URL in the `soundURLs` dictionary.
    */
    public init?(soundURLs: [AudioQuality: NSURL]) {
        self.soundURLs = soundURLs
        super.init()

        if soundURLs.count == 0 {
            return nil
        }
    }


    // MARK: Quality selection

    /// Returns the highest quality URL found or nil if no URLs are available
    public var highestQualityURL: AudioItemURL {
        return (AudioItemURL(quality: .High, URL: soundURLs[.High]) ??
            AudioItemURL(quality: .Medium, URL: soundURLs[.Medium]) ??
            AudioItemURL(quality: .Low, URL: soundURLs[.Low]))!
    }

    /// Returns the medium quality URL found or nil if no URLs are available
    public var mediumQualityURL: AudioItemURL {
        return (AudioItemURL(quality: .Medium, URL: soundURLs[.Medium]) ??
            AudioItemURL(quality: .Low, URL: soundURLs[.Low]) ??
            AudioItemURL(quality: .High, URL: soundURLs[.High]))!
    }

    /// Returns the lowest quality URL found or nil if no URLs are available
    public var lowestQualityURL: AudioItemURL {
        return (AudioItemURL(quality: .Low, URL: soundURLs[.Low]) ??
            AudioItemURL(quality: .Medium, URL: soundURLs[.Medium]) ??
            AudioItemURL(quality: .High, URL: soundURLs[.High]))!
    }


    // MARK: Additional properties

    /**
    The artist of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    public dynamic var artist: String?

    /**
    The title of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    public dynamic var title: String?

    /**
    The album of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    public dynamic var album: String?

    /**
    The track count of the item's album.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    public dynamic var trackCount: NSNumber?

    /**
    The track number of the item in its album.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    public dynamic var trackNumber: NSNumber?

    #if os(iOS)
    /**
    The artwork image of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    public dynamic var artworkImage: UIImage?
    #endif


    // MARK: KVO

    internal static var ap_KVOItems: [String] {
        return ["artist", "title", "album", "trackCount", "trackNumber", "artworkImage"]
    }


    // MARK: Metadata

    public func parseMetadata(items: [AVMetadataItem]) {
        items.forEach {
            if let commonKey = $0.commonKey {
                switch commonKey {
                case AVMetadataCommonKeyTitle where title == nil:
                    title = $0.value as? String
                case AVMetadataCommonKeyArtist where artist == nil:
                    artist = $0.value as? String
                case AVMetadataCommonKeyAlbumName where album == nil:
                    album = $0.value as? String
                case AVMetadataID3MetadataKeyTrackNumber where trackNumber == nil:
                    trackNumber = $0.value as? NSNumber
                default:
                    #if os(iOS)
                        if commonKey == AVMetadataCommonKeyArtwork && artworkImage == nil {
                            artworkImage = ($0.value as? NSData).map { UIImage(data: $0) } ?? nil
                        }
                    #endif
                }
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////
