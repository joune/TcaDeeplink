import Foundation
import Combine
import ComposableArchitecture
import SwiftUI

public typealias FeatureStore = StoreOf<FeatureReducer>

public struct FeatureReducer: Reducer {

    public struct State: Equatable {
       let id: String
       var update: String = ""
       var timer: Timer?
    }

    public enum Action {
        case taskStart
        case data(String)
    }

    @Dependency(\.mainQueue) var mainQueue

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .taskStart:
                print("XXX taskStart: \(state.id)")
                state.timer?.invalidate()
                
                return .publisher { self.loadDataAndUpdates(&state.timer, id: state.id)
                        .map { Self.Action.data($0) }
                        .receive(on: self.mainQueue)
                }
            case let .data(d):
                state.update = d
                return .none
            }
        }
    }

    func loadDataAndUpdates(_ timer: inout Timer?, id: String) -> AnyPublisher<String, Never> {
        let pub = CurrentValueSubject<String, Never>("\(id)-0")

        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            let update = "\(id)-\(Date())"
            pub.send(update)
        }
        return pub.eraseToAnyPublisher()
    }
}

public struct FeatureView: View {
    let store: FeatureStore

    @ObservedObject var viewStore: ViewStore<ViewState, FeatureReducer.Action>
    
    struct ViewState: Equatable {
        let id: String
        let update: String
    }


    public init(store: FeatureStore) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: {
            let vs = ViewState(id: $0.id, update: $0.update)
            print("xxx observe \(vs)")
            return vs
        }, send: { $0 })
    }
 
    public var body: some View {
        let _ = Self._printChanges()
        VStack {
            Text("Hello from \(self.viewStore.id)")
            Text("update: \(self.viewStore.update)")
        }
        .id(self.viewStore.id)
        .onChange(of: self.viewStore.id, { oldValue, newValue in
            print("XXX id changed \(oldValue) -> \(newValue)")
        })
        .task {
            await self.viewStore.send(.taskStart).finish()
        }
    }
}

