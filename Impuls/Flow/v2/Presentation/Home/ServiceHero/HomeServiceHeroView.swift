//
//  HomeServiceHeroView.swift
//  Impuls
//
//  One service on the home screen, shown as a hero card: a map picture of the
//  product's whole network, a one-line summary and an "Open map" pill. The
//  whole card is the button that opens the product; a long press offers to
//  take it off the home screen. The same file holds the "add product" card
//  and the skeleton that stands in until the services are known.
//

import SwiftUI

struct HomeServiceHeroView: View {

    @ObservedObject var viewModel: HomeServiceHeroCardViewModel
    let onOpen: () -> Void
    /// Offered on long press; nil while this is the only service left.
    let onRemove: (() -> Void)?

    private let cornerRadius: CGFloat = 16
    @Environment(\.colorScheme) private var colorScheme

    private var style: HomeServiceHeroStyle { viewModel.style }

    var body: some View {
        removable(
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onOpen()
            } label: {
                ZStack(alignment: .bottomLeading) {
                    background
                    scrim
                    topRow
                    bottomRow
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .buttonStyle(HeroPressStyle())
        )
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
        .accessibilityLabel(Text(style.title))
        .accessibilityHint(Text(openMapTitle))
    }

    // MARK: - Layers

    private var background: some View {
        GeometryReader { geometry in
            ZStack {
                fallbackGradient

                if style.iconIsTemplate {
                    Image(style.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.alwaysWhite.opacity(0.14))
                        .frame(width: geometry.size.height * 0.9)
                        .rotationEffect(.degrees(-12))
                        .offset(x: geometry.size.width * 0.28, y: -geometry.size.height * 0.12)
                }

                if let image = viewModel.mapImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .animation(.easeInOut(duration: 0.3), value: viewModel.mapImage == nil)
            .onAppear {
                viewModel.updateAppearance(isDark: colorScheme == .dark)
                viewModel.updateMapSize(geometry.size)
            }
            .onChange(of: geometry.size) { viewModel.updateMapSize($0) }
            .onChange(of: colorScheme) { viewModel.updateAppearance(isDark: $0 == .dark) }
        }
    }

    /// What shows until the map picture lands (and stays if there is nothing to frame).
    @ViewBuilder
    private var fallbackGradient: some View {
        switch style.accent {
        case .yellow:
            // Fixed dark surface (gray9 -> gray8 in light): the white text and
            // watermark above must keep reading in dark mode too.
            ZStack {
                Color.onBrandLabel
                LinearGradient(colors: [.clear, Color.alwaysWhite.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        case .evGradient:
            LinearGradient.evBrandGradientHorizontal
        }
    }

    /// Darkens the bottom so white text reads on any map tile; a thin band at
    /// the top does the same for the chips. Everything drawn on top of this
    /// card stays white on purpose: it sits over the map picture / gradient.
    private var scrim: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Color.alwaysBlack.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 64)
            Spacer(minLength: 0)
            LinearGradient(colors: [.clear, Color.alwaysBlack.opacity(0.78)], startPoint: .top, endPoint: .bottom)
                .frame(height: 120)
        }
    }

    private var topRow: some View {
        VStack {
            HStack(alignment: .center, spacing: 8) {
                chip {
                    productIcon
                    Text(style.title)
                }

                Spacer(minLength: 8)

                if style.showsAvailabilityChip,
                   case .sites(_, let available, _) = viewModel.summary, available > 0 {
                    chip {
                        Circle()
                            .fill(Color.successGreen)
                            .frame(width: 7, height: 7)
                        Text("\(available) \("MOBILE_home_hero_available".localized(fallback: "available"))")
                    }
                }
            }
            .padding(12)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var productIcon: some View {
        if style.iconIsTemplate {
            Image(style.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)
                .foregroundColor(style.iconTint)
        } else {
            Image(style.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(style.headline)
                    .font(.robotoBold20)
                    .foregroundColor(.alwaysWhite)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.robotoRegular14)
                    .foregroundColor(Color.alwaysWhite.opacity(0.88))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            openMapPill
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private var openMapPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "map.fill")
                .font(.system(size: 13, weight: .semibold))
            Text(openMapTitle)
                .font(.robotoBold14)
                .lineLimit(1)
        }
        .foregroundColor(pillForeground)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(pillBackground)
        .clipShape(Capsule())
        .layoutPriority(1)
    }

    // MARK: - Pieces

    private var openMapTitle: String {
        "MOBILE_home_hero_open_map".localized(fallback: "Open map")
    }

    private var subtitle: String {
        switch viewModel.summary {
        case .locationOff:
            return "MOBILE_home_hero_location_off".localized(fallback: "Turn on location to see what's near you")
        case .loading:
            return "MOBILE_home_hero_loading".localized(fallback: "Looking around you…")
        case .empty:
            return "MOBILE_home_hero_empty".localized(fallback: "Nothing nearby yet")
        case .sites(let count, _, let nearest):
            let sites = "\(count) \(style.unit)"
            let nearestText = "\("MOBILE_home_hero_nearest".localized(fallback: "nearest")) \(nearest)"
            return "\(sites) · \(nearestText)"
        }
    }

    private var pillForeground: Color {
        switch style.accent {
        case .yellow: return .onBrandLabel
        case .evGradient: return .alwaysWhite
        }
    }

    @ViewBuilder
    private var pillBackground: some View {
        switch style.accent {
        case .yellow: Color.brandYellow
        case .evGradient: LinearGradient.evBrandGradientHorizontal
        }
    }

    private func chip<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) {
            content()
        }
        .font(.robotoMedium13)
        .foregroundColor(.alwaysWhite)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.alwaysBlack.opacity(0.45))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func removable<Content: View>(_ content: Content) -> some View {
        if let onRemove {
            content.contextMenu {
                Button(role: .destructive, action: onRemove) {
                    Label("MOBILE_home_hero_remove_product".localized(fallback: "Remove from home"),
                          systemImage: "minus.circle")
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Add product

/// The last card of the row while the rider has not picked every product the
/// market offers; opens the product selection screen.
struct HomeAddProductCardView: View {

    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brandYellow)
                        .frame(width: 52, height: 52)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color.onBrandLabel)
                }

                VStack(spacing: 4) {
                    Text("CHARGER_add_product".localized(fallback: "Add product"))
                        .font(.robotoBold16)
                        .foregroundColor(Color.gray9)
                        .lineLimit(1)
                    Text("MOBILE_home_hero_add_product_subtitle".localized(fallback: "Pick more services for your home screen"))
                        .font(.robotoRegular14)
                        .foregroundColor(Color.gray8)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundColor(Color.gray5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(HeroPressStyle())
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .accessibilityLabel(Text("CHARGER_add_product".localized(fallback: "Add product")))
    }
}

// MARK: - Skeleton

/// Stands in for the cards until the available services are known.
struct HomeServiceLoadingCardView: View {

    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray4)

            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(Color.gray5).frame(width: 150, height: 18)
                Capsule().fill(Color.gray5).frame(width: 210, height: 12)
            }
            .padding(16)
        }
        .opacity(pulse ? 0.55 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Press style

/// Presses the card down a touch instead of dimming it, so the map stays legible.
private struct HeroPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
