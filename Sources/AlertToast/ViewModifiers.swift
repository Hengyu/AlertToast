// MIT License
//
// Copyright (c) 2021 Elai Zuberman, 2023 hengyu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Combine
import SwiftUI

struct AlertToastModifier<T: View>: ViewModifier {

    /// Presentation `Binding<Bool>`
    @Binding var isPresenting: Bool

    /// Duration time to display the alert
    @State var duration: TimeInterval = 2

    /// Tap to dismiss alert
    let tapToDismiss: Bool
    let displayMode: AlertDisplayMode
    let toast: () -> T

    /// Completion block returns `true` after dismiss
    let onTap: (() -> Void)?
    let onDismiss: (() -> Void)?

    @State private var dismissalTask: Task<(), Never>?

    init(
        isPresenting: Binding<Bool>,
        duration: TimeInterval = 2,
        tapToDismiss: Bool = true,
        displayMode: AlertDisplayMode,
        @ViewBuilder toast: @escaping () -> T,
        onTap: (() -> Void)?,
        onDismiss: (() -> Void)?
    ) {
        _isPresenting = isPresenting
        self.duration = duration
        self.tapToDismiss = tapToDismiss
        self.displayMode = displayMode
        self.toast = toast
        self.onTap = onTap
        self.onDismiss = onDismiss
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: displayMode.alignment) {
                ZStack {
                    if isPresenting {
                        makeToastContent()
                            .padding(displayMode.padding)
                            .transition(displayMode.transition)
                    }
                }
                // animation on the content may have unexpected behavior if
                // the content itself has configured animation block
                .animation(.spring, value: isPresenting)
            }
            .valueChanged(value: isPresenting) { isPresenting in
                if isPresenting {
                    scheduleDismissal()
                } else {
                    resetDismissal()
                }
            }
    }

    @ViewBuilder
    private func makeToastContent() -> some View {
        toast()
            .adaptiveOnTapGesture {
                dismissToast()
            }
            .onDisappear {
                onDismiss?()
            }
    }

    private func scheduleDismissal() {
        guard duration > 0 else { return }
        dismissalTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            dismissToast()
        }
    }

    private func resetDismissal() {
        dismissalTask?.cancel()
        dismissalTask = nil
    }

    private func dismissToast() {
        withAnimation(.spring) {
            isPresenting = false
        }
    }
}

/// Fileprivate View Modifier for dynamic frame when alert type is `.regular` / `.loading`.
private struct WithFrameModifier: ViewModifier {

    var withFrame: Bool

    #if os(tvOS)
    var maxWidth: CGFloat = 360
    var maxHeight: CGFloat = 360
    #else
    var maxWidth: CGFloat = 175
    var maxHeight: CGFloat = 175
    #endif

    @ViewBuilder
    func body(content: Content) -> some View {
        if withFrame {
            content
                .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .center)
        } else {
            content
        }
    }
}

public extension View {

    /// Present `AlertToast`.
    /// - Parameters:
    ///   - show: `Binding<Bool>`
    ///   - alert: () -> AlertToast
    /// - Returns: `AlertToast`
    func toast<T>(
        isPresenting: Binding<Bool>,
        duration: TimeInterval = 1.2,
        tapToDismiss: Bool = true,
        displayMode: AlertDisplayMode,
        @ViewBuilder toast: @escaping () -> T,
        onTap: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View where T: View {
        modifier(
            AlertToastModifier(
                isPresenting: isPresenting,
                duration: duration,
                tapToDismiss: tapToDismiss,
                displayMode: displayMode,
                toast: toast,
                onTap: onTap,
                onDismiss: onDismiss
            )
        )
    }

    func toast<Item: Equatable, T: View>(
        item: Binding<Item?>,
        duration: TimeInterval = 1.2,
        displayMode: AlertDisplayMode,
        @ViewBuilder toast: @escaping (Item) -> T,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(
            AlertToastValueModifier(
                item: item,
                duration: duration,
                displayMode: displayMode,
                toast: toast,
                onDismiss: onDismiss
            )
        )
    }

    /// Choose the alert background
    /// - Parameter shape: AnyShapeStyle, if `nil` return `.regularMaterial`.
    /// - Returns: some View
    func alertBackground(_ shape: AnyShapeStyle?) -> some View {
        background(shape ?? AnyShapeStyle(.regularMaterial))
    }
}

extension View {

    /// Return some view w/o frame depends on the condition.
    /// This view modifier function is set by default to:
    /// - `maxWidth`: 175
    /// - `maxHeight`: 175
    func withFrame(_ withFrame: Bool) -> some View {
        modifier(WithFrameModifier(withFrame: withFrame))
    }

    @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *) {
            self.onChange(of: value) { _, newValue in
                onChange(newValue)
            }
        } else {
            self.onChange(of: value, perform: onChange)
        }
    }
}

extension Image {
    func hudModifier() -> some View {
        renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 20, maxHeight: 20, alignment: .center)
    }
}
