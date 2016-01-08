//
//  AudioResourceLoader.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 10/11/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import AVFoundation
#if os(iOS) || os(tvOS)
    import MobileCoreServices
#endif

internal protocol AudioResourceLoaderDelegate: NSObjectProtocol {
    func resourceLoader(resourceLoader: AudioResourceLoader, didReceiveData data: NSData)
    func resourceLoader(resourceLoader: AudioResourceLoader, didFinishLoadingWithError error: ErrorType?)
}

internal class AudioResourceLoader: NSObject, AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate {
    private let URL: NSURL
    private weak var delegate: AudioResourceLoaderDelegate?

    private lazy var session: NSURLSession = {
        return NSURLSession(configuration: .defaultSessionConfiguration(),
            delegate: self,
            delegateQueue: NSOperationQueue.mainQueue())
    }()

    private var data: NSMutableData?
    private var response: NSHTTPURLResponse?
    private var dataTask: NSURLSessionDataTask?
    private var pendingRequests = [AVAssetResourceLoadingRequest]()
    private var totalDataLengthReceived = Int64(0)

    // MARK: Initialization
    ////////////////////////////////////////////////////////////////////////////

    init(URL: NSURL, delegate: AudioResourceLoaderDelegate?) {
        self.URL = URL
        self.delegate = delegate
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: AVAssetResourceLoaderDelegate
    ////////////////////////////////////////////////////////////////////////////

    func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if dataTask == nil {
            let request = NSURLRequest(URL: URL)
            let task = session.dataTaskWithRequest(request)

            dataTask = task
            task.resume()
        }
        pendingRequests.append(loadingRequest)
        return true
    }

    func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
        if let index = pendingRequests.indexOf(loadingRequest) {
            pendingRequests.removeAtIndex(index)
        }
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: NSURLSessionDataDelegate
    ////////////////////////////////////////////////////////////////////////////

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        data = NSMutableData()
        totalDataLengthReceived = 0
        self.response = response as? NSHTTPURLResponse

        processPendingRequests()

        completionHandler(.Allow)
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data?.appendData(data)
        totalDataLengthReceived += data.length

        processPendingRequests()

        delegate?.resourceLoader(self, didReceiveData: data)
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        processPendingRequests()

        delegate?.resourceLoader(self, didFinishLoadingWithError: error)
    }

    ////////////////////////////////////////////////////////////////////////////


    // MARK: Requests handling
    ////////////////////////////////////////////////////////////////////////////

    private func processPendingRequests() {
        pendingRequests = pendingRequests.filter { request in
            if let contentInformationRequest = request.contentInformationRequest {
                fillInContentInformation(contentInformationRequest)
            }

            if let dataRequest = request.dataRequest {
                if isRequestCompleteAfterRespondingToRequestedData(dataRequest) {
                    request.finishLoading()
                    return false
                }
            }
            return true
        }
    }

    private func fillInContentInformation(request: AVAssetResourceLoadingContentInformationRequest) {
        guard let MIMEType = response?.MIMEType, contentLength = response?.expectedContentLength else {
            return
        }

        request.byteRangeAccessSupported = true
        request.contentLength = contentLength
        if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, nil) {
            request.contentType = contentType.takeUnretainedValue() as String
        }
    }

    private func isRequestCompleteAfterRespondingToRequestedData(request: AVAssetResourceLoadingDataRequest) -> Bool {
        guard let data = data else {
            return false
        }

        let startOffset = request.currentOffset != 0 ? request.currentOffset : request.requestedOffset
        let unreadBytesLength = totalDataLengthReceived - startOffset
        let responseLength = min(Int64(request.requestedLength), unreadBytesLength)

        if Int64(data.length) < responseLength {
            return false
        }

        let range = NSMakeRange(0, Int(responseLength))
        request.respondWithData(data.subdataWithRange(range))

        if startOffset > 0 {
            data.replaceBytesInRange(range, withBytes: nil, length: 0)
        }

        let endOffset = startOffset + request.requestedLength
        let didRespondFully = (Int64(data.length) >= endOffset)
        return didRespondFully
    }

    ////////////////////////////////////////////////////////////////////////////
}
