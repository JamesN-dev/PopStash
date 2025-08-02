//
//  PopupWindowController.swift
//  PopStash
//
//  Created by atetraxx on 8/2/25.
//

import SwiftUI

struct PopupWindowController: View {
    @Bindable var popupManager: NotificationPopupManager
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        Color.clear
            .onChange(of: popupManager.isShowing) { oldValue, isShowing in
                print("PopupWindowController: isShowing changed \(oldValue) -> \(isShowing)")
                if isShowing {
                    print("Calling openWindow(id: 'notification')")
                    openWindow(id: "notification")
                } else {
                    print("Calling dismissWindow(id: 'notification')")
                    dismissWindow(id: "notification")
                }
            }
    }
}
