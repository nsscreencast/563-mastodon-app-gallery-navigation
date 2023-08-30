import SwiftUI
import Manfred


struct ImageGalleryView: View {
    let mediaAttachments: [MediaAttachment]

    struct LayoutItem: Identifiable {
        var id: Int { index }
        let index: Int
        let media: MediaAttachment
        let frame: CGRect

        var debugTintColor: Color {
            [Color.red, .blue, .green][index % 3].opacity(0.5)
        }
    }

    func layout(proxy: GeometryProxy) -> [LayoutItem] {
        let maxItemsPerRow = mediaAttachments.count == 1 ? 1 : 2
        let numberOfRows = Int(ceil(CGFloat(mediaAttachments.count) / CGFloat(maxItemsPerRow)))
        var x: CGFloat = 0
        var y: CGFloat = 0
        let templateWidth: CGFloat = proxy.size.width / CGFloat(maxItemsPerRow)
        let height: CGFloat = proxy.size.height / CGFloat(numberOfRows)
        var items: [LayoutItem] = []
        for index in mediaAttachments.indices {
            var width = templateWidth
            let media = mediaAttachments[index]
            if x + width > proxy.size.width {
                // new row
                y += height
                x = 0
            }

            if index == mediaAttachments.count - 1, x == 0 {
                // last item is by itself on a row, then fill it
                width = proxy.size.width
            }

            let rect = CGRect(
                x: x + width/2,
                y: y + height/2,
                width: width,
                height: height
            )
            items.append(.init(index: index, media: media, frame: rect))

            x += width
        }

        return items
    }

    var body: some View {
        GeometryReader { proxy in
            let items = layout(proxy: proxy)
            ForEach(items) { item in
                imageItem(item: item)
            }
        }
    }

    private func imageItem(item: LayoutItem) -> some View {
        RemoteImageView(url: item.media.previewUrl!) { image in
            image
                .resizable()
                .onTapWithSourceRect { sourceRect in
                    GalleryWindowManager.shared.show(
                        media: self.mediaAttachments,
                        selectedIndex: item.index,
                        sourceRect: sourceRect,
                        placeholderImage: image
                    )
                }
            
        } placeholder: {
            Color.gray
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: item.frame.width, height: item.frame.height)
        .clipped()
        .contentShape(Rectangle())

        .position(item.frame.origin)
    }
}

struct TapGestureWithSourceRectModifier: ViewModifier {
    let block: (NSRect) -> Void

    func body(content: Content) -> some View {
        content
            .overlay(TapGestureWithSourceRectView(block: block))
    }
}

struct TapGestureWithSourceRectView: NSViewRepresentable {
    let block: (NSRect) -> Void

    func makeNSView(context: Context) -> _TapGestureWithSourceRectNSView {
        _TapGestureWithSourceRectNSView(block: block)
    }

    func updateNSView(_ nsView: _TapGestureWithSourceRectNSView, context: Context) {
    }

    final class _TapGestureWithSourceRectNSView: NSView {
        let block: (NSRect) -> Void

        init(block: @escaping (NSRect) -> Void) {
            self.block = block
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("what year is it?!")
        }

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)

            guard let window else { return }
            guard let superview else { return }

            // if we are in a scroll view (for example) it is important to ask
            // super to convert to get a real answer
            let windowFrame = superview.convert(frame, to: nil)
            let screenFrame = window.convertToScreen(windowFrame)

            block(screenFrame)
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }
    }
}


extension View {
    func onTapWithSourceRect(_ block: @escaping (NSRect) -> Void) -> some View {
        modifier(TapGestureWithSourceRectModifier(block: block))
    }
}

#if DEBUG
struct ImageGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        let post = Post.imageAspectRatios
        ImageGalleryView(mediaAttachments: post.media)
    }
}
#endif
