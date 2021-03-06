//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

enum NetworkError: Error {
    case noIdentifier
    case otherError
    case noData
    case noDecode
    case noEncode
    case noRep
}

class MovieController {
    
    init(){
        fetchMoviesFromServer()
    }
    
    
     typealias CompletionHandler = (Result<Bool, NetworkError>) -> Void


    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    private let baseURL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm,
                               "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error searching for movie with search term \(searchTerm): \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    // MARK: - Properties
    
    var searchedMovies: [MovieRepresentation] = []
    
    var movieList: [Movie] = []
    
    let baseMoviesURL = URL(string: "https://mymovies-c37fb.firebaseio.com/")!
    
    func sendMovieToServer(movie: Movie, completion: @escaping CompletionHandler) {
        guard let identifier =  movie.identifier else {
            completion(.failure(.noIdentifier))
            print("Caught")
            return
        }

        let requestURL =  baseMoviesURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
       
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        do {
            guard let movieRepresentation = movie.movieRepresentation else {
                completion(.failure(.noRep))
                return
            }
            request.httpBody = try JSONEncoder().encode(movieRepresentation)
        } catch {
            NSLog("Error encoding entry: \(error)")
            completion(.failure(.noEncode))
            return
        }
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error putting task to server: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(true))
            }
            
        }.resume()
    }
    
    func deleteMovieFromServer(movie: Movie, completion: @escaping CompletionHandler = { _ in }) {
        guard let identifier = movie.identifier else {
            completion(.failure(.noIdentifier))
            return
        }
        
        let requestURL = baseMoviesURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("Error deleting entry from server: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
       
    func updateMovies(with representations: [MovieRepresentation]) throws {
    /// identifier shouldn't be force upwrapped
        let identifiersToFetch = representations.compactMap({ UUID(uuidString: $0.identifier!.uuidString) })
            
            let representationsByID = Dictionary(uniqueKeysWithValues:
                zip(identifiersToFetch, representations)
            )
            
            // Make a copy of representationsByID for later use
            var moviesToCreate = representationsByID
            
            // Ask Core Data to find any tasks with these identifiers
            
            let predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
           
            let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
            fetchRequest.predicate = predicate
            
            let context = CoreDataStack.shared.container.newBackgroundContext()
           
            context.performAndWait {
                
                do {
                    // This will only fetch the entries that match the criteria in our predicate
                    let existingEntries = try context.fetch(fetchRequest)
                    
                    // Let's update the entries that already exist in Core Data
                    
                    for movie in existingEntries {
                        guard let id = movie.identifier else { continue }
                        moviesToCreate.removeValue(forKey: id)
                    }
 
                    for representation in moviesToCreate.values {
                        Movie(movieRepresentation: representation, context: context)
                    }
                } catch {
                    NSLog("Error fetching tasks for UUIDs: \(error)")
                }
            }
            try CoreDataStack.shared.save(context: context)
        }
        
    
    func fetchMoviesFromServer(completion: @escaping CompletionHandler = { _ in }) {
        let requestURL = baseMoviesURL.appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching tasks: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            guard let data = data else {
                NSLog("Error: No data returned from fetch")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            do {
                let movieRepresentations = try JSONDecoder().decode([String: MovieRepresentation].self, from: data).map({ $0.value })
              
                try self.updateMovies(with: movieRepresentations)
                
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                NSLog("Error decoding entry representation: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.noDecode))
                }
            }
        }.resume()
    }
}
