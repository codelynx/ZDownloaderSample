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

		if self.imageItems.count == 0 {
			ImageManager.shared.refresh()
		}

		typealias T = ImageCollectionViewController
		NotificationCenter.default.addObserver(self, selector: #selector(T.imageDidLoad(_:)), name: .imageDidDownload, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(T.imageListDidChange(_:)), name: .imageListDidChange, object: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	var imageItems: [ImageItem] { return ImageManager.shared.imageItems }

	@IBAction func reload(_ sender: UIBarButtonItem) {
		ImageManager.shared.refresh()
		self.collectionView.reloadData()
		ImageManager.shared.startDownloadingImages()
	}

	@objc func imageDidLoad(_ notification: Notification) {
		if let uuid = notification.object as? UUID {
			if let (index, _) = self.imageItems.enumerated().filter({ (_, item) in item.uuid == uuid }).first {
				let indexPath = IndexPath(item: index, section: 0)
				DispatchQueue.main.async {
					self.collectionView.reloadItems(at: [indexPath])
				}
			}
		}
	}

	@objc func imageListDidChange(_ notification: Notification) {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}

	// MARK: -

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.imageItems.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCollectionViewCell
		cell.imageItem = self.imageItems[indexPath.row]
		return cell
	}

}
