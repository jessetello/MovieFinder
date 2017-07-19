//
//  MovieViewModel.swift
//  MovieFinder
//
//  Created by Jesse Tello on 7/17/17.
//  Copyright © 2017 jt. All rights reserved.
//

import Foundation
import UIKit
import Speech

protocol MovieViewModelUpdatable: class {
    func movieViewModelDidUpdate(error:Error?)
    func speechUpdate(error:Error?)
}

enum RequestType {
    case MovieList
    case Genres
    case Cast
}

class MovieViewModel: NSObject {
    weak var delegate: MovieViewModelUpdatable?
    var movieList = [Movie]()
    var pageMax = 0
    var currentPage = 1
    var selectedMovie: Movie?
    var genresList = [Int:String]()
    var castList = [String]()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    func getMovies(page:Int) {
        print(page)
        let path = Constants.RequestsValues.DiscoverUrl + Constants.RequestsValues.ApiKey + "&page=\(page)"
        requestWithPath(path: path, requestType: .MovieList)
    }
    
    func retrieveGenres() {
        let path = Constants.RequestsValues.BaseURL + Constants.RequestsValues.GenreList + Constants.RequestsValues.ApiKey
        requestWithPath(path: path, requestType: .Genres)
    }
    
    func retrieveCast() {
        let path = Constants.RequestsValues.BaseURL + "/movie/\(selectedMovie?.id ?? 0)/credits?" + Constants.RequestsValues.ApiKey
        requestWithPath(path: path, requestType: .Cast)
    }
    
    func selectedMovie(index:Int) {
        selectedMovie = movieList[index]
    }
    
    func configureMovieCell(mCell:MovieCell, movieIndex:IndexPath) {
        let movie = self.movieList[movieIndex.row]
        mCell.movieTitle.text = movie.title
        for g in movie.genreIDs! {
            if let genre = genresList[g] {
                mCell.movieGenres.text = mCell.movieGenres.text! + " " + genre
            }
        }
        
        if let imagePath = movie.postImage! as String? {
            mCell.movieImageIndicator.startAnimating()
            mCell.movieImageIndicator.hidesWhenStopped = true
            if let imageString = Constants.RequestsValues.BaseImageListURL + "\(imagePath)"as String? {
                if let url = URL(string: imageString) {
                    DispatchQueue.main.async {
                        mCell.movieImage.downloadedFrom(url: url)
                        mCell.movieImageIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    private func requestWithPath(path:String, requestType:RequestType) {
        if let url = URL(string: path) {
            let request = URLRequest(url:url)
            URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                if error == nil {
                    do {
                        if let jsonData = data {
                            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                                DispatchQueue.main.async {
                                    self?.parseResults(json: json)
                                }
                            }
                            else {
                                let mError: Error = MovieError.customError
                                self?.delegate?.movieViewModelDidUpdate(error: mError)
                            }
                        }
                    } catch {
                        let mError: Error = MovieError.customError
                        self?.delegate?.movieViewModelDidUpdate(error: mError)
                    }
                }
                else {
                    self?.delegate?.movieViewModelDidUpdate(error: error)
                }
            }.resume()
        }
    }
    
    private func parseResults(json:[String:Any]) {
        if let results = json["results"] as? [[String:Any]] {
            self.pageMax = json["total_pages"] as! Int
            self.currentPage = json["page"] as! Int
            for m in results {
                let movie = Movie()
                movie.title = m["original_title"] as? String
                movie.overview = m["overview"] as? String
                movie.postImage = m["poster_path"] as? String
                movie.backImage = m["backdrop_path"] as? String
                movie.id = m["id"] as? Int
                movie.genreIDs = m["genre_ids"] as? [Int]
                movieList.append(movie)
            }
        }
        else if let genres = json["genres"] as? [[String:Any]] {
            for (_, element) in genres.enumerated() {
                genresList[element["id"] as! Int] = element["name"] as? String
            }
            self.getMovies(page: self.currentPage)
        }
        else if let cast = json["cast"] as? [[String:Any]] {
            for info in cast {
                castList.append(info["name"] as! String)
            }
        }
        self.delegate?.movieViewModelDidUpdate(error: nil)
    }
    
    func record() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            if result != nil {
                let movieTitle = result?.bestTranscription.formattedString
                self.selectedMovie = self.movieList.filter { ($0.title?.contains(movieTitle!))! }.first
                self.delegate?.speechUpdate(error:nil)
                self.audioEngine.stop()
            }
            if error != nil {
                self.delegate?.speechUpdate(error: error)
            }
        })
        
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
}

extension MovieViewModel: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
       
    }
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200, let mimeType = response?.mimeType, mimeType.hasPrefix("image"), let data = data, error == nil, let image = UIImage(data: data) else {
                    return
                }
                DispatchQueue.main.async() {
                    self.image = image
                }
        }.resume()
    }
}

//Custom Error
public enum MovieError: Error {
    case customError
}

extension MovieError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .customError:
            return NSLocalizedString("Error loading movies", comment: "error")
        }
    }
}

