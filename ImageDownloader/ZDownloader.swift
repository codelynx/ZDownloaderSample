//
//	ZDownloader.swift
//	ZKit
//
//	The MIT License (MIT)
//
//	Copyright (c) 2016 Electricwoods LLC, Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy 
//	of this software and associated documentation files (the "Software"), to deal 
//	in the Software without restriction, including without limitation the rights 
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//	copies of the Software, and to permit persons to whom the Software is 
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in 
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//

import Foundation


public protocol ZDownloadable: class {

	var downloadableInfo: NSDictionary { get } // should be JSON serializable
	func downloadDidComplete(info: NSDictionary, response: URLResponse?, location: URL?, error: Error?)

}


public protocol ZDownloaderDelegate: class {

	func downloadable(with dictionary: NSDictionary) -> ZDownloadable?

}


public class ZDownloader: NSObject {

	let identifier: String
	weak var delegate: ZDownloaderDelegate?

	private static var downloaders = NSMapTable<NSString, ZDownloader>.strongToWeakObjects()
	
	init(identifier: String, delegate: ZDownloaderDelegate) {
		
		self.delegate = delegate
		self.identifier = identifier
		super.init()
		if let _ = ZDownloader.downloaders.object(forKey: identifier as NSString) {
			fatalError("session identifier `\(identifier)` has been used.")
		}
		ZDownloader.downloaders.setObject(self, forKey: identifier as NSString)
		
		typealias T = ZDownloader
		NotificationCenter.default.addObserver(self, selector: #selector(T.applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(T.applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
	}

	deinit {
		ZDownloader.downloaders.removeObject(forKey: self.identifier as NSString)
		NotificationCenter.default.removeObserver(self)
	}

	func applicationWillEnterForeground(_ notification: Notification) {
		print("applicationWillEnterForeground")
	}

	func applicationDidEnterBackground(_ notification: Notification) {
		print("applicationDidEnterBackground")
	}


	class func downloader(identifier: String) -> ZDownloader? {
		return ZDownloader.downloaders.object(forKey: identifier as NSString)
	}

	public lazy var configuration: URLSessionConfiguration = {
		return URLSessionConfiguration.background(withIdentifier: self.identifier)
	}()
	
	public lazy var session: URLSession = {
		return URLSession(configuration: self.configuration, delegate: self, delegateQueue: nil)
	}()

	public func download(request: URLRequest, downloadable: ZDownloadable) {
		do {
			let task = self.session.downloadTask(with: request)
			let dictionary = downloadable.downloadableInfo
			let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
			let string = String(bytes: data, encoding: .utf8)
			task.taskDescription = string
			task.resume()
		}
		catch { print("failed serializing json. \(error)") }
	}

	public func download(url: URL, downloadable: ZDownloadable) {
		let request = URLRequest(url: url)
		self.download(request: request, downloadable: downloadable)
	}
}


extension ZDownloader: URLSessionTaskDelegate {

	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
	}

	@available(iOS 10.0, *)
	public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let description = task.taskDescription, let data = description.data(using: .utf8) {
			do {
				if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary, let delegate = self.delegate {
					if let downloadable = delegate.downloadable(with: dictionary) {
						downloadable.downloadDidComplete(info: dictionary, response: task.response, location: nil, error: error)
					}
					else { print("unknown type: \(dictionary)") }
				}
				else { print("unexpected taskDescription: \(description)") }
			}
			catch { print("failed unserializing json: \(error)") }
		}
	}
	
}

extension ZDownloader: URLSessionDownloadDelegate {

	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		if let description = downloadTask.taskDescription, let data = description.data(using: .utf8) {
			do {
				if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary, let delegate = self.delegate {
					if let downloadable = delegate.downloadable(with: dictionary) {
						downloadable.downloadDidComplete(info: dictionary, response: downloadTask.response, location: location, error: nil)
					}
					else { print("unknown type: \(dictionary)") }
				}
				else { print("unexpected taskDescription: \(description)") }
			}
			catch { print("failed unserializing json: \(error)") }
		}
	}
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
	}
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
	}
}


