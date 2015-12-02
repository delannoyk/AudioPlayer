//
//  AudioResourceLoader.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 10/11/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

internal protocol AudioResourceLoaderDelegate: class {
    func audioResourceLoader(resourceLoader: AudioResourceLoader, didReceiveResponse response: NSURLResponse)
    func audioResourceLoader(resourceLoader: AudioResourceLoader, didReceiveData data: NSData)
    func audioResourceLoader(resourceLoader: AudioResourceLoader, didFinishLoadingItem temporaryFileURL: NSURL)
    func audioResourceLoader(resourceLoader: AudioResourceLoader, didFailWithError error: NSError?)
}

internal class AudioResourceLoader: NSObject, AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate {
    private var currentTask: AVAssetResourceLoadingRequest?
    private var currentDownloadTask: NSURLSessionDataTask?
    private var totalBytesReceived = 0

    private var URL: NSURL
    private weak var delegate: AudioResourceLoaderDelegate?

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    init(URL: NSURL, delegate: AudioResourceLoaderDelegate) {
        self.URL = URL
        self.delegate = delegate
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: AVAssetResourceLoaderDelegate
    ////////////////////////////////////////////////////////////////////////////

    func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil

        print("test 1")

        let request = NSURLRequest(URL: URL)
        let session = NSURLSession(configuration: .defaultSessionConfiguration(),
            delegate: self,
            delegateQueue: NSOperationQueue.mainQueue())

        currentTask = loadingRequest

        let task = session.dataTaskWithRequest(request)
        task.resume()

        currentDownloadTask = task
        return true
    }

    func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: NSURLSessionDataDelegate
    ////////////////////////////////////////////////////////////////////////////

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        guard let MIMEType = response.MIMEType else {
            completionHandler(.Cancel)
            return
        }

        let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil)
        currentTask?.contentInformationRequest?.byteRangeAccessSupported = true
        currentTask?.contentInformationRequest?.contentLength = response.expectedContentLength
        currentTask?.contentInformationRequest?.contentType = "public.mp3"//contentType?.takeUnretainedValue() as? String
        completionHandler(.Allow)
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        totalBytesReceived += data.length

        currentTask?.dataRequest?.respondWithData(data)
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {
            currentTask?.finishLoadingWithError(error)
        }
        else {
            currentTask?.finishLoading()
        }
        currentTask = nil
        currentDownloadTask = nil
    }

    ////////////////////////////////////////////////////////////////////////////
}
