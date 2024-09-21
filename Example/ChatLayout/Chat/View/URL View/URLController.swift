//
// ChatLayout
// URLController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import LinkPresentation

@available(iOS 13, *)
final class URLController {
    let url: URL

    var metadata: LPLinkMetadata?

    weak var delegate: ReloadDelegate?

    weak var view: URLView? {
        didSet {
            UIView.performWithoutAnimation {
                view?.reloadData()
            }
        }
    }

    private let provider = LPMetadataProvider()

    private let messageId: UUID

    private let bubbleController: BubbleController

    init(url: URL, messageId: UUID, bubbleController: BubbleController) {
        self.url = url
        self.messageId = messageId
        self.bubbleController = bubbleController
        startFetchingMetadata()
    }

    private func startFetchingMetadata() {
        if let metadata = try? metadataCache.getEntity(for: url) {
            self.metadata = metadata
            view?.reloadData()
        } else {
            provider.startFetchingMetadata(for: url) { [weak self] metadata, error in
                guard let self,
                      let metadata,
                      error == nil else {
                    return
                }

                try? metadataCache.store(entity: metadata, for: url)

                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        return
                    }
                    if #available(iOS 16.0, *),
                       enableSelfSizingSupport {
                        self.metadata = metadata
                        view?.reloadData()
                    } else {
                        delegate?.reloadMessage(with: messageId)
                    }
                }
            }
        }
    }
}
