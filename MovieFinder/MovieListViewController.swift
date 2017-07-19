//
//  MovieListViewController.swift
//  MovieFinder
//
//  Created by Jesse Tello on 7/17/17.
//  Copyright © 2017 jt. All rights reserved.
//

import UIKit
import SVProgressHUD
import Speech

class MovieListViewController: UIViewController {
    
    @IBOutlet weak var movieListView: UITableView!
    let movieViewModel = MovieViewModel()
    var isBottom = false
    var page = 1
    @IBOutlet weak var speechButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.movieListView.delegate = self
        self.movieListView.dataSource = self
        self.movieViewModel.delegate = self

        SVProgressHUD.show(withStatus: "Loading Movies...")
        movieViewModel.retrieveGenres()
        speechButton.isEnabled = false
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
            case .restricted:
                isButtonEnabled = false
            case .notDetermined:
                isButtonEnabled = false
            }
            OperationQueue.main.addOperation() {
                self.speechButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.movieViewModel.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MovieDetails" {
            if let md = segue.destination as? MovieViewController {
                md.movieViewModel = self.movieViewModel
            }
        }
    }
    
    @IBAction func speechAction(_ sender: UIBarButtonItem) {
        if self.movieViewModel.audioEngine.isRunning {
            self.movieViewModel.audioEngine.stop()
            self.speechButton.title = "Speech"
            SVProgressHUD.dismiss()
        }
        else {
            self.speechButton.title = "Stop"
            self.movieViewModel.record()
            SVProgressHUD.show(withStatus: "Speak a title...")
        }
    }
}

extension MovieListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieViewModel.movieList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mCell = movieListView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath as IndexPath) as! MovieCell
        self.movieViewModel.configureMovieCell(mCell: mCell, movieIndex: indexPath)
        return mCell
    }
}

extension MovieListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         self.movieViewModel.selectedMovie(index:indexPath.row)
         self.performSegue(withIdentifier: "MovieDetails", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRowIndex = movieListView.numberOfRows(inSection: 0) - 1
        if indexPath.row == lastRowIndex && !isBottom {
            if self.movieViewModel.pageMax != page {
                self.page += 1
                self.movieViewModel.getMovies(page: self.page)
            }
        }
    }
}

extension MovieListViewController: MovieViewModelUpdatable {
    func movieViewModelDidUpdate(error: Error?) {
        if error == nil {
            self.movieListView.reloadData()
        }
        else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Movie Load Error", message:error?.localizedDescription , preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            actionSheetController.addAction(cancelAction)
            self.present(actionSheetController, animated: true, completion: nil)
        }
        SVProgressHUD.dismiss()
    }
    
    func speechUpdate(error: Error?) {
        if error == nil {
            self.speechButton.title = "Speech"
            self.performSegue(withIdentifier: "MovieDetails", sender: nil)
        }
        else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Voice Search Error", message:error?.localizedDescription , preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            actionSheetController.addAction(cancelAction)
            self.present(actionSheetController, animated: true, completion: nil)
        }
        SVProgressHUD.dismiss()
    }
}
