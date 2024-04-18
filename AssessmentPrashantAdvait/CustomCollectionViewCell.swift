//
//  CustomCollectionViewCell.swift
//  AssessmentPrashantAdvait
//
//  Created by RLogixxTraining on 14/04/24.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.contentMode = .scaleToFill
        imgView.clipsToBounds = true
        // Initialization code
    }

}
