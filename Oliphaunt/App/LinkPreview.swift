import SwiftUI
import LinkPresentation

struct LinkPreview<Placeholder: View>: View {
    let url: URL
    @ViewBuilder var placeholder: () -> Placeholder
    @State var metadata: LPLinkMetadata?

    var body: some View {
        Group {
            if let metadata {
                LinkPreviewView(metadata: metadata)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            let metadata = try? await LinkPreviewLoader.shared.loadMetadata(for: url)
            self.metadata = metadata
        }
    }
}

private struct LinkPreviewView: NSViewControllerRepresentable {
    let metadata: LPLinkMetadata

    func makeNSViewController(context: Context) -> LinkPreviewController {
        LinkPreviewController(metadata: metadata)
    }

    func updateNSViewController(_ viewController: LinkPreviewController, context: Context) {
        viewController.metadata = metadata
    }
}

private final class LinkPreviewController: NSViewController {
    var metadata: LPLinkMetadata

    init(metadata: LPLinkMetadata) {
        self.metadata = metadata

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var linkView: LPLinkView = {
        let linkView = LPLinkView(metadata: metadata)
        linkView.translatesAutoresizingMaskIntoConstraints = false
        return linkView
    }()

    private lazy var minWidthConstraint: NSLayoutConstraint = {
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
    }()

    private lazy var minHeightConstraint: NSLayoutConstraint = {
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
    }()

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(linkView)

        NSLayoutConstraint.activate([
            linkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            linkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            linkView.topAnchor.constraint(equalTo: view.topAnchor),
            linkView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            minWidthConstraint,
            minHeightConstraint
        ])
    }

    override func viewWillLayout() {
        let size = linkView.fittingSize

        minWidthConstraint.constant = size.width
        minHeightConstraint.constant = size.height

        super.viewWillLayout()
    }
}

private final class LinkPreviewLoader {
    static let shared = LinkPreviewLoader()

    private var cache: NSCache<NSString, LPLinkMetadata> = .init()

    func loadMetadata(for url: URL) async throws -> LPLinkMetadata {
        let cacheKey = url.absoluteString.lowercased() as NSString
        if let cachedMetadata = cache.object(forKey: cacheKey) {
            return cachedMetadata
        }
        let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
        cache.setObject(metadata, forKey: cacheKey)
        return metadata
    }
}

#if DEBUG
struct LinkPreview_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            LinkPreview(
                url: URL("https://nsscreencast.com/episodes/550-mastodon-app-oauth-keychain")
            ) {
                Color.pink
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
