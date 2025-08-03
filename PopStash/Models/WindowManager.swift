//
//  WindowManager.swift
//  PopStash
//
//  Manages window lifecycle for PopStash windows
//

import SwiftUI
import Observation
import OSLog
import AppKit

private let logger = Logger(subsystem: "com.popstash.app", category: "window-manager")

@Observable
final class WindowManager {
    private var openWindow: ((String) -> Void)?
    private var dismissWindow: ((String) -> Void)?
    
    func setWindowActions(openWindow: @escaping (String) -> Void, dismissWindow: @escaping (String) -> Void) {
        self.openWindow = openWindow
        self.dismissWindow = dismissWindow
    }
    
    func openNotificationWindow() {
        logger.debug("Opening notification window")
        dismissWindow?("notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.openWindow?("notification")
        }
    }
    
    func closeNotificationWindow() {
        logger.debug("Closing notification window")
        dismissWindow?("notification")
    }
    
    func openEditorWindow() {
        logger.debug("Opening editor window")
        openWindow?("textEditor")
    }
    
    func closeEditorWindow() {
        logger.debug("Closing editor window")
        dismissWindow?("textEditor")
    }
}