import AppKit
import SwiftUI
import Manfred

final class GalleryWindowManager {
    static let shared = GalleryWindowManager()

    private var windowController: GalleryWindowController?

    func show(media: [MediaAttachment], selectedIndex: Int, sourceRect: NSRect, placeholderImage: Image?) {
        windowController?.close()

        windowController = GalleryWindowController(
            media: media,
            selectedIndex: selectedIndex,
            sourceRect: sourceRect,
            placeholderImage: placeholderImage
        )
        windowController?.showWindow(self)
    }
}

private final class GalleryWindowController: NSWindowController {
    convenience init(media: [MediaAttachment], selectedIndex: Int, sourceRect: NSRect, placeholderImage: Image?) {
        let panel = NSPanel(
            contentRect: sourceRect,
            styleMask: [.hudWindow, .utilityWindow, .closable, .resizable, .titled],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(
            rootView:
                GalleryRoot(media: media, selectedIndex: selectedIndex, placeholderImage: placeholderImage)
                .frame(minWidth: sourceRect.width, maxWidth: .infinity, minHeight: sourceRect.height, maxHeight: .infinity)
        )
        self.init(window: panel)
    }

    override func showWindow(_ sender: Any?) {
        guard let window else { return }

        window.makeKeyAndOrderFront(self)

        let targetSize = CGSize(width: 800, height: 600)
        let targetOrigin = CGPoint(
            x: window.frame.midX - targetSize.width/2,
            y: window.frame.midY - targetSize.height/2
        )
        let largerFrame = CGRect(origin: targetOrigin, size: targetSize)
        NSAnimationContext.runAnimationGroup { context in
            context.timingFunction = .init(name: .easeInEaseOut)
            window.animator().setFrame(largerFrame, display: true)
        }
    }
}

private struct GalleryRoot: View {
    let media: [MediaAttachment]
    @State var selectedIndex: Int
    @State var placeholderImage: Image?

    var body: some View {
        ZoomingView {
            imageItem(imageURL: media[selectedIndex].url)
        }
        .id(selectedIndex)
        .overlay {
            if media.count > 1 {
                navigationButtons
            }
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
            Button {
                selectedIndex -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedIndex <= 0)

            Spacer()

            Button {
                selectedIndex += 1
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedIndex >= media.count - 1)
        }
        .buttonStyle(_ImageNavigationButtonStyle())
        .padding()
    }

    private func imageItem(imageURL: URL) -> some View {
        RemoteImageView(url: imageURL) { image in
            image.resizable()
                .task {
                    // no longer need this and we don't want to show it
                    // for other images in this gallery
                    placeholderImage = nil
                }
        } placeholder: {
            if let placeholderImage {
                placeholderImage.resizable()
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(minWidth: 200, minHeight: 200)
    }
}

struct ZoomingView<T: View>: NSViewRepresentable {
    @ViewBuilder let content: () -> T

    func makeNSView(context: Context) -> _ZoomingView {
        _ZoomingView(contentView: NSHostingView(rootView: content()))
    }

    func updateNSView(_ zoomingNSView: _ZoomingView, context: Context) {
    }
}

final class _ZoomingView: NSView {
    let contentView: NSView
    let scrollView: NSScrollView

    init(contentView: NSView) {
        self.contentView = contentView
        scrollView = NSScrollView()
        super.init(frame: .zero)

        scrollView.frame = bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 10
        scrollView.backgroundColor = .black

        contentView.frame = bounds
        contentView.autoresizingMask = [.width, .height]

        addSubview(scrollView)
        scrollView.documentView = contentView
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let zoomStep: CGFloat = 1
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "=" {
            changeZoom(delta: zoomStep)
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "-" {
            changeZoom(delta: -zoomStep)
        } else {
            super.keyDown(with: event)
        }
    }

    private func changeZoom(delta: CGFloat) {
        scrollView.animator().magnification += delta
    }
}

private struct _ImageNavigationButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .padding(12)
            .background(.thinMaterial, in: Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .opacity(isEnabled ? 1 : 0.4)
    }
}

struct GalleryRoot_Previews: PreviewProvider {
    static var previews: some View {
        GalleryRoot(
            media: Post.imageAspectRatios.media, selectedIndex: 1,
            placeholderImage: nil
        )
    }
}
