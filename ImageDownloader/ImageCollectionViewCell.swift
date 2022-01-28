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
	
	var imageItem: ImageItem! {
		didSet { self.setNeedsLayout() }
	}
	
	deinit {
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		guard let imageItem = self.imageItem else { return }
		self.imageView.image = imageItem.image
		self.iconView.isHidden = (imageItem.status ?? 0) < 300
		self.setNeedsDisplay()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		self.imageView.image = nil
		self.iconView.isHidden = true
	}
}
