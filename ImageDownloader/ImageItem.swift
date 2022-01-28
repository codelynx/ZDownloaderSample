//
//  ImageItem.swift
//  ImageDownloader
//
//  Created by Kaz Yoshikawa on 1/28/22.
//  Copyright © 2022 Electricwoods LLC. All rights reserved.
//


import UIKit


class ImageItem {
	static let uuidKey = "uuid"
	static let urlKey = "url"
	static let statusKey = "status"
	let uuid: UUID
	let url: URL
	var status: Int?
	init(uuid: UUID, url: URL) {
		self.uuid = uuid
		self.url = url
		self.status = nil
	}
	init?(dictionary: NSDictionary) {
		guard let uuidString = dictionary[Self.uuidKey] as? String,
			  let uuid = UUID(uuidString: uuidString),
			  let urlString = dictionary[Self.uuidKey] as? String,
			  let url = URL(string: urlString)
		else { return nil }
		self.uuid = uuid
		self.url = url
		self.status = dictionary[Self.statusKey] as? Int
	}
	var dictionary: NSDictionary {
		let dictionary = NSMutableDictionary()
		dictionary[Self.uuidKey] = self.uuid.uuidString
		dictionary[Self.urlKey] = self.url.absoluteString
		dictionary[Self.statusKey] = self.status
		return NSDictionary(dictionary: dictionary)
	}
	var imageFileURL: URL {
		return ImageManager.imageFileURL(uuid: self.uuid)
	}
	var hasImage: Bool {
		return FileManager.default.fileExists(atPath: self.imageFileURL.path)
	}
	var image: UIImage? {
		get {
			do { return self.hasImage ? UIImage(data: try Data(contentsOf: self.imageFileURL)) : nil }
			catch { print("\(Self.self).\(#function): \(error)"); return nil }
		}
		set {
			do { try newValue?.jpegData(compressionQuality: 0.75)?.write(to: self.imageFileURL) }
			catch { print("\(Self.self).\(#function): \(error)") }
		}
	}
}

extension ImageItem: ZDownloadable {

	var downloadableInfo: NSDictionary {
		typealias T = ImageManager
		let dictionary = NSMutableDictionary()
		dictionary[T.typeKey] = T.imageValue
		dictionary[T.uuidKey] = self.uuid.uuidString
		return NSDictionary(dictionary: dictionary)
	}
	func downloadDidComplete(info: NSDictionary, response: URLResponse?, location: URL?, error: Error?) {
		print("downloadDidComplete:")
		if let response = response as? HTTPURLResponse { print("  status: \(response.statusCode)") }
		if let location = location { print("  location: \(location)") }
		if let error = error { print("  error: \(error)") }
		if let location = location, let imageBin = try? Data(contentsOf: location), let image = UIImage(data: imageBin) {
			self.image = image // imply to save
		}
		if let response = response as? HTTPURLResponse {
			self.status = response.statusCode
		}
		NotificationCenter.default.post(name: .imageDidDownload, object: self.uuid)
		ImageManager.shared.setNeedsSave()
	}

}
