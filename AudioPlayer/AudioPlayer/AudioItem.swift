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
    case high
    case medium
    case low
}


// MARK: - AudioItemURL

/**
`AudioItemURL` contains information about an Item URL such as its
quality.
*/
public struct AudioItemURL {
    public let quality: AudioQuality
    public let URL: Foundation.URL

    public init?(quality: AudioQuality, URL: Foundation.URL?) {
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
open class AudioItem: NSObject {
    /// Returns the available qualities
    open let soundURLs: [AudioQuality: URL]


    // MARK: Initialization

    /**
    Initializes an AudioItem.

    - parameter highQualitySoundURL:   The URL for the high quality sound.
    - parameter mediumQualitySoundURL: The URL for the medium quality sound.
    - parameter lowQualitySoundURL:    The URL for the low quality sound.

    - returns: An initialized `AudioItem` if there is at least a non-null URL.
    */
    public convenience init?(highQualitySoundURL: URL? = nil, mediumQualitySoundURL: URL? = nil, lowQualitySoundURL: URL? = nil) {
        var URLs = [AudioQuality: URL]()
        if let highURL = highQualitySoundURL {
            URLs[.high] = highURL
        }
        if let mediumURL = mediumQualitySoundURL {
            URLs[.medium] = mediumURL
        }
        if let lowURL = lowQualitySoundURL {
            URLs[.low] = lowURL
        }
        self.init(soundURLs: URLs)
    }

    /**
    Initializes an `AudioItem`.

    - parameter soundURLs: The URLs of the sound associated with its quality wrapped in a `Dictionary`.

    - returns: An initialized `AudioItem` if there is at least an URL in the `soundURLs` dictionary.
    */
    public init?(soundURLs: [AudioQuality: URL]) {
        self.soundURLs = soundURLs
        super.init()

        if soundURLs.count == 0 {
            return nil
        }
    }


    // MARK: Quality selection

    /// Returns the highest quality URL found or nil if no URLs are available
    open var highestQualityURL: AudioItemURL {
        return (AudioItemURL(quality: .high, URL: soundURLs[.high]) ??
            AudioItemURL(quality: .medium, URL: soundURLs[.medium]) ??
            AudioItemURL(quality: .low, URL: soundURLs[.low]))!
    }

    /// Returns the medium quality URL found or nil if no URLs are available
    open var mediumQualityURL: AudioItemURL {
        return (AudioItemURL(quality: .medium, URL: soundURLs[.medium]) ??
            AudioItemURL(quality: .low, URL: soundURLs[.low]) ??
            AudioItemURL(quality: .high, URL: soundURLs[.high]))!
    }

    /// Returns the lowest quality URL found or nil if no URLs are available
    open var lowestQualityURL: AudioItemURL {
        return (AudioItemURL(quality: .low, URL: soundURLs[.low]) ??
            AudioItemURL(quality: .medium, URL: soundURLs[.medium]) ??
            AudioItemURL(quality: .high, URL: soundURLs[.high]))!
    }


    // MARK: Additional properties

    /**
    The artist of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    open dynamic var artist: String?

    /**
    The title of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    open dynamic var title: String?

    /**
    The album of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    open dynamic var album: String?

    /**
    The track count of the item's album.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    open dynamic var trackCount: NSNumber?

    /**
    The track number of the item in its album.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    open dynamic var trackNumber: NSNumber?

    #if os(iOS)
    /**
    The artwork image of the item.

    This can change over time which is why the property is dynamic. It enables KVO on the property.
    */
    open dynamic var artworkImage: UIImage?
    #endif


    // MARK: KVO

    internal static var ap_KVOItems: [String] {
        return ["artist", "title", "album", "trackCount", "trackNumber", "artworkImage"]
    }


    // MARK: Metadata

    open func parseMetadata(_ items: [AVMetadataItem]) {
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
                            artworkImage = ($0.value as? Data).map { UIImage(data: $0) } ?? nil
                        }
                    #endif
                }
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////
