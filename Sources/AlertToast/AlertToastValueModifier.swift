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

extension AlertToast.DisplayMode {
    var transition: AnyTransition {
        switch self {
        case .alert:
            return AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        case .banner(let transition):
            return transition == .slide
            ? AnyTransition.slide.combined(with: .opacity)
            : AnyTransition.move(edge: .bottom)
        case .hud:
            return AnyTransition.move(edge: .top).combined(with: .opacity)
        }
    }
}

struct AlertToastValueModifier<T: Equatable>: ViewModifier {
    /// A binding to an optional source of truth for the toast.
    /// When item is non-nil, the system passes the item’s content to the modifier’s closure.
    ///
    /// If item changes, the system dismisses the sheet and replaces it with a new one using the same process.
    @Binding var item: T?

    let displayMode: AlertToast.DisplayMode

    /// Duration time to display the alert
    @State var duration: Double = 2

    var offsetY: CGFloat = 0

    /// Init `AlertToast` View
    var alert: (T) -> AlertToast

    var onDismiss: (() -> Void)?

    @State private var hostRect: CGRect = .zero
    @State private var alertRect: CGRect = .zero

    private var size: CGSize {
        #if os(iOS) || os(tvOS)
        return UIScreen.main.bounds.size
        #elseif os(macOS)
        if let frame = NSScreen.main?.frame {
            return .init(width: frame.width, height: frame.height)
        } else {
            return .zero
        }
        #else
        return .init(width: 200, height: 100)
        #endif
    }

    private var offset: CGFloat {
        -hostRect.midY + alertRect.height
    }

    func body(content: Content) -> some View {
        Group {
            if let item {
                makeToast(content, item: item)
            } else {
                content
            }
        }
        .animation(.spring, value: item)
        .valueChanged(value: item) { item in
            if item != nil, duration > 0 {
                handleNewItem()
            }
        }
    }

    @ViewBuilder
    private func makeToastContent(_ item: T) -> some View {
        alert(item).makeBody(displayMode)
            .overlay {
                GeometryReader {
                    saveAlertRect($0)
                }
            }
            .adaptiveOnTapGesture {
                dismissToast()
            }
            .onDisappear {
                onDismiss?()
            }
            .transition(displayMode.transition)
    }

    @ViewBuilder
    private func makeToast(_ content: Content, item: T) -> some View {
        content
            .overlay {
                switch displayMode {
                case .alert:
                    makeToastContent(item)
                        .offset(y: offsetY)
                        .frame(maxWidth: size.width, maxHeight: size.height, alignment: .center)
                        .edgesIgnoringSafeArea(.all)
                case .hud:
                    GeometryReader { geo -> AnyView in
                        let rect = geo.frame(in: .global)

                        if rect.integral != hostRect.integral {
                            DispatchQueue.main.async {
                                self.hostRect = rect
                            }
                        }
                        return AnyView(EmptyView())
                    }
                    .overlay {
                        makeToastContent(item)
                            .frame(maxWidth: size.width, maxHeight: size.height)
                            .offset(y: offset)
                    }
                case .banner:
                    makeToastContent(item)
                        .offset(y: offsetY)
                }
            }
    }

    private func saveAlertRect(_ geo: GeometryProxy) -> some View {
        let rect = geo.frame(in: .global)
        if rect.integral != alertRect.integral {
            DispatchQueue.main.async {
                self.alertRect = rect
            }
        }
        return AnyView(EmptyView())
    }

    private func handleNewItem() {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            dismissToast()
        }
    }

    private func dismissToast() {
        withAnimation(.spring) {
            self.item = nil
        }
    }
}
