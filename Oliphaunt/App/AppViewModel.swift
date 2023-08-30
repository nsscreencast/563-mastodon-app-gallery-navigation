import Combine
import SwiftUI

final class AppViewModel: ObservableObject {
    private(set) var accountController = AccountController()

    enum Screen {
        case loading
        case onboarding
        case timeline(TimelineController)
    }

    @Published private(set) var screen = Screen.loading

    private var cancellables = Set<AnyCancellable>()

    init() {
        Task { @MainActor in
            await accountController.autoLogin()

            accountController.$session
                .sink { session in
                    Task { @MainActor in
                        if let session {
                            let timelineController = TimelineController(session: session)
                            self.screen = Screen.timeline(timelineController)
                        } else {
                            self.screen = Screen.onboarding
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
}
