//
//  ImageEntity+addition.swift
//  ImageDownloader
//
//  Created by Kaz Yoshikawa on 11/22/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import UIKit
import CoreData



extension ImageEntity: ZDownloadable {

	public var downloadableInfo: NSDictionary {
		return ["type": "image", "oid": self.objectID.uriRepresentation().absoluteString]
	}

	public func downloadDidComplete(info: NSDictionary, response: URLResponse?, location: URL?, error: Error?) {
		print("downloadDidComplete:")
		if let response = response { print("  response: \(response)") }
		if let location = location { print("  location: \(location)") }
		if let error = error { print("  error: \(error)") }

		if let location = location {
			if let imageBin = try? Data(contentsOf: location), let _ = UIImage(data: imageBin) {
				self.imageBin = imageBin
			}
		}
		
		if let response = response as? HTTPURLResponse {
			self.status = response.statusCode as NSNumber
		}
		
		try? self.managedObjectContext?.save()

		NotificationCenter.default.post(name: .imageDidDownload, object: self)
	}

}
