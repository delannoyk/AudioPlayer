// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "KDEAudioPlayer",
    platforms: [
        .iOS(.v8),
        .tvOS(.v9),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "KDEAudioPlayer",
            targets: ["KDEAudioPlayer"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KDEAudioPlayer",
            dependencies: [],
            path: "AudioPlayer/AudioPlayer",
            // exclude: [
            //     "utils/MPNowPlayingInfoCenter+AudioItem.swift"
            // ],
            sources: ["."],
            publicHeadersPath: "",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("MediaPlayer"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("Foundation", .when(platforms: [.macOS]))
            ]
        )
    ]
)
