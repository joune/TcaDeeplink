import ComposableArchitecture
import SwiftUI

public typealias HomeStore = StoreOf<HomeReducer>

public struct HomeReducer: Reducer {
    public struct State: Equatable {
        @PresentationState public var destination: DestinationReducer.State? = nil
    }

    @CasePathable
    public enum Action {
        case buttonTapped(String)
        case close
        case deeplink(String)
        case destination(PresentationAction<DestinationReducer.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .buttonTapped(tappedID):
                state.destination = .feature(FeatureReducer.State(id: tappedID))
                return .run { send in
                    do {
                        try await Task.sleep(for: .seconds(3))
                        await send(.deeplink("timer")) // case 1: view inconsistent state
//                        await send(.close) // case 2: view not updating
                    } catch {
                        print("sleep error \(error)")
                    }
                }
            case .close: // not used in case 1
                state.destination = nil
                //return .none // this closes the feature view
                return .send(.deeplink("after-close")) // but this doesn't
                
            case let .deeplink(notificationID):
                state.destination = .feature(FeatureReducer.State(id: notificationID))
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            DestinationReducer()
        }
    }
}

public struct DestinationReducer: Reducer {
    public enum State: Equatable {
        case feature(FeatureReducer.State)
    }

    public enum Action {
        case feature(FeatureReducer.Action)
    }

    public var body: some ReducerOf<Self> {
        Scope(state: /State.feature, action: /Action.feature) {
            FeatureReducer()
        }
    }
}

public struct HomeView: View {
    let store: HomeStore

    let viewStore: ViewStoreOf<HomeReducer>

    public init(store: HomeStore) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: { $0 }, send: { $0 })
    }
 
     public var body: some View {
         NavigationStack {
             Button(action: { self.viewStore.send(.buttonTapped("button")) }) {
                 Text("click bait")
             }
             .navigationDestination(
                store: self.store.scope(state: \.$destination, action: \.destination),
                state: /DestinationReducer.State.feature,
                action: DestinationReducer.Action.feature
             ) { store in
                 FeatureView(store: store)
             }
         }
     }
}

#Preview {
    HomeView(store: HomeStore(initialState: .init()) {
        HomeReducer()
    })
}
