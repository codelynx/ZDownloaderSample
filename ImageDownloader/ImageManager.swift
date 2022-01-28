//
//  ImageManager.swift
//  ImageDownloader
//
//  Created by Kaz Yoshikawa on 11/22/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreData
import UIKit


extension Notification.Name {

	static let imageDidDownload = Notification.Name("ImageDidDownload")
	static let imageListDidChange = Notification.Name("ImageListDidChange")

}


class ImageManager: ZDownloaderDelegate {

	private init() {
		self.loadImageItems()
	}

	static let shared = ImageManager()

	static var documentDirectoryURL: URL { return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
	static func imageFileURL(uuid: UUID) -> URL {
		return self.documentDirectoryURL.appendingPathComponent((uuid.uuidString as NSString).appendingPathExtension("jpeg")!)
	}
	
	func makeRandomImageURLs(count: Int) -> [URL] {
		return (0..<count).compactMap { URL(string: "https://picsum.photos/320?random=\($0)") }
	}
	
	func makeRandomImageItems(count: Int) -> [ImageItem] {
		return self.makeRandomImageURLs(count: count).map {  ImageItem(uuid: UUID(), url: $0) }
	}
	
	var imageItems = [ImageItem]()
	lazy var downloader: ZDownloader? = {
		return ZDownloader(identifier: "image.downloader", delegate: self)
	}()

	func downloadable(with dictionary: NSDictionary) -> ZDownloadable? {
		if let uuidString = dictionary[Self.uuidKey] as? String, let uuid = UUID(uuidString: uuidString) {
			return self.imageItem(with: uuid)
		}
		return nil
	}

	static let imageItemsKey = "image.items"
	static let typeKey = "type"
	static let uuidKey = "uuid"
	static let urlKey = "url"
	static let imageValue = "image"

	func imageItem(with uuid: UUID) -> ImageItem? {
		return self.imageItems.filter { $0.uuid == uuid }.first
	}

	func loadImageItems() {
		self.imageItems = (UserDefaults.standard.value(forKey: Self.imageItemsKey) as? [NSDictionary]).flatMap { $0.compactMap { ImageItem(dictionary: $0) } } ?? []
	}
	
	func saveImageItems() {
		let dictionaries = self.imageItems.map { $0.dictionary }
		UserDefaults.standard.setValue(dictionaries, forKey: Self.imageItemsKey)
	}

	private var isSaving = false
	func setNeedsSave() {
		if !self.isSaving {
			self.isSaving = true
			Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
				self.saveImageItems()
				self.isSaving = false
			}
		}
	}

	func startDownloadingImages() {
		DispatchQueue.global(qos: .default).async {
			print("start downloading images....")
			for imageItem in self.imageItems {
				if !imageItem.hasImage {
					let request = URLRequest(url: imageItem.url)
					self.downloader?.download(request: request, downloadable: imageItem)
					print("request: \(imageItem.url.absoluteString)")
				}
			}
		}
	}

	private func cleanup() {
		do {
			let documentDirectoryURL = Self.documentDirectoryURL
			for item in try FileManager.default.contentsOfDirectory(atPath: documentDirectoryURL.path) {
				let fileURL = documentDirectoryURL.appendingPathComponent(item)
				try FileManager.default.removeItem(at: fileURL)
			}
		}
		catch {
			fatalError("\(error)")
		}
	}
	
	func refresh() {
		self.cleanup()
		self.imageItems = self.makeRandomImageItems(count: 256)
		self.saveImageItems()
		self.startDownloadingImages()
	}

}
