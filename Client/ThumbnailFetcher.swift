//
//  ThumbnailFetcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/05/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import ReadabilityKit

class ThumbnailFetcher {

    static func fetchThumbnail(url: URL, completion:@escaping (UIImage?) -> Void) {
        Readability.parse(url: url) { data in
            if let imageUrlString = data?.topImage, let imageUrl = URL(string: imageUrlString) {
                self.shouldFetchImage(url: imageUrl) { shouldFetch in
                    if shouldFetch {
                        let task = URLSession.shared.dataTask(with: imageUrl) { data, response, error -> Void in
                            if let data = data, let image = UIImage(data: data) {
                                completion(image)
                            } else {
                                completion(nil)
                            }
                        }
                        task.resume()
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    private static func shouldFetchImage(url: URL, completion:@escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, _ -> Void in
            if let expectedContentLength = response?.expectedContentLength {
                completion(expectedContentLength < 1000000)
            } else {
                completion(false)
            }
        })
        
        task.resume()
    }
}
