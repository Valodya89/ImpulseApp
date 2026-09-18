//
//  HomeServiceHeroCardViewModel.swift
//  Impuls
//
//  State for one product's hero card on the home screen. It is fed what the
//  home view model already loads (rider location, the nearest-vehicles list)
//  and turns it into the card's summary line plus a rendered picture of that
//  product's network; nothing is fetched twice.
//

import Foundation
import Combine
import CoreLocation
import UIKit

final class HomeServiceHeroCardViewModel: ObservableObject {

    struct Site {
        let coordinate: CLLocationCoordinate2D
        /// Units for rent here: 1 for a vehicle, banks in a cabinet, free plugs on a station.
        let available: Int
    }

    enum Summary: Equatable {
        case locationOff
        case loading
        case empty
        case sites(count: Int, available: Int, nearest: String)
    }

    let style: HomeServiceHeroStyle

    @Published private(set) var mapImage: UIImage?
    @Published private(set) var summary: Summary = .loading

    private let renderer = HomeMapSnapshotRenderer()

    private var location: CLLocationCoordinate2D?
    private var isLocationAuthorized = false
    private var sites: [Site] = []
    private var hasLoadedSites = false
    private var mapSize: CGSize = .zero
    private var isDark = ThemeManager.shared.isDarkModeActive

    private var lastRequest: HomeMapSnapshotRenderer.Request?
    private var renderTask: Task<Void, Never>?

    init(style: HomeServiceHeroStyle) {
        self.style = style
    }

    deinit {
        renderTask?.cancel()
        renderer.cancel()
    }

    func update(location: CLLocationCoordinate2D?, isLocationAuthorized: Bool) {
        self.location = location
        self.isLocationAuthorized = isLocationAuthorized
        refresh()
    }

    /// Nearest-first, the order the home view model already sorts them in.
    func update(sites: [Site]) {
        self.sites = sites
        hasLoadedSites = true
        refresh()
    }

    /// The card reports its size once laid out; the picture is rendered at
    /// exactly that size so it never scales.
    func updateMapSize(_ size: CGSize) {
        let rounded = CGSize(width: size.width.rounded(), height: size.height.rounded())
        guard rounded != mapSize else { return }
        mapSize = rounded
        refresh()
    }

    /// The card reports the appearance it is drawn in; the map tiles follow it.
    func updateAppearance(isDark: Bool) {
        guard isDark != self.isDark else { return }
        self.isDark = isDark
        refresh()
    }

    // MARK: - Private

    private func refresh() {
        summary = makeSummary()
        requestSnapshotIfNeeded()
    }

    private func makeSummary() -> Summary {
        guard isLocationAuthorized else { return .locationOff }
        guard hasLoadedSites else { return .loading }
        guard let nearest = sites.first else { return .empty }

        let available = sites.reduce(0) { $0 + $1.available }
        let nearestText: String
        if let location {
            nearestText = location.clLocation.distance(from: nearest.coordinate.clLocation).prettyDistance
        } else {
            nearestText = "-"
        }
        return .sites(count: sites.count, available: available, nearest: nearestText)
    }

    private func requestSnapshotIfNeeded() {
        // Every site goes in the picture; without any (and no rider either)
        // there is nothing to frame, so the gradient stays.
        guard mapSize.width > 0, mapSize.height > 0,
              !sites.isEmpty || location != nil else { return }

        let request = HomeMapSnapshotRenderer.Request(
            rider: location,
            points: sites.map(\.coordinate),
            markerImageName: style.markerImageName,
            markerOverlayImageName: style.markerOverlayImageName,
            size: mapSize,
            isDark: isDark
        )
        guard request != lastRequest else { return }
        lastRequest = request

        renderTask?.cancel()
        renderTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let image = await self.renderer.render(request)
            guard !Task.isCancelled, let image else { return }
            self.mapImage = image
        }
    }
}
