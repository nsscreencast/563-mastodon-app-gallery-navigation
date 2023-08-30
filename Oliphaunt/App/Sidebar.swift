import SwiftUI

struct Sidebar: View {
    @EnvironmentObject var accountController: AccountController

    var body: some View {
        VStack {
            AvatarView(url: accountController.account?.avatarStatic)
                .padding(8)

            Spacer()
        }
        .background {
            List {}.listStyle(.sidebar) // trick to get translucent background
        }
    }
}

#if DEBUG
struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
            .environmentObject(AccountController())
    }
}
#endif
