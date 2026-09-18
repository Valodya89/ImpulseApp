//
//  HomeMapSnapshotRenderer.swift
//  Impuls
//
//  Renders the static map picture behind a home service card: the product's
//  whole network drawn with its own pin, plus the rider's position when they
//  are inside that area. A picture instead of a live map keeps the home screen
//  cheap (no Google map instance idling per card under the sheet); the real
//  map opens on tap.
//

import UIKit
import MapKit
import CoreLocation

final class HomeMapSnapshotRenderer {

    struct Request: Equatable {
        /// Where the rider is, if known. Drawn only when it falls inside the
        /// framed network; a rider abroad must not zoom the picture out to nothing.
        let rider: CLLocationCoordinate2D?
        /// Every site, nearest-first.
        let points: [CLLocationCoordinate2D]
        let markerImageName: String
        let markerOverlayImageName: String?
        let size: CGSize
        /// Dark tiles for the dark appearance; part of the key so a theme
        /// switch re-renders the picture.
        var isDark: Bool = false

        static func == (lhs: Request, rhs: Request) -> Bool {
            lhs.size == rhs.size
                && lhs.isDark == rhs.isDark
                && lhs.markerImageName == rhs.markerImageName
                && lhs.markerOverlayImageName == rhs.markerOverlayImageName
                && lhs.rider?.latitude == rhs.rider?.latitude
                && lhs.rider?.longitude == rhs.rider?.longitude
                && lhs.points.count == rhs.points.count
                && zip(lhs.points, rhs.points).allSatisfy {
                    $0.latitude == $1.latitude && $0.longitude == $1.longitude
                }
        }
    }

    /// Smallest area shown even when every site sits on one street, so the
    /// picture still reads as a neighbourhood.
    private let minimumSpan: CLLocationDegrees = 0.008
    /// How far outside the network's box the rider may be and still be framed,
    /// as a fraction of that box.
    private let riderSlack: Double = 0.5

    private var snapshotter: MKMapSnapshotter?

    func render(_ request: Request) async -> UIImage? {
        guard request.size.width > 0, request.size.height > 0 else { return nil }

        snapshotter?.cancel()

        let options = MKMapSnapshotter.Options()
        options.region = region(for: request)
        options.size = request.size
        options.scale = UIScreen.main.scale
        options.mapType = .mutedStandard
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll
        // Tiles follow the appearance the card is currently drawn in.
        options.traitCollection = UITraitCollection(userInterfaceStyle: request.isDark ? .dark : .light)

        let snapshotter = MKMapSnapshotter(options: options)
        self.snapshotter = snapshotter

        let snapshot: MKMapSnapshotter.Snapshot
        do {
            snapshot = try await snapshotter.start()
        } catch {
            return nil
        }
        if Task.isCancelled { return nil }

        return draw(snapshot, request: request)
    }

    func cancel() {
        snapshotter?.cancel()
        snapshotter = nil
    }

    // MARK: - Private

    /// The rider is framed when they are in or near the network.
    private func riderIsFramed(_ request: Request) -> Bool {
        guard let rider = request.rider else { return false }
        guard let box = boundingBox(request.points) else { return true }
        let latSlack = max(box.maxLat - box.minLat, minimumSpan) * riderSlack
        let lonSlack = max(box.maxLon - box.minLon, minimumSpan) * riderSlack
        return rider.latitude >= box.minLat - latSlack && rider.latitude <= box.maxLat + latSlack
            && rider.longitude >= box.minLon - lonSlack && rider.longitude <= box.maxLon + lonSlack
    }

