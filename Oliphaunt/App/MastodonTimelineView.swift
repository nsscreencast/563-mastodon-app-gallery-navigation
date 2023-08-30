import SwiftUI
import Manfred

struct MastodonTimelineView: View {
    @ObservedObject var controller: TimelineController

    var body: some View {
        HStack(spacing: 0) {
            Sidebar()
            TimelinePostsView(
                posts: controller.statuses.map(Post.init),
                fetchNextPage: controller.fetchNextPage
            )
        }
        .task {
            await controller.fetchPosts()
        }
    }
}

struct TimelinePostsView: View {
    var posts: [Post]

    var fetchNextPage: () async -> Void

    var body: some View {
        List {
            ForEach(posts) { post in
                PostView(post: post)
                    .padding(.bottom, 8)
            }

            if !posts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .task {
                        await fetchNextPage()
                    }
            }
        }
    }
}

#if DEBUG
struct TimelinePostsView_Previews: PreviewProvider {
    static var previews: some View {
        TimelinePostsView(
            posts: [
                .preview
            ],
            fetchNextPage: {}
        )
        .frame(width: 300)
    }
}
#endif
