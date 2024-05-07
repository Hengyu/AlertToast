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

public struct AlertToastModifier: ViewModifier {

    /// Presentation `Binding<Bool>`
    @Binding var isPresenting: Bool

    /// Duration time to display the alert
    @State var duration: Double = 2

    /// Tap to dismiss alert
    @State var tapToDismiss: Bool = true

    var offsetY: CGFloat = 0

    /// Init `AlertToast` View
    var alert: () -> AlertToast

    /// Completion block returns `true` after dismiss
    var onTap: (() -> Void)?
    var completion: (() -> Void)?

    @State private var workItem: DispatchWorkItem?

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

    @ViewBuilder
    public func main() -> some View {
        if isPresenting {
            let value = alert()

            value
                .overlay(
                    GeometryReader {
                        saveAlertRect($0)
                    }
                )
                .adaptiveOnTapGesture {
                    onTap?()
                    if tapToDismiss {
                        withAnimation(.spring()) {
                            self.workItem?.cancel()
                            isPresenting = false
                            self.workItem = nil
                        }
                    }
                }
                .onDisappear {
                    completion?()
                }
                .transition(
                    {
                        switch value.displayMode {
                        case .alert:
                            return AnyTransition.scale(scale: 0.8).combined(with: .opacity)
                        case .banner(let transition):
                            return transition == .slide
                            ? AnyTransition.slide.combined(with: .opacity)
                            : AnyTransition.move(edge: .bottom)
                        case .hud:
                            return AnyTransition.move(edge: .top).combined(with: .opacity)
                        }
                    }()
                )
        }
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        switch alert().displayMode {
        case .banner:
            content
                .overlay(
                    ZStack {
                        main()
                            .offset(y: offsetY)
                    }
                        .animation(Animation.spring(), value: isPresenting)
                )
                .valueChanged(value: isPresenting) { presented in
                    if presented {
                        onAppearAction()
                    }
                }
        case .hud:
            content
                .overlay(
                    GeometryReader { geo -> AnyView in
                        let rect = geo.frame(in: .global)

                        if rect.integral != hostRect.integral {
                            DispatchQueue.main.async {
                                self.hostRect = rect
                            }
                        }
                        return AnyView(EmptyView())
                    }
                        .overlay(
                            ZStack {
                                main()
                                    .offset(y: offsetY)
                            }
                                .frame(maxWidth: size.width, maxHeight: size.height)
                                .offset(y: offset)
                                .animation(Animation.spring(), value: isPresenting)
                        )
                )
                .valueChanged(value: isPresenting) { presented in
                    if presented {
                        onAppearAction()
                    }
                }
        case .alert:
            content
                .overlay(
                    ZStack {
                        main()
                            .offset(y: offsetY)
                    }
                        .frame(maxWidth: size.width, maxHeight: size.height, alignment: .center)
                        .edgesIgnoringSafeArea(.all)
                        .animation(Animation.spring(), value: isPresenting)
                )
                .valueChanged(value: isPresenting) { presented in
                    if presented {
                        onAppearAction()
                    }
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

    private func onAppearAction() {
        guard workItem == nil else {
            return
        }

        if alert().type == .loading {
            duration = 0
            tapToDismiss = false
        }

        if duration > 0 {
            workItem?.cancel()

            let task = DispatchWorkItem {
                withAnimation(Animation.spring()) {
                    isPresenting = false
                    workItem = nil
                }
            }
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
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

/// Fileprivate View Modifier to change the alert background.
private struct BackgroundModifier: ViewModifier {

    var color: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let color {
            content
                .background(color)
        } else {
            content.background(.regularMaterial)
        }
    }
}

public extension View {

    /// Return some view w/o frame depends on the condition.
    /// This view modifier function is set by default to:
    /// - `maxWidth`: 175
    /// - `maxHeight`: 175
    func withFrame(_ withFrame: Bool) -> some View {
        modifier(WithFrameModifier(withFrame: withFrame))
    }

    /// Present `AlertToast`.
    /// - Parameters:
    ///   - show: `Binding<Bool>`
    ///   - alert: () -> AlertToast
    /// - Returns: `AlertToast`
    func toast(
        isPresenting: Binding<Bool>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping () -> AlertToast,
        onTap: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> some View {
        modifier(
            AlertToastModifier(
                isPresenting: isPresenting,
                duration: duration,
                tapToDismiss: tapToDismiss,
                offsetY: offsetY,
                alert: alert,
                onTap: onTap,
                completion: completion
            )
        )
    }

    /// Choose the alert background
    /// - Parameter color: Some Color, if `nil` return `VisualEffectBlur`
    /// - Returns: some View
    func alertBackground(_ color: Color? = nil) -> some View {
        modifier(BackgroundModifier(color: color))
    }

    @ViewBuilder fileprivate func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
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
