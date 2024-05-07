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

        var titleSubtitlePadding: CGFloat {
            switch self {
            case .complete, .error, .systemImage, .image, .loading:
                #if os(tvOS)
                4
                #else
                2
                #endif
            case .regular:
                #if os(tvOS)
                12
                #else
                8
                #endif
            }
        }
    }

    /// Customize Alert Appearance
    public struct AlertStyle: Sendable {
        public let titleStyle: AnyShapeStyle
        public let titleFont: Font
        public let subtitleStyle: AnyShapeStyle
        public let subtitleFont: Font
        public let backgroundColor: Color?

        public init(
            titleStyle: any ShapeStyle = .primary,
            titleFont: Font = .headline,
            subtitleStyle: any ShapeStyle = .secondary,
            subtitleFont: Font = .subheadline,
            backgroundColor: Color? = nil
        ) {
            self.titleStyle = .init(titleStyle)
            self.titleFont = titleFont
            self.subtitleStyle = .init(subtitleStyle)
            self.subtitleFont = subtitleFont
            self.backgroundColor = backgroundColor
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
    private let style: AlertStyle

    /// Full init
    public init(
        displayMode: DisplayMode = .alert,
        type: AlertType,
        title: String? = nil,
        subtitle: String? = nil,
        style: AlertStyle = .init()
    ) {
        self.displayMode = displayMode
        self.type = type
        self.title = title.flatMap { LocalizedStringKey($0) }
        self.subtitle = subtitle.flatMap { LocalizedStringKey($0) }
        self.style = style
    }

    public init(
        displayMode: DisplayMode = .alert,
        type: AlertType,
        title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        style: AlertStyle = .init()
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
        self.style = .init()
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
                            .foregroundStyle(color)
                    case .error(let color):
                        Image(systemName: "xmark")
                            .foregroundStyle(color)
                    case .systemImage(let name, let color):
                        Image(systemName: name)
                            .foregroundStyle(color)
                    case .image(let name, let color):
                        Image(name)
                            .renderingMode(.template)
                            .foregroundStyle(color)
                    case .loading:
                        ProgressView()
                            #if os(iOS) || os(macOS) || os(visionOS)
                            .controlSize(.large)
                            #endif
                            .progressViewStyle(.circular)
                    case .regular:
                        EmptyView()
                    }

                    if let title {
                        Text(title)
                            .font(style.titleFont)
                            .foregroundStyle(style.titleStyle)
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(style.subtitleFont)
                        .foregroundStyle(style.subtitleStyle)
                }
            }
            .multilineTextAlignment(.leading)
            .padding()
            #if os(tvOS)
            .frame(maxWidth: 480, alignment: .leading)
            .alertBackground(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            #else
            .frame(maxWidth: 400, alignment: .leading)
            .alertBackground(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            #endif
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
                        .foregroundStyle(color)
                case .error(let color):
                    Image(systemName: "xmark")
                        .hudModifier()
                        .foregroundStyle(color)
                case .systemImage(let name, let color):
                    Image(systemName: name)
                        .hudModifier()
                        .foregroundStyle(color)
                case .image(let name, let color):
                    Image(name)
                        .hudModifier()
                        .foregroundStyle(color)
                case .loading:
                    ProgressView()
                        #if os(iOS) || os(macOS) || os(visionOS)
                        .controlSize(.large)
                        #endif
                        .progressViewStyle(.circular)
                case .regular:
                    EmptyView()
                }

                if title != nil || subtitle != nil {
                    VStack(alignment: type == .regular ? .center : .leading, spacing: type.titleSubtitlePadding) {
                        if let title {
                            Text(title)
                                .font(style.titleFont)
                                .foregroundStyle(style.titleStyle)
                                .multilineTextAlignment(.center)
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(style.subtitleFont)
                                .foregroundStyle(style.subtitleStyle)
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .alertBackground(style.backgroundColor)
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
                    .foregroundStyle(color)
                    .padding(.bottom)
                Spacer()
            case .image(let name, let color):
                Spacer()
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .foregroundStyle(color)
                    .padding(.bottom)
                Spacer()
            case .loading:
                ProgressView()
                    #if os(iOS) || os(macOS) || os(visionOS)
                    .controlSize(.large)
                    #endif
                    .progressViewStyle(.circular)
            case .regular:
                EmptyView()
            }

            VStack(spacing: type.titleSubtitlePadding) {
                if let title {
                    Text(title)
                        .font(style.titleFont)
                        .foregroundStyle(style.titleStyle)
                        .multilineTextAlignment(.center)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(style.subtitleFont)
                        .foregroundStyle(style.subtitleStyle)
                        .opacity(0.85)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .withFrame(type != .regular && type != .loading)
        .alertBackground(style.backgroundColor)
        #if os(tvOS)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        #else
        .clipShape(RoundedRectangle(cornerRadius: 12))
        #endif
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
