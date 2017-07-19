//
//  MovieCell.swift
//  MovieFinder
//
//  Created by Jesse Tello on 7/17/17.
//  Copyright © 2017 jt. All rights reserved.
//

import UIKit

class MovieCell: UITableViewCell {

    @IBOutlet weak var movieImage: UIImageView!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var movieGenres: UILabel!
    @IBOutlet weak var movieImageIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.movieGenres.text = ""
        self.movieImage.image = UIImage(named: "PlaceHolder")
    }

}
