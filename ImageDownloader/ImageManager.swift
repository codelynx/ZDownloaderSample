//
//  ImageManager.swift
//  ImageDownloader
//
//  Created by Kaz Yoshikawa on 11/22/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreData


extension Notification.Name {

	static let imageDidDownload = Notification.Name("ImageDidDownload")
	static let imageListDidChange = Notification.Name("ImageListDidChange")

}


class ImageManager: ZDownloaderDelegate {

	private init() {
	}

	static let shared = ImageManager()

	lazy var storage: ZManagedObjectStorage = {
		let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let fileURL = documentUrl.appendingPathComponent("images.sqlite")
		return ZManagedObjectStorage(fileURL: fileURL, modelName: "ImageModel")!
	}()

	var imageListURL: URL {
		return Bundle.main.url(forResource: "imagelist", withExtension: "txt")!
	}

	lazy var downloader: ZDownloader? = {
		return ZDownloader(identifier: "image.downloader", delegate: self)
	}()

	func downloadable(with dictionary: NSDictionary) -> ZDownloadable? {
		if let _ = dictionary["type"] as? String {
			if let oid = dictionary["oid"] as? String, let uri = URL(string: oid) {
				if let object = self.storage.managedObjectContext?.managedObject(with: uri) as? ImageEntity {
					return object
				}
			}
		}
		return nil
	}

	func updateImages() {

		DispatchQueue.global(qos: .default).async {

			var imageObjects = self.imageObjects

			if imageObjects.count == 0 {

				print("updating the list")
				let context = self.storage.managedObjectContext!
				let imageList = try! String(contentsOf: self.imageListURL)
				var urls = [URL]()
				imageList.enumerateLines { (line, stop) in
					if line.trimmingCharacters(in: CharacterSet.whitespaces).characters.count > 0, let url = URL(string: line) {
						urls.append(url)
					}
				}
				let imageURLs = urls.shuffled()[0 ..< 256]  // pick 256 randomly
				
				for imageURL in imageURLs {
					let request = NSFetchRequest<ImageEntity>(entityName: "ImageEntity")
					request.predicate = NSPredicate(format: "url == %@", imageURL.absoluteString)
					do {
						var imageObject: ImageEntity? = try context.fetch(request).first
						if imageObject == nil {
							imageObject = context.insert(entityName: "ImageEntity")
							imageObject?.url = imageURL.absoluteString
						}
						imageObjects.append(imageObject!)
					}
					catch { print("\(error)") }
				}
				try! self.storage.managedObjectContext?.save()
			}

			// just reload all objects
			print("reloading objects")
			
			NotificationCenter.default.post(name: .imageListDidChange, object: nil, userInfo: nil)

			self.startDownloadingImages()
		}

	}

	func startDownloadingImages() {
		DispatchQueue.global(qos: .default).async {
			// start downloading images
			print("start downloading images....")
			let imageObjects = self.imageObjects
			for imageObject in imageObjects {
				if imageObject.imageBin == nil && imageObject.status == nil, let urlString = imageObject.url, let url = URL(string: urlString) {
					let request = URLRequest(url: url)
					self.downloader?.download(request: request, downloadable: imageObject)
					print("request: \(url.absoluteString)")
				}
			}
		}
	}

	var imageObjects: [ImageEntity] {
		let request = NSFetchRequest<ImageEntity>(entityName: "ImageEntity")
		return try! self.storage.managedObjectContext?.fetch(request) ?? []
	}
	
	func reload() {
		let context = self.storage.managedObjectContext
		for imageObject in self.imageObjects {
			context?.delete(imageObject)
		}
		try? context?.save()
		self.updateImages()
	}

}
