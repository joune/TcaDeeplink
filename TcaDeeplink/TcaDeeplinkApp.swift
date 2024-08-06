import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    let homeStore: HomeStore

    override public init() {

        self.homeStore = HomeStore(initialState: .init()) {
            HomeReducer()
        }
    }
    
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        print("did receive notification (tapped)")

        self.homeStore.send(.deeplink("notification"))
    }
}

@main
struct app: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView(store: self.appDelegate.homeStore)
        }
    }
}

