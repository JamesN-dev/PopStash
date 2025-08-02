
SwiftUI Window Focus + Dragging Issue - Need Scene-Level Solution

I have a SwiftUI notification popup that requires two clicks to interact
with:

1. First click focuses the window
2. Second click triggers the interaction

Current Setup:

• Using Window("Notification", id: "notification") in App file
• Currently has .windowStyle(HiddenTitleBarWindowStyle()) and .
windowLevel(.floating)
• Want to switch to .windowStyle(.plain) to remove window buttons
entirely
• Notification content uses .onTapGesture (will convert to Button)

Dragging Implementation Problem: I have a perfect custom drag
implementation in PopEditor.swift that uses:

@State private var location = CGPoint(x: 200, y: 200)
@GestureState private var startLocation: CGPoint?
@State private var isDragging = false

var drag: some Gesture {
    DragGesture()
        .onChanged { value in
            self.location = value.location
            isDragging = true
        }
        .onEnded { value in
            isDragging = false
        }
}

// Applied with: .position(location) and .gesture(drag)

The Problem: This moves the view CONTENT but leaves the SwiftUI Window
frame in place, creating a "floating content inside static window"
effect.


Questions:

1. Will .windowStyle(.plain) fix the focus issue by making the window
immediately interactive?
2. How do I move this exact drag implementation to the Window Scene
level so it drags the entire window?
3. What's the correct Scene-level modifier for window activation?
4. Do floating windows (.windowLevel(.floating)) behave differently with
auto-focus?

IMPORTANT - Use context7 to verify these uncertain items:

• Search "SwiftUI Window drag gesture scene level" - how to apply drag
gestures to entire windows
• Search "SwiftUI allowsWindowActivationEvents" - verify if this
modifier exists and correct usage
• Search "SwiftUI windowStyle plain focus behavior" - confirm if .plain
windows auto-focus better
• Search "SwiftUI windowLevel floating focus behavior" - understand
floating window focus behavior
• Search "SwiftUI Window scene modifiers" - complete list of available
Window modifiers

Don't guess on any SwiftUI APIs - use context7 to fetch official
documentation for each uncertain topic above.

Goal: Single-click interaction on a button-free, draggable notification
popup where the entire window moves (not just content), working for both
notification and editor states.
