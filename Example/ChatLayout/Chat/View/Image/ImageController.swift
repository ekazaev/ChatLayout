//
// ChatLayout
// ImageController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020.
// Distributed under the MIT license.
//

import Foundation
import UIKit

final class ImageController {

    weak var view: ImageView? {
        didSet {
            view?.reloadData()
        }
    }

    weak var delegate: ReloadDelegate?

    var state: ImageViewState {
        guard let image = image else {
            return .loading
        }
        return .image(image)
    }

    private var image: UIImage?

    private let messageId: UUID

    private let source: ImageMessageSource

    private let bubbleController: BubbleController

    init(source: ImageMessageSource, messageId: UUID, bubbleController: BubbleController) {
        self.source = source
        self.messageId = messageId
        self.bubbleController = bubbleController
        loadImage()
    }

    private func loadImage() {
        switch source {
        case let .imageURL(url):
            if let image = try? imageCache.getEntity(for: .init(url: url)) {
                self.image = image
                view?.reloadData()
            } else {
                loader.loadImage(from: url) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    self.image = try? result.get()
                    self.delegate?.reloadMessage(with: self.messageId)
                }
            }
        case let .image(image):
            self.image = image
            view?.reloadData()
        }
    }

}
