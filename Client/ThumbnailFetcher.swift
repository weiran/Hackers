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
        guard let cache = try? Cache<UIImage>(name: "thumbnailCache") else { return nil }

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
                fetchThumbnail(url: url) { image, error in
                    guard let cache = try? Cache<UIImage>(name: "thumbnailCache") else { return }
                    
                    if let image = image, !cancelMe, error == nil {
                        // image fetched
                        let cacheExpiry = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
                        cache.setObject(image, forKey: url.absoluteString, expires: .date(cacheExpiry))
                        fulfill(image)
                    } else if let error = error {
                        // error fetching image
                        reject(error)
                    } else {
                        // no image to fetch or cancelled
                        fulfill(nil)
                    }
                }
            }
        }
        
        return (promise, cancel)
    }

    fileprivate static func fetchThumbnail(url: URL, completion:@escaping (UIImage?, Error?) -> Void) {
        Readability.parse(url: url) { data in
            if let imageUrlString = data?.topImage, let imageUrl = parseImageUrl(url, imageUrl: URL(string: imageUrlString)) {
                self.shouldFetchImage(url: imageUrl) { shouldFetch in
                    if shouldFetch {
                        let task = URLSession.shared.dataTask(with: imageUrl) { data, response, error -> Void in
                            if let data = data, let image = UIImage(data: data), error == nil {
                                completion(image, nil)
                            } else if let error = error {
                                completion(nil, error)
                            } else {
                                completion(nil, nil)
                            }
                        }
                        task.resume()
                    } else {
                        completion(nil, nil)
                    }
                }
            }
        }
    }
    
    fileprivate static func shouldFetchImage(url: URL, completion:@escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if let expectedContentLength = response?.expectedContentLength {
                completion(expectedContentLength < 1000000 && expectedContentLength > 0)
            } else {
                completion(false)
            }
            if let error = error {
                print(error.localizedDescription)
            }
        })
        
        task.resume()
    }
    
    fileprivate static func parseImageUrl(_ url: URL, imageUrl: URL?) -> URL? {
        guard let imageUrl = imageUrl else { return nil }
        
        guard let urlComponents = NSURLComponents(url: imageUrl, resolvingAgainstBaseURL: true) else {
            return url
        }
        
        if urlComponents.scheme == nil {
            urlComponents.scheme = url.scheme
        }
        
        if urlComponents.host == nil {
            urlComponents.host = url.host
        }
        
        return urlComponents.url!
    }
}
