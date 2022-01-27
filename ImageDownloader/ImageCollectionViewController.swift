//
//  ViewController.swift
//  ImageDownloader
//
//  Created by Kaz Yoshikawa on 11/22/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import UIKit
import CoreData


class ImageCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

	@IBOutlet weak var collectionView: UICollectionView!

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()

		ImageManager.shared.updateImages()

		typealias T = ImageCollectionViewController
		NotificationCenter.default.addObserver(self, selector: #selector(T.imageDidLoad(_:)), name: .imageDidDownload, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(T.imageListDidChange(_:)), name: .imageListDidChange, object: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	var imageObjects = [ImageEntity]()


	@IBAction func reload(_ sender: UIBarButtonItem) {
		ImageManager.shared.reload()
		self.collectionView.reloadData()
		ImageManager.shared.startDownloadingImages()
	}

	@objc func imageDidLoad(_ notification: Notification) {
		if let imageObject = notification.object as? ImageEntity {
			if let item = imageObjects.firstIndex(of: imageObject) {
				let indexPath = IndexPath(item: item, section: 0)
				DispatchQueue.main.async {
					self.collectionView.reloadItems(at: [indexPath])
				}
			}
		}
	}

	@objc func imageListDidChange(_ notification: Notification) {
		DispatchQueue.main.async {
			self.imageObjects = ImageManager.shared.imageObjects
			self.collectionView.reloadData()
		}
	}

	// MARK: -

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.imageObjects.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCollectionViewCell
		cell.imageEntity = self.imageObjects[indexPath.row]
		return cell
	}

}

extension NSManagedObjectContext {

	public func insert<T: NSManagedObject>(entityName: String) -> T? {
		if let entity = NSEntityDescription.entity(forEntityName: entityName, in: self) {
			return NSManagedObject(entity: entity, insertInto: self) as? T
		}
		return nil
	}

	public func managedObject(with uri: URL) -> NSManagedObject? {
		if let objectID = self.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) {
			return self.object(with: objectID)
		}
		return nil
	}

}
