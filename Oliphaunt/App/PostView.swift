import SwiftUI
import Manfred

struct PostView: View {
    var post: Post
    var booster: Account?

    init(post: Post) {
        self.post = post.displayPost
        if post.reblog != nil {
            booster = post.account
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(url: post.account.avatarStatic)

            content
        }
    }

    private var imageAttachments: [MediaAttachment]? {
        let images = post.media.filter({ $0.type == .image })
        if images.isEmpty {
            return nil
        }

        return images
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits {
                HStack {
                    identity
                }

                VStack(alignment: .leading) {
                    identity
                }
            }

            if let content = post.content {
                Text(content.attributedString)
            }

            if let linkURL = post.linkCardURL {
                LinkPreview(url: linkURL) {
                   ProgressView()
                        .controlSize(.small)
                        .frame(height: 280)
                }
                .frame(maxWidth: 320)
                .overlay {
                    Color.clear.contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(linkURL.absoluteString, forType: .URL)
                                NSPasteboard.general.setString(linkURL.absoluteString, forType: .string)
                            } label: {
                                Text("Copy URL")
                            }

                        }
                }
            }

            if let imageAttachments {
                ImageGalleryView(mediaAttachments: imageAttachments)
                    .frame(maxWidth: 600, minHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Divider()
                .padding(.top, 4)
        }
        .frame(minHeight: 80, alignment: .top)
    }

    @ViewBuilder
    private var identity: some View {
        if !post.account.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(post.account.displayName)
            .font(.headline)
        }

        ViewThatFits {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                username
            }
            VStack(alignment: .leading, spacing: 0) {
                username
            }
        }
    }

    @Environment(\.openWindow) var openWindow

    @ViewBuilder
    private var username: some View {
        let c = post.account.formattedUsernameComponents
        Text(c.handle)
            .foregroundStyle(.secondary)
        if let server = c.server {
            Text(server)
                .foregroundStyle(.tertiary)
        }
    }
}

extension Post {
    var linkCardURL: URL? {
        guard let card, card.type == "link" else { return nil }

        return card.url
    }
}

#if DEBUG
struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(post: .imageAspectRatios)
            .frame(width: 300)
            .padding()
    }
}
#endif
