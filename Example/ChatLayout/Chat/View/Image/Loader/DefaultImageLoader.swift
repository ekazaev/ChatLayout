//
// ChatLayout
// DefaultImageLoader.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

public struct DefaultImageLoader: ImageLoader {

    public enum ImageError: Error {
        case unknown
        case corruptedData
    }

    public init() {}

    public func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        let sessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, _: URLResponse?, error: Error?) in
            DispatchQueue.global(qos: .utility).async {
                guard let imageData = data else {
                    DispatchQueue.main.async {
                        guard let error = error else {
                            completion(.failure(ImageError.unknown))
                            return
                        }
                        completion(.failure(error))
                    }
                    return
                }
                guard let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async {
                        completion(.failure(ImageError.corruptedData))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            }
        })
        sessionDataTask.resume()
    }

}
