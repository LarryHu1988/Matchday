import SwiftUI
import WebKit

// MARK: - Reusable Crest Image with SVG Support
// Football-data.org API returns SVG URLs for crests/emblems.
// iOS AsyncImage cannot render SVGs, so SVG URLs use a lightweight
// WKWebView-based renderer that downloads and rasterises the SVG.

struct CrestImage: View {
    let url: String?
    let size: CGFloat

    init(_ url: String?, size: CGFloat = 30) {
        self.url = url
        self.size = size
    }

    var body: some View {
        if let url = url, let imageURL = URL(string: url) {
            if url.lowercased().hasSuffix(".svg") {
                SVGCrestView(url: imageURL, size: size)
            } else {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size, height: size)
                    case .failure:
                        placeholderIcon
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        placeholderIcon
                    }
                }
            }
        } else {
            placeholderIcon
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "shield.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(.gray.opacity(0.3))
    }
}

// MARK: - SVG Crest View
// Downloads SVG data, renders it in a tiny off-screen WKWebView,
// snapshots the result into a UIImage, caches it.

struct SVGCrestView: View {
    let url: URL
    let size: CGFloat
    @State private var uiImage: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else if didFail {
                Image(systemName: "shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundStyle(.gray.opacity(0.3))
            } else {
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        // Check cache first
        if let cached = SVGCache.shared.image(for: url, size: size) {
            uiImage = cached
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Some "SVG" URLs actually return PNG/JPEG data
            if let directImage = UIImage(data: data) {
                SVGCache.shared.store(directImage, for: url, size: size)
                uiImage = directImage
                return
            }

            // Render SVG via WKWebView snapshot
            guard let svgString = String(data: data, encoding: .utf8) else {
                didFail = true
                return
            }

            let rendered = await renderSVG(svgString)
            if let rendered {
                SVGCache.shared.store(rendered, for: url, size: size)
                uiImage = rendered
            } else {
                didFail = true
            }
        } catch {
            didFail = true
        }
    }

    @MainActor
    private func renderSVG(_ svgString: String) async -> UIImage? {
        let pixelSize = size * 3 // @3x retina
        let html = """
        <!DOCTYPE html>
        <html><head><meta name="viewport" content="width=\(Int(pixelSize)),initial-scale=1">
        <style>
        * { margin:0; padding:0; }
        body { width:\(Int(pixelSize))px; height:\(Int(pixelSize))px; display:flex; align-items:center; justify-content:center; background:transparent; }
        svg { max-width:100%; max-height:100%; }
        </style></head>
        <body>\(svgString)</body></html>
        """

        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize), configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        webView.loadHTMLString(html, baseURL: nil)

        // Wait for content to load
        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            if !webView.isLoading { break }
        }
        // Extra settle time for rendering
        try? await Task.sleep(nanoseconds: 100_000_000)

        let snapshotConfig = WKSnapshotConfiguration()
        snapshotConfig.snapshotWidth = NSNumber(value: Double(pixelSize))

        return try? await webView.takeSnapshot(configuration: snapshotConfig)
    }
}

// MARK: - Simple SVG Image Cache

final class SVGCache: @unchecked Sendable {
    static let shared = SVGCache()
    private var cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
    }

    func image(for url: URL, size: CGFloat) -> UIImage? {
        cache.object(forKey: cacheKey(url, size))
    }

    func store(_ image: UIImage, for url: URL, size: CGFloat) {
        cache.setObject(image, forKey: cacheKey(url, size))
    }

    private func cacheKey(_ url: URL, _ size: CGFloat) -> NSString {
        "\(url.absoluteString)_\(Int(size))" as NSString
    }
}

// MARK: - Loading State View

struct LoadingView: View {
    let message: String

    init(_ message: String = "") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message.isEmpty ? L10n.loading : message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button(L10n.retry) {
                    retryAction()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
