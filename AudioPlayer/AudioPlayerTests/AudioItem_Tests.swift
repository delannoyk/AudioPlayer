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
        let URLLow = NSURL(string: "https://github.com")!
        let URLMedium = NSURL(string: "https://github.com/delannoyk")!
        let URLHigh = NSURL(string: "https://github.com/delannoyk/AudioPlayer")!

        let itemLowOnly = AudioItem(lowQualitySoundURL: URLLow)
        XCTAssertEqual(itemLowOnly?.lowestQualityURL.URL, URLLow)
        XCTAssertEqual(itemLowOnly?.mediumQualityURL.URL, URLLow)
        XCTAssertEqual(itemLowOnly?.highestQualityURL.URL, URLLow)

        let itemMediumOnly = AudioItem(mediumQualitySoundURL: URLMedium)
        XCTAssertEqual(itemMediumOnly?.lowestQualityURL.URL, URLMedium)
        XCTAssertEqual(itemMediumOnly?.mediumQualityURL.URL, URLMedium)
        XCTAssertEqual(itemMediumOnly?.highestQualityURL.URL, URLMedium)

        let itemHighOnly = AudioItem(highQualitySoundURL: URLHigh)
        XCTAssertEqual(itemHighOnly?.lowestQualityURL.URL, URLHigh)
        XCTAssertEqual(itemHighOnly?.mediumQualityURL.URL, URLHigh)
        XCTAssertEqual(itemHighOnly?.highestQualityURL.URL, URLHigh)

        let itemLowMediumOnly = AudioItem(lowQualitySoundURL: URLLow, mediumQualitySoundURL: URLMedium)
        XCTAssertEqual(itemLowMediumOnly?.lowestQualityURL.URL, URLLow)
        XCTAssertEqual(itemLowMediumOnly?.mediumQualityURL.URL, URLMedium)
        XCTAssertEqual(itemLowMediumOnly?.highestQualityURL.URL, URLMedium)

        let itemLowHighOnly = AudioItem(lowQualitySoundURL: URLLow, highQualitySoundURL: URLHigh)
        XCTAssertEqual(itemLowHighOnly?.lowestQualityURL.URL, URLLow)
        XCTAssertEqual(itemLowHighOnly?.mediumQualityURL.URL, URLLow)
        XCTAssertEqual(itemLowHighOnly?.highestQualityURL.URL, URLHigh)

        let itemMediumHighOnly = AudioItem(mediumQualitySoundURL: URLMedium, highQualitySoundURL: URLHigh)
        XCTAssertEqual(itemMediumHighOnly?.lowestQualityURL.URL, URLMedium)
        XCTAssertEqual(itemMediumHighOnly?.mediumQualityURL.URL, URLMedium)
        XCTAssertEqual(itemMediumHighOnly?.highestQualityURL.URL, URLHigh)

        let itemFull = AudioItem(lowQualitySoundURL: URLLow, mediumQualitySoundURL: URLMedium, highQualitySoundURL: URLHigh)
        XCTAssertEqual(itemFull?.lowestQualityURL.URL, URLLow)
        XCTAssertEqual(itemFull?.mediumQualityURL.URL, URLMedium)
        XCTAssertEqual(itemFull?.highestQualityURL.URL, URLHigh)
    }

    func testParseMetadata() {
        let imageURL = NSBundle(forClass: self.dynamicType).URLForResource("image", withExtension: "png")!
        let imageData = NSData(contentsOfURL: imageURL)!

        let metadata = [
            FakeMetadataItem(commonKey: AVMetadataCommonKeyTitle, value: "title"),
            FakeMetadataItem(commonKey: AVMetadataCommonKeyArtist, value: "artist"),
            FakeMetadataItem(commonKey: AVMetadataCommonKeyAlbumName, value: "album"),
            FakeMetadataItem(commonKey: AVMetadataID3MetadataKeyTrackNumber, value: NSNumber(integer: 1)),
            FakeMetadataItem(commonKey: AVMetadataCommonKeyArtwork, value: imageData)
        ]

        let item = AudioItem(soundURLs: [.Low: NSURL(string: "https://github.com")!])
        item?.parseMetadata(metadata)

        XCTAssertEqual(item?.title, "title")
        XCTAssertEqual(item?.artist, "artist")
        XCTAssertEqual(item?.album, "album")
        XCTAssertEqual(item?.trackNumber?.integerValue, 1)
        XCTAssertNotNil(item?.artworkImage)
    }

    func testParseMetadataDoesNotOverrideUserProperties() {
        let item = AudioItem(soundURLs: [.Low: NSURL(string: "https://github.com")!])
        item?.title = "title"
        item?.artist = "artist"
        item?.album = "album"
        item?.trackNumber = NSNumber(integer: 1)

        let metadata = [
            FakeMetadataItem(commonKey: AVMetadataCommonKeyTitle, value: "abc"),
            FakeMetadataItem(commonKey: AVMetadataCommonKeyArtist, value: "def"),
            FakeMetadataItem(commonKey: AVMetadataCommonKeyAlbumName, value: "ghi"),
            FakeMetadataItem(commonKey: AVMetadataID3MetadataKeyTrackNumber, value: NSNumber(integer: 10))
        ]
        item?.parseMetadata(metadata)

        XCTAssertEqual(item?.title, "title")
        XCTAssertEqual(item?.artist, "artist")
        XCTAssertEqual(item?.album, "album")
        XCTAssertEqual(item?.trackNumber?.integerValue, 1)
    }
}
