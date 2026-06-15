//
//  MimoMap.swift
//  MimoBike
//
//  2GIS SDK bootstrap. Replaces the Google Maps `GMSServices` entry point.
//
//  This is the single owner of the `DGis.Container` (the SDK requires exactly one
//  instance for the whole application lifetime). It also exposes the shared
//  `IImageFactory`, the SDK `Context`, and a map-factory builder used by `MimoMapView`.
//
//  NOTE: The map will only render real tiles once a valid 2GIS access key (bound to
//  this app's bundle id) is set in `Constant.APIKeys.TWO_GIS_API_KEY`.
//

import UIKit
import DGis

final class MimoMap {

    static let shared = MimoMap()

    /// The one and only SDK container.
    let sdk: DGis.Container

    /// Lazily resolved SDK services (all `throws` on the SDK side).
    private(set) lazy var imageFactory: IImageFactory? = try? self.sdk.imageFactory
    private(set) lazy var context: Context? = try? self.sdk.context

    private init() {
        // The 2GIS SDK key is a generated *file* (`dgissdk.key`) that embeds both
        // the key and the bound `app_id` — a bare key string is rejected with
        // "File with key info is invalid". Preferred setup: download `dgissdk.key`
        // from dev.2gis.com (specifying this app's bundle id as App ID) and add it
        // to the app target. `.default` reads it from the bundle root.
        // Fallback: if no file is bundled, treat `TWO_GIS_API_KEY` as the full
        // *contents* of that key file (not just the UUID).
        let keySource: KeySource
        if Bundle.main.url(forResource: "dgissdk", withExtension: "key") != nil {
            keySource = .default
        } else {
            keySource = .fromString(KeyFromString(contents: Constant.APIKeys.TWO_GIS_API_KEY))
        }
        self.sdk = DGis.Container(keySource: keySource)
    }

    /// Touch the singleton so the container initialises at launch.
    /// Called from `AppDelegate.didFinishLaunchingWithOptions`.
    func start() {
        _ = self.sdk
    }

    /// Builds a fresh map factory (one per `MimoMapView`).
    func makeMapFactory() -> IMapFactory? {
        var options = MapOptions.default
        options.devicePPI = .autodetected
        return try? self.sdk.makeMapFactory(options: options)
    }

    /// Builds a "my location" source for a map.
    func makeMyLocationSource() -> MyLocationMapObjectSource? {
        guard let context = self.context else { return nil }
        return MyLocationMapObjectSource(
            context: context,
            controllerSettings: MyLocationControllerSettings(bearingSource: .magnetic),
            markerType: .model
        )
    }
}
