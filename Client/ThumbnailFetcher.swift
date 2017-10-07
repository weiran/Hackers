//
//  ThumbnailFetcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/05/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import ReadabilityKit
import AwesomeCache
import PromiseKit

class ThumbnailFetcher {
    
    static func getThumbnailFromCache(url: URL) -> UIImage? {
        guard let cache = try? Cache<UIImage>(name: "thumbnailCache") else {
            return nil
        }

        return cache[url.absoluteString]
    }
    
    static func getThumbnail(url: URL) -> (Promise<UIImage?>, () -> Void) {
        var cancelMe = false
        var cancel: () -> Void = { }
        
        let promise = Promise<UIImage?> { fulfill, reject in
            cancel = {
                cancelMe = true
            }
            
            if let cachedImage = getThumbnailFromCache(url: url) {
                fulfill(cachedImage)
            } else {
                fetchThumbnail(url: url) { image in
                    if let image = image, !cancelMe {
                        if let cache = try? Cache<UIImage>(name: "thumbnailCache") {
                            cache[url.absoluteString] = image
                        }
                        fulfill(image)
                    } else {
                        fulfill(nil)
                    }
                }
            }
        }
        
        return (promise, cancel)
    }

    private static func fetchThumbnail(url: URL, completion:@escaping (UIImage?) -> Void) {
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
                completion(expectedContentLength < 1000000 && expectedContentLength > 0)
            } else {
                completion(false)
            }
        })
        
        task.resume()
    }
}
