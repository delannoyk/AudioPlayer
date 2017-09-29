//
//  AudioItem_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 13/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
import AVFoundation
@testable import AudioPlayer

class AudioItem_Tests: XCTestCase {
    func testItemInitializationFailsIfNoValidURLIsGiven() {
        XCTAssertNil(AudioItem(soundURLs: [:]))
        XCTAssertNil(AudioItem(highQualitySoundURL: nil, mediumQualitySoundURL: nil, lowQualitySoundURL: nil))
    }

    func testItemXXXestURL() {
        let urlLow = URL(string: "https://github.com")!
        let urlMedium = URL(string: "https://github.com/delannoyk")!
        let urlHigh = URL(string: "https://github.com/delannoyk/AudioPlayer")!

        let itemLowOnly = AudioItem(lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemLowOnly?.lowestQualityURL.url, urlLow)
        XCTAssertEqual(itemLowOnly?.mediumQualityURL.url, urlLow)
        XCTAssertEqual(itemLowOnly?.highestQualityURL.url, urlLow)

        let itemMediumOnly = AudioItem(mediumQualitySoundURL: urlMedium)
        XCTAssertEqual(itemMediumOnly?.lowestQualityURL.url, urlMedium)
        XCTAssertEqual(itemMediumOnly?.mediumQualityURL.url, urlMedium)
        XCTAssertEqual(itemMediumOnly?.highestQualityURL.url, urlMedium)

        let itemHighOnly = AudioItem(highQualitySoundURL: urlHigh)
        XCTAssertEqual(itemHighOnly?.lowestQualityURL.url, urlHigh)
        XCTAssertEqual(itemHighOnly?.mediumQualityURL.url, urlHigh)
        XCTAssertEqual(itemHighOnly?.highestQualityURL.url, urlHigh)

        let itemLowMediumOnly = AudioItem(mediumQualitySoundURL: urlMedium, lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemLowMediumOnly?.lowestQualityURL.url, urlLow)
        XCTAssertEqual(itemLowMediumOnly?.mediumQualityURL.url, urlMedium)
        XCTAssertEqual(itemLowMediumOnly?.highestQualityURL.url, urlMedium)

        let itemLowHighOnly = AudioItem(highQualitySoundURL: urlHigh, lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemLowHighOnly?.lowestQualityURL.url, urlLow)
        XCTAssertEqual(itemLowHighOnly?.mediumQualityURL.url, urlLow)
        XCTAssertEqual(itemLowHighOnly?.highestQualityURL.url, urlHigh)

        let itemMediumHighOnly = AudioItem(highQualitySoundURL: urlHigh, mediumQualitySoundURL: urlMedium)
        XCTAssertEqual(itemMediumHighOnly?.lowestQualityURL.url, urlMedium)
        XCTAssertEqual(itemMediumHighOnly?.mediumQualityURL.url, urlMedium)
        XCTAssertEqual(itemMediumHighOnly?.highestQualityURL.url, urlHigh)

        let itemFull = AudioItem(highQualitySoundURL: urlHigh, mediumQualitySoundURL: urlMedium, lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemFull?.lowestQualityURL.url, urlLow)
        XCTAssertEqual(itemFull?.mediumQualityURL.url, urlMedium)
        XCTAssertEqual(itemFull?.highestQualityURL.url, urlHigh)
    }

