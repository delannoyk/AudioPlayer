//
//  ViewController.swift
//  AudioPlayerExample
//
//  Created by Kevin DELANNOY on 10/11/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import UIKit
import AudioPlayer

class ViewController: UIViewController {
    @IBOutlet private weak var textFieldURL: UITextField?
    @IBOutlet private weak var textViewLogs: UITextView?

    private let audioPlayer = AudioPlayer()

    // MARK: Actions
    ////////////////////////////////////////////////////////////////////////////

    @IBAction private func buttonPlayPressed(_: AnyObject) {
        if let text = textFieldURL?.text, item = AudioItem(highQualitySoundURL: NSURL(string: text)) {
            audioPlayer.delegate = self
            audioPlayer.playItem(item)
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Log
    ////////////////////////////////////////////////////////////////////////////

    private func log(text: String) {
        textViewLogs?.text = text + "\n" + (textViewLogs.map { $0.text } ?? "")
        textViewLogs?.contentOffset = .zero

        print(text)
    }

    ////////////////////////////////////////////////////////////////////////////
}

extension ViewController: AudioPlayerDelegate {
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
        log("AudioPlayer DidChangeState from: .\(from) to: .\(to)")
    }

    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem) {
        log("AudioPlayer DidFindDuration duration: \(duration)")
    }

    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float) {
    }

    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {
    }

    func audioPlayer(audioPlayer: AudioPlayer, didLoadRange range: AudioPlayer.TimeRange, forItem item: AudioItem) {
        print(range)
    }

    func audioPlayer(audioPlayer: AudioPlayer, didLoadData data: NSData, forItem item: AudioItem) {
        print("Received Data")
    }

    func audioPlayer(audioPlayer: AudioPlayer, didFinishLoadingDataForItem item: AudioItem, withError error: ErrorType?) {
        print("Finished Loading (Error: \(error))")
    }
}
