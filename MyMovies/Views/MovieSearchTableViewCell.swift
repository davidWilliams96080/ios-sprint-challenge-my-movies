//
//  MovieSearchTableViewCell.swift
//  MyMovies
//
//  Created by David Williams on 5/4/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class MovieSearchTableViewCell: UITableViewCell {

    var movieController: MovieController?
    
    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var addMovieLabel: UIButton!
    
    var movierepresentation: MovieRepresentation? {
        didSet {
            updateViews()
        }
    }
    
    var added: Bool = false
    
    func updateViews() {
           guard let movie = movierepresentation else { return }
           
           movieTitleLabel.text = movie.title
       }
    
    @IBAction func addMovie(_ sender: Any) {
        if !added {
            added.toggle()
            addMovieLabel.setTitle("Added", for: .normal)
            guard let movieTitle = movieTitleLabel.text else { return }
            let movie = Movie(
                title: movieTitle,
                hasWatched: false,
                context: CoreDataStack.shared.mainContext)
            movieController?.sendMovieToServer(movie: movie) { _ in }
            do {
                try CoreDataStack.shared.mainContext.save()
            } catch {
                NSLog("Error saving managed object context: \(error)")
            }
        } else {
            addMovieLabel.isSelected = false
            return
        }
    }
}
