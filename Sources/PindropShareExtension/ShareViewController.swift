import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    private let viewModel = ShareViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
        extractURL()
    }

    // MARK: - UI Setup

    private func setupUI() {
        let rootView = ShareRootView(
            viewModel: viewModel,
            onOpenMaps: { [weak self] place, app in
                self?.openInMaps(place: place, app: app)
            },
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(
                    withError: NSError(domain: "PindropShareExtension", code: NSUserCancelledError)
                )
            }
        )

        let host = UIHostingController(rootView: rootView)
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - URL Extraction

    private func extractURL() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            setError("無法取得分享內容")
            return
        }

        // 印出所有 attachment 的 type，方便 debug
        for (i, item) in items.enumerated() {
            for (j, provider) in (item.attachments ?? []).enumerated() {
                print("[Pindrop] item[\(i)] attachment[\(j)] types: \(provider.registeredTypeIdentifiers)")
            }
        }

        // 依優先順序嘗試取得 URL
        for item in items {
            for provider in item.attachments ?? [] {

                // 優先嘗試 public.url
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] result, error in
                        print("[Pindrop] public.url result: \(String(describing: result)), error: \(String(describing: error))")
                        DispatchQueue.main.async {
                            if let url = result as? URL {
                                print("[Pindrop] Got URL: \(url)")
                                print("[Pindrop] Calling process(url:)...")
                                self?.viewModel.process(url: url)
                                print("[Pindrop] process(url:) returned")
                            } else if let str = result as? String, let url = URL(string: str) {
                                print("[Pindrop] Got URL from string: \(url)")
                                self?.viewModel.process(url: url)
                            } else {
                                self?.tryPlainText(from: item)
                            }
                        }
                    }
                    return
                }
            }
        }

        // Fallback：嘗試 plain-text（Instagram 有時只給文字含 URL）
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    tryPlainText(from: item)
                    return
                }
            }
        }

        setError("找不到連結")
    }

    private func tryPlainText(from item: NSExtensionItem) {
        for provider in item.attachments ?? [] {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] result, error in
                    print("[Pindrop] plain-text result: \(String(describing: result)), error: \(String(describing: error))")
                    DispatchQueue.main.async {
                        let text = result as? String ?? ""
                        // 從文字中抽出第一個 URL
                        if let url = self?.extractFirstURL(from: text) {
                            print("[Pindrop] Extracted URL from text: \(url)")
                            self?.viewModel.process(url: url)
                        } else {
                            print("[Pindrop] No URL found in text: \(text)")
                            self?.setError("找不到連結")
                        }
                    }
                }
                return
            }
        }
        setError("找不到連結")
    }

    private func extractFirstURL(from text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard let match = matches?.first, let range = Range(match.range, in: text) else { return nil }
        return URL(string: String(text[range]))
    }

    // MARK: - Maps Opening

    /// 依用戶選擇的地圖 App 開啟。
    /// Apple Maps 使用 maps.apple.com universal link；Google Maps 優先 comgooglemaps:// 再 fallback 到網頁版。
    private func openInMaps(place: Place, app: MapsApp) {
        switch app {
        case .apple:
            let url = MapsService.appleMapsURL(name: place.name, address: place.address)
            openViaResponderChain(url: url)

        case .google:
            let appURL = MapsService.googleMapsAppURL(placeId: place.id, name: place.name)
            let webURL = MapsService.googleMapsWebURL(placeId: place.id, name: place.name)
            // Share Extension 無法直接用 UIApplication.shared，改走 responder chain
            let opened = openViaResponderChain(url: appURL)
            if !opened { _ = openViaResponderChain(url: webURL) }
        }

        extensionContext?.completeRequest(returningItems: nil)
    }

    @discardableResult
    private func openViaResponderChain(url: URL) -> Bool {
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url)
                print("[Pindrop] Opened URL via responder chain: \(url)")
                return true
            }
            responder = r.next
        }
        print("[Pindrop] Responder chain: UIApplication not found, trying extensionContext")
        extensionContext?.open(url)
        return false
    }

    // MARK: - Helpers

    private func setError(_ message: String) {
        Task { @MainActor in
            viewModel.state = .error(message)
        }
    }
}
