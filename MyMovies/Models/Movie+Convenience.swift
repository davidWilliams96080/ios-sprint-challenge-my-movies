//
//  Movie+Convenience.swift
//  MyMovies
//
//  Created by David Williams on 5/3/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation
import CoreData

extension Movie {
    
    var movieRepresentation: MovieRepresentation? {
        guard let title = title else { return nil }
        let id = identifier ?? UUID()
        
        return MovieRepresentation(title: title, identifier: id, hasWatched: hasWatched)
    }
    
    @discardableResult convenience init(identifier: UUID = UUID(),
                                        title: String,
                                        hasWatched: Bool = false,
                                        context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.title = title
        self.hasWatched = hasWatched
        self.identifier = identifier
    }
    
    @discardableResult convenience init?(movieRepresentation: MovieRepresentation,
                                         context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        
        // I cannot get away from force unwrapping movieRepresentation.identifier!.uuidString without disrupting
        // the keyValue dictionary match - it errors when attempting to eliminate the bang
        guard let identifier = UUID(uuidString: movieRepresentation.identifier!.uuidString),
            let hasWatched = movieRepresentation.hasWatched else {
        return nil
        }
        
        self.init(identifier: identifier,
                  title: movieRepresentation.title,
                  hasWatched: hasWatched,
                  context: context)
    }
}
