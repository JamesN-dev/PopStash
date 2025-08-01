//
//  AppKitBridge 2.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//


import Foundation

@MainActor
final class AppKitBridge: ObservableObject {
    let windowOpenStream: AsyncStream<Void>
    private var continuation: AsyncStream<Void>.Continuation

    init() {
        (self.windowOpenStream, self.continuation) = AsyncStream.makeStream(of: Void.self)
    }

    func signalOpenWindow() {
        continuation.yield(())
    }
}
