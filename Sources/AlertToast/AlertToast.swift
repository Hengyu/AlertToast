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

import SwiftUI

// MARK: - Main View

public struct AlertToast: View {

    public enum BannerAnimation {
        case slide, pop
    }

    /// Determine how the alert will be display
    public enum DisplayMode: Equatable {

        /// Present at the center of the screen
        case alert

        /// Drop from the top of the screen
        case hud

        /// Banner from the bottom of the view
        case banner(_ transition: BannerAnimation)
    }

    /// Determine what the alert will display
    public enum AlertType: Equatable {

        /// Animated checkmark
        case complete(_ color: Color)

        /// Animated xmark
        case error(_ color: Color)

        /// System image from `SFSymbols`
        case systemImage(_ name: String, _ color: Color)

        /// Image from Assets
        case image(_ name: String, _ color: Color)

        /// Loading indicator (Circular)
        case loading

        /// Only text alert
        case regular
    }

    /// Customize Alert Appearance
    public enum AlertStyle: Equatable {

        case style(
            backgroundColor: Color? = nil,
            titleColor: Color? = nil,
            subTitleColor: Color? = nil,
            titleFont: Font? = nil,
            subTitleFont: Font? = nil
        )

        /// Get background color
        var backgroundColor: Color? {
            switch self {
            case .style(backgroundColor: let color, _, _, _, _):
                return color
            }
        }

        /// Get title color
        var titleColor: Color? {
            switch self {
            case .style(_, let color, _, _, _):
                return color
            }
        }

        /// Get subTitle color
        var subtitleColor: Color? {
            switch self {
            case .style(_, _, let color, _, _):
                return color
            }
        }

        /// Get title font
        var titleFont: Font? {
            switch self {
            case .style(_, _, _, titleFont: let font, _):
                return font
            }
        }

        /// Get subTitle font
        var subTitleFont: Font? {
            switch self {
            case .style(_, _, _, _, subTitleFont: let font):
                return font
            }
        }
    }

    /// The display mode
    /// - `alert`
    /// - `hud`
    /// - `banner`
    internal let displayMode: DisplayMode

    /// What the alert would show
    /// `complete`, `error`, `systemImage`, `image`, `loading`, `regular`
    internal let type: AlertType

    /// The title of the alert.
    private let title: LocalizedStringKey?

    /// The subtitle of the alert.
    private let subtitle: LocalizedStringKey?

    /// Customize your alert appearance
    private let style: AlertStyle?

    /// Full init
    public init(
        displayMode: DisplayMode = .alert,
        type: AlertType,
        title: String? = nil,
        subTitle: String? = nil,
        style: AlertStyle? = nil
    ) {
        self.displayMode = displayMode
        self.type = type
        self.title = title.flatMap { LocalizedStringKey($0) }
        self.subtitle = subTitle.flatMap { LocalizedStringKey($0) }
        self.style = style
    }

    public init(
        displayMode: DisplayMode = .alert,
        type: AlertType,
        title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        style: AlertStyle? = nil
    ) {
        self.displayMode = displayMode
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }

    /// Short init with most used parameters
    public init(
        displayMode: DisplayMode,
        type: AlertType,
        title: String? = nil
    ) {
        self.displayMode = displayMode
        self.type = type
        self.title = title.flatMap { LocalizedStringKey($0) }
        self.subtitle = nil
        self.style = nil
    }

    /// Banner from the bottom of the view
    public var banner: some View {
        VStack {
            Spacer()

            // Banner view starts here
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    switch type {
                    case .complete(let color):
                        Image(systemName: "checkmark")
                            .foregroundColor(color)
                    case .error(let color):
                        Image(systemName: "xmark")
                            .foregroundColor(color)
                    case .systemImage(let name, let color):
                        Image(systemName: name)
                            .foregroundColor(color)
                    case .image(let name, let color):
                        Image(name)
                            .renderingMode(.template)
                            .foregroundColor(color)
                    case .loading:
                        ActivityIndicator()
                    case .regular:
                        EmptyView()
                    }

                    if let title {
                        Text(title)
                            .font(style?.titleFont ?? .headline.bold())
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(style?.subTitleFont ?? .subheadline)
                }
            }
            .multilineTextAlignment(.leading)
            .textColor(style?.titleColor ?? nil)
            .padding()
            .frame(maxWidth: 400, alignment: .leading)
            .alertBackground(style?.backgroundColor ?? nil)
            .cornerRadius(10)
            .padding([.horizontal, .bottom])
        }
        #if os(visionOS)
        .frame(depth: 100)
        #endif
    }

    /// HUD View
    public var hud: some View {
        Group {
            HStack(spacing: 16) {
                switch type {
                case .complete(let color):
                    Image(systemName: "checkmark")
                        .hudModifier()
                        .foregroundColor(color)
                case .error(let color):
                    Image(systemName: "xmark")
                        .hudModifier()
                        .foregroundColor(color)
                case .systemImage(let name, let color):
                    Image(systemName: name)
                        .hudModifier()
                        .foregroundColor(color)
                case .image(let name, let color):
                    Image(name)
                        .hudModifier()
                        .foregroundColor(color)
                case .loading:
                    ActivityIndicator()
                case .regular:
                    EmptyView()
                }

                if title != nil || subtitle != nil {
                    VStack(alignment: type == .regular ? .center : .leading, spacing: 2) {
                        if let title {
                            Text(title)
                                .font(style?.titleFont ?? Font.body.bold())
                                .multilineTextAlignment(.center)
                                .textColor(style?.titleColor ?? nil)
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(style?.subTitleFont ?? Font.footnote)
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                                .textColor(style?.subtitleColor ?? nil)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .alertBackground(style?.backgroundColor ?? nil)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
            .compositingGroup()
        }
        .padding(.top)
        #if os(visionOS)
        .frame(depth: 100)
        #endif
    }

    /// Alert View
    public var alert: some View {
        VStack {
            switch type {
            case .complete(let color):
                Spacer()
                AnimatedCheckmark(color: color)
                Spacer()
            case .error(let color):
                Spacer()
                AnimatedXmark(color: color)
                Spacer()
            case .systemImage(let name, let color):
                Spacer()
                Image(systemName: name)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case .image(let name, let color):
                Spacer()
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case .loading:
                ActivityIndicator()
            case .regular:
                EmptyView()
            }

            VStack(spacing: type == .regular ? 8 : 2) {
                if let title {
                    Text(title)
                        .font(style?.titleFont ?? Font.body.bold())
                        .multilineTextAlignment(.center)
                        .textColor(style?.titleColor ?? nil)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(style?.subTitleFont ?? Font.footnote)
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                        .textColor(style?.subtitleColor ?? nil)
                }
            }
        }
        .padding()
        .withFrame(type != .regular && type != .loading)
        .alertBackground(style?.backgroundColor ?? nil)
        .cornerRadius(10)
        #if os(visionOS)
        .frame(depth: 100)
        #endif
    }

    /// Body init determine by `displayMode`
    public var body: some View {
        switch displayMode {
        case .alert:
            alert
        case .hud:
            hud
        case .banner:
            banner
        }
    }
}