    func testItemURLForQuality() {
        let urlLow = URL(string: "https://github.com")!
        let urlMedium = URL(string: "https://github.com/delannoyk")!
        let urlHigh = URL(string: "https://github.com/delannoyk/AudioPlayer")!

        let itemLowOnly = AudioItem(lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemLowOnly?.url(for: .high).quality, .low)
        XCTAssertEqual(itemLowOnly?.url(for: .medium).quality, .low)
        XCTAssertEqual(itemLowOnly?.url(for: .low).quality, .low)

        let itemMediumOnly = AudioItem(mediumQualitySoundURL: urlMedium)
        XCTAssertEqual(itemMediumOnly?.url(for: .high).quality, .medium)
        XCTAssertEqual(itemMediumOnly?.url(for: .medium).quality, .medium)
        XCTAssertEqual(itemMediumOnly?.url(for: .low).quality, .medium)

        let itemHighOnly = AudioItem(highQualitySoundURL: urlHigh)
        XCTAssertEqual(itemHighOnly?.url(for: .high).quality, .high)
        XCTAssertEqual(itemHighOnly?.url(for: .medium).quality, .high)
        XCTAssertEqual(itemHighOnly?.url(for: .low).quality, .high)

        let itemLowMediumOnly = AudioItem(mediumQualitySoundURL: urlMedium, lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemLowMediumOnly?.url(for: .high).quality, .medium)
        XCTAssertEqual(itemLowMediumOnly?.url(for: .medium).quality, .medium)
        XCTAssertEqual(itemLowMediumOnly?.url(for: .low).quality, .low)

        let itemLowHighOnly = AudioItem(highQualitySoundURL: urlHigh, lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemLowHighOnly?.url(for: .high).quality, .high)
        XCTAssertEqual(itemLowHighOnly?.url(for: .medium).quality, .low)
        XCTAssertEqual(itemLowHighOnly?.url(for: .low).quality, .low)

        let itemMediumHighOnly = AudioItem(highQualitySoundURL: urlHigh, mediumQualitySoundURL: urlMedium)
        XCTAssertEqual(itemMediumHighOnly?.url(for: .high).quality, .high)
        XCTAssertEqual(itemMediumHighOnly?.url(for: .medium).quality, .medium)
        XCTAssertEqual(itemMediumHighOnly?.url(for: .low).quality, .medium)

        let itemFull = AudioItem(highQualitySoundURL: urlHigh, mediumQualitySoundURL: urlMedium, lowQualitySoundURL: urlLow)
        XCTAssertEqual(itemFull?.url(for: .high).quality, .high)
        XCTAssertEqual(itemFull?.url(for: .medium).quality, .medium)
        XCTAssertEqual(itemFull?.url(for: .low).quality, .low)
    }

    func testParseMetadata() {
        let imageURL = Bundle(for: type(of: self)).url(forResource: "image", withExtension: "png")!
        let imageData = NSData(contentsOf: imageURL)!

        let metadata = [
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyTitle, value: "title" as NSString),
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyArtist, value: "artist" as NSString),
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyAlbumName, value: "album" as NSString),
            FakeMetadataItem(commonKey: AVMetadataKey.id3MetadataKeyTrackNumber, value: NSNumber(value: 1)),
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyArtwork, value: imageData)
        ]

        let item = AudioItem(soundURLs: [.low: URL(string: "https://github.com")!])
        item?.parseMetadata(metadata)

        XCTAssertEqual(item?.title, "title")
        XCTAssertEqual(item?.artist, "artist")
        XCTAssertEqual(item?.album, "album")
        XCTAssertEqual(item?.trackNumber?.intValue, 1)
        XCTAssertNotNil(item?.artworkImage)
    }

    func testParseMetadataDoesNotOverrideUserProperties() {
        let item = AudioItem(soundURLs: [.low: URL(string: "https://github.com")!])
        item?.title = "title"
        item?.artist = "artist"
        item?.album = "album"
        item?.trackNumber = NSNumber(value: 1)

        let metadata = [
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyTitle, value: "abc" as NSString),
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyArtist, value: "def" as NSString),
            FakeMetadataItem(commonKey: AVMetadataKey.commonKeyAlbumName, value: "ghi" as NSString),
            FakeMetadataItem(commonKey: AVMetadataKey.id3MetadataKeyTrackNumber, value: NSNumber(value: 10))
        ]
        item?.parseMetadata(metadata)

        XCTAssertEqual(item?.title, "title")
        XCTAssertEqual(item?.artist, "artist")
        XCTAssertEqual(item?.album, "album")
        XCTAssertEqual(item?.trackNumber?.intValue, 1)
    }
}
