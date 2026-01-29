//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Timur Badretdinov on 29/01/2026.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest(success: false)
            return
        }

        let urlType = UTType.url.identifier

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(urlType) {
                attachment.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            self?.saveURL(url)
                        } else if let urlData = item as? Data,
                                  let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                            self?.saveURL(url)
                        } else {
                            self?.completeRequest(success: false)
                        }
                    }
                }
                return
            }
        }

        // Try plain text (might contain URL)
        let textType = UTType.plainText.identifier
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(textType) {
                attachment.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let text = item as? String,
                           let url = URL(string: text),
                           url.scheme?.hasPrefix("http") == true {
                            self?.saveURL(url)
                        } else {
                            self?.completeRequest(success: false)
                        }
                    }
                }
                return
            }
        }

        completeRequest(success: false)
    }

    private func saveURL(_ url: URL) {
        SharedURLManager.addPendingURL(url)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Brief delay to let haptic complete before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.completeRequest(success: true)
        }
    }

    private func completeRequest(success: Bool) {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
