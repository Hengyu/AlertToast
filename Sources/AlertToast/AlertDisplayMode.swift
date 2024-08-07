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

/// Determine how the alert will be display
public enum AlertDisplayMode: Equatable, Sendable {
    public enum BannerAnimation: Equatable, Sendable {
        case slide, pop
    }

    /// Present at the center of the screen
    case alert

    /// Drop from the top of the screen
    case hud

    /// Banner from the bottom of the view
    case banner(_ transition: BannerAnimation)

    var isBanner: Bool {
        switch self {
        case .alert, .hud: false
        case .banner: true
        }
    }

    var padding: Edge.Set {
        switch self {
        case .alert: []
        case .hud: .top
        case .banner: [.bottom, .horizontal]
        }
    }
}

extension AlertDisplayMode {
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

    var alignment: Alignment {
        switch self {
        case .alert: .center
        case .banner: .bottom
        case .hud: .top
        }
    }
}
