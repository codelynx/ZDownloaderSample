//
//  ImageCollectionViewCell.swift
//  ImageDownloader
//
//  Created by Kaz Yoshikawa on 11/22/16.
//  Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import UIKit


class ImageCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var iconView: UILabel!
	var observing: Bool = false

    var imageEntity: ImageEntity! {
		didSet { self.setNeedsLayout() }
	}

	deinit {
	}

	override func layoutSubviews() {
		assert(imageEntity != nil)
		if let imageEntity = self.imageEntity, let bin = imageEntity.imageBin, let image = UIImage(data: bin as Data) {
			self.imageView.image = image
		}
		else {
			self.imageView.image = nil
		}
		
		if let status = imageEntity.status?.int16Value, status >= 300 {
			self.iconView.isHidden = false
		}
		else {
			self.iconView.isHidden = true
		}
	}
	
}