    private func boundingBox(_ points: [CLLocationCoordinate2D]) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)? {
        guard let first = points.first else { return nil }
        var box = (minLat: first.latitude, maxLat: first.latitude, minLon: first.longitude, maxLon: first.longitude)
        for point in points.dropFirst() {
            box.minLat = min(box.minLat, point.latitude)
            box.maxLat = max(box.maxLat, point.latitude)
            box.minLon = min(box.minLon, point.longitude)
            box.maxLon = max(box.maxLon, point.longitude)
        }
        return box
    }

    private func region(for request: Request) -> MKCoordinateRegion {
        var points = request.points
        if let rider = request.rider, riderIsFramed(request) {
            points.append(rider)
        }

        guard let box = boundingBox(points) else {
            let fallback = request.rider ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return MKCoordinateRegion(center: fallback,
                                      span: MKCoordinateSpan(latitudeDelta: minimumSpan, longitudeDelta: minimumSpan))
        }
        let (minLat, maxLat, minLon, maxLon) = box

        // Pad so edge pins do not touch the border (the pin sits above its
        // point, so the top needs a little more) and keep the span sane.
        let aspect = Double(request.size.width / max(request.size.height, 1))
        var latDelta = min(max((maxLat - minLat) * 1.5, minimumSpan), 120)
        var lonDelta = min(max((maxLon - minLon) * 1.4, minimumSpan * aspect), 300)
        // Match the picture's aspect so MapKit does not pick a wider region than asked.
        let cosLat = max(cos((minLat + maxLat) / 2 * .pi / 180), 0.01)
        if lonDelta * cosLat < latDelta * aspect {
            lonDelta = latDelta * aspect / cosLat
        } else {
            latDelta = lonDelta * cosLat / aspect
        }

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2 + latDelta * 0.05,
                                            longitude: (minLon + maxLon) / 2)
        return MKCoordinateRegion(center: center,
                                  span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }

    /// A dense network gets smaller pins so the picture stays a map, not a pile.
    /// The width follows the asset so no pin is squashed.
    private func markerSize(for image: UIImage?, siteCount: Int) -> CGSize {
        let height: CGFloat
        switch siteCount {
        case ..<10:  height = 28
        case ..<30:  height = 21
        default:     height = 16
        }
        guard let image, image.size.height > 0 else { return CGSize(width: height * 0.8, height: height) }
        return CGSize(width: height * image.size.width / image.size.height, height: height)
    }

    private func draw(_ snapshot: MKMapSnapshotter.Snapshot, request: Request) -> UIImage {
        let bounds = CGRect(origin: .zero, size: request.size)
        let marker = UIImage(named: request.markerImageName)
        let overlay = request.markerOverlayImageName.flatMap { UIImage(named: $0) }
        let markerSize = markerSize(for: marker, siteCount: request.points.count)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: request.size, format: format)

        return renderer.image { context in
            snapshot.image.draw(in: bounds)

            // Farthest first so the nearest sites end up on top of any overlap.
            for coordinate in request.points.reversed() {
                let point = snapshot.point(for: coordinate)
                guard bounds.insetBy(dx: -markerSize.width, dy: -markerSize.height).contains(point) else { continue }
                let rect = CGRect(x: point.x - markerSize.width / 2,
                                  y: point.y - markerSize.height,
                                  width: markerSize.width,
                                  height: markerSize.height)
                marker?.draw(in: rect)
                // The power-bank pin is a blank white drop the map composes its
                // yellow head over (`ChargerSelectedMarkerView` proportions). At
                // pin size the drop's soft shadow vanishes on light tiles, so a
                // crisp white disc is drawn under the head to keep it legible.
                if let overlay {
                    let headCenter = CGPoint(x: rect.midX, y: rect.minY + markerSize.height * 0.38)
                    let ring = markerSize.width * 0.8
                    let side = markerSize.width * 0.58
                    let cg = context.cgContext
                    cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.25).cgColor)
                    cg.setFillColor(UIColor.alwaysWhite.cgColor) // stays white: pin over the map, like the live marker
                    cg.fillEllipse(in: CGRect(x: headCenter.x - ring / 2, y: headCenter.y - ring / 2, width: ring, height: ring))
                    cg.setShadow(offset: .zero, blur: 0, color: nil)
                    overlay.draw(in: CGRect(x: headCenter.x - side / 2, y: headCenter.y - side / 2, width: side, height: side))
                }
            }

            // The rider: a blue dot with a soft halo, like the live map's puck.
            guard let rider = request.rider, riderIsFramed(request) else { return }
            let me = snapshot.point(for: rider)
            guard bounds.contains(me) else { return }
            let blue = UIColor.systemBlue
            let cg = context.cgContext

            cg.setFillColor(blue.withAlphaComponent(0.18).cgColor)
            cg.fillEllipse(in: CGRect(x: me.x - 16, y: me.y - 16, width: 32, height: 32))

            cg.setFillColor(UIColor.alwaysWhite.cgColor) // stays white: puck ring over the map, like the live one
            cg.fillEllipse(in: CGRect(x: me.x - 8, y: me.y - 8, width: 16, height: 16))

            cg.setFillColor(blue.cgColor)
            cg.fillEllipse(in: CGRect(x: me.x - 6, y: me.y - 6, width: 12, height: 12))
        }
    }
}
