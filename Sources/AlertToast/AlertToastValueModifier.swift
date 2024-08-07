// MIT License
//
// Copyright (c) 2024 hengyu
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

import SwiftUI

struct AlertToastValueModifier<Item: Equatable, T: View>: ViewModifier {
    /// A binding to an optional source of truth for the toast.
    /// When item is non-nil, the system passes the item’s content to the modifier’s closure.
    ///
    /// If item changes, the system dismisses the sheet and replaces it with a new one using the same process.
    @Binding var item: Item?

    let displayMode: AlertDisplayMode
    /// Duration time to display the alert
    let duration: Double
    /// Init `AlertToast` View
    let toast: (Item) -> T
    let onDismiss: (() -> Void)?

    @State private var dismissalTask: Task<(), Never>?

    init(
        item: Binding<Item?>,
        duration: TimeInterval,
        displayMode: AlertDisplayMode,
        @ViewBuilder toast: @escaping (Item) -> T,
        onDismiss: (() -> Void)?
    ) {
        _item = item
        self.displayMode = displayMode
        self.duration = duration
        self.toast = toast
        self.onDismiss = onDismiss
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: displayMode.alignment) {
                ZStack {
                    if let item {
                        makeToastContent(item)
                            .padding(displayMode.padding)
                            .transition(displayMode.transition)
                    }
                }
                // animation on the content may have unexpected behavior if
                // the content itself has configured animation block
                .animation(.spring, value: item)
            }
            .valueChanged(value: item) { item in
                if item != nil {
                    scheduleDismissal()
                } else {
                    resetDismissal()
                }
            }
    }

    @ViewBuilder
    private func makeToastContent(_ item: Item) -> some View {
        toast(item)
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
            item = nil
        }
    }
}
