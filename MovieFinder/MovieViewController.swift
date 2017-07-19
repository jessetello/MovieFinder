//
//  MovieViewController.swift
//  MovieFinder
//
//  Created by Jesse Tello on 7/17/17.
//  Copyright © 2017 jt. All rights reserved.
//

import UIKit
import SVProgressHUD
class MovieViewController: UIViewController {

    var movieViewModel: MovieViewModel?
    
    @IBOutlet weak var moviePoster: UIImageView!
    @IBOutlet weak var movieOverview: UILabel!
    @IBOutlet weak var movieCast: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show(withStatus: "Loading Movie Details...")
        self.movieViewModel?.delegate = self
        self.movieViewModel?.retrieveCast()
        setupMovieDetails()
    }
    
    func setupMovieDetails() {
        self.movieOverview.text = self.movieViewModel?.selectedMovie?.overview
        if let backImageString = self.movieViewModel?.selectedMovie?.backImage  {
            let path = Constants.RequestsValues.BaseImageDetailURL + backImageString
            guard let bURL = URL(string: path) else {
                return
            }
            DispatchQueue.main.async {
                self.moviePoster.downloadedFrom(url: bURL)
            }
        }
    }
}

extension MovieViewController: MovieViewModelUpdatable {
    func movieViewModelDidUpdate(error: Error?) {
        if error == nil {
            DispatchQueue.main.async {
                self.movieCast.text = self.movieViewModel?.castList.joined(separator: ",")
            }
        }
        else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Error", message:error?.localizedDescription , preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            actionSheetController.addAction(cancelAction)
            self.present(actionSheetController, animated: true, completion: nil)
        }
        SVProgressHUD.dismiss()
    }
    
    func speechUpdate(error: Error?) {
        
    }
}
