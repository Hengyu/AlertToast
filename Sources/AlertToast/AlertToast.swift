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

// MARK: AlertToast

public struct AlertToast: View {

    public enum AlertShape: Equatable, Hashable, Sendable {
        case pill
        case square
        case banner
    }

    /// Customize Alert Appearance
    public struct AlertStyle: Sendable {
        public let alertShape: AlertShape
        public let titleStyle: AnyShapeStyle
        public let titleFont: Font
        public let subtitleStyle: AnyShapeStyle
        public let subtitleFont: Font
        public let background: AnyShapeStyle?

        public init(
            alertShape: AlertShape,
            titleStyle: any ShapeStyle = .primary,
            titleFont: Font = .headline,
            subtitleStyle: any ShapeStyle = .secondary,
            subtitleFont: Font = .subheadline,
            background: (any ShapeStyle)? = nil
        ) {
            self.alertShape = alertShape
            self.titleStyle = .init(titleStyle)
            self.titleFont = titleFont
            self.subtitleStyle = .init(subtitleStyle)
            self.subtitleFont = subtitleFont
            self.background = background.map { AnyShapeStyle($0) }
        }
    }

    /// Determine what the alert will display
    public enum AlertType: Equatable, Hashable, Sendable {

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

    public struct AlertInfo: Hashable, Sendable {
        let type: AlertType
        let title: String?
        let subtitle: String?

        public init(type: AlertType, title: String? = nil, subtitle: String? = nil) {
            self.type = type
            self.title = title
            self.subtitle = subtitle
        }
    }

    /// What the alert would show
    /// `complete`, `error`, `systemImage`, `image`, `loading`, `regular`
    internal let type: AlertType

    /// The title of the alert.
    private let title: (any StringProtocol)?

    /// The subtitle of the alert.
    private let subtitle: (any StringProtocol)?

    /// Customize your alert appearance
    private let style: AlertStyle

    public init(info: AlertInfo, style: AlertStyle) {
        self.type = info.type
        self.title = info.title
        self.subtitle = info.subtitle
        self.style = style
    }

    public init(
        type: AlertType,
        title: (any StringProtocol)? = nil,
        subtitle: (any StringProtocol)? = nil,
        style: AlertStyle
    ) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }

    public init(type: AlertType, title: String? = nil, shape: AlertShape) {
        self.type = type
        self.title = title
        self.subtitle = nil
        self.style = .init(alertShape: shape)
    }

    public var body: some View {
        switch style.alertShape {
        case .pill: hud
        case .square: alert
        case .banner: banner
        }
    }

    private var banner: some View {
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
        .frame(maxWidth: Platform.isTV ? 480 : 400, alignment: .leading)
        .alertBackground(style.background)
        .clipShape(RoundedRectangle(cornerRadius: Platform.isTV ? 16 : 12))
        #if os(visionOS)
        .frame(depth: 100)
        #endif
    }

    private var hud: some View {
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
        .alertBackground(style.background)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
        .compositingGroup()
        #if os(visionOS)
        .frame(depth: 100)
        #endif
    }

    private var alert: some View {
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
        .alertBackground(style.background)
        .clipShape(RoundedRectangle(cornerRadius: Platform.isTV ? 16 : 12))
        #if os(visionOS)
        .frame(depth: 100)
        #endif
    }
}

enum Platform {
    static let isTV: Bool = {
        #if os(tvOS)
        true
        #else
        false
        #endif
    }()
}

// MARK: AlertType

extension AlertToast.AlertType {
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
