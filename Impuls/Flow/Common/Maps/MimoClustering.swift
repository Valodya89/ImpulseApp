//
//  MimoClustering.swift
//  MimoBike
//
//  Replacements for the Google Maps Utils clustering stack
//  (`GMUClusterManager`, `GMUClusterIconGenerator`, `GMUDefaultClusterRenderer`,
//  `GMUNonHierarchicalDistanceBasedAlgorithm`, `GMUCluster`) backed by 2GIS'
//  native clustering (`MapObjectManager.withClustering`).
//

import UIKit
import DGis

/// Replacement for `GMUClusterIconGenerator`. The app's existing icon generators
/// (`MimoClusterIconGenerator`/`EVClusterIconGenerator` types) adopt this.
protocol MimoClusterIconGenerating: AnyObject {
    func icon(forSize size: UInt) -> UIImage!
}

/// Replacement for `GMUNonHierarchicalDistanceBasedAlgorithm`. The distance is
/// forwarded to 2GIS' `logicalPixel` grouping radius.
final class MimoNonHierarchicalDistanceBasedAlgorithm {
    let clusterDistancePoints: Float
    init(clusterDistancePoints: UInt) { self.clusterDistancePoints = Float(clusterDistancePoints) }
    init() { self.clusterDistancePoints = 100 }
}

/// Replacement for `GMUDefaultClusterRenderer` — a thin configuration holder.
final class MimoDefaultClusterRenderer {
    let mapView: MimoMapView
    let iconGenerator: MimoClusterIconGenerating
    var minimumClusterSize: Int = 1
    var maximumClusterZoom: Int = 16
    var animatesClusters: Bool = true

    init(mapView: MimoMapView, clusterIconGenerator: MimoClusterIconGenerating) {
        self.mapView = mapView
        self.iconGenerator = clusterIconGenerator
    }
}

/// Replacement for `GMUClusterManager`.
final class MimoClusterManager {
    private let mapView: MimoMapView
    private let algorithm: MimoNonHierarchicalDistanceBasedAlgorithm
    private let renderer: MimoDefaultClusterRenderer
    private var clusterObjectManager: MapObjectManager?
    private var pendingMarkers: [MimoMarker] = []

    init(map: MimoMapView,
         algorithm: MimoNonHierarchicalDistanceBasedAlgorithm,
         renderer: MimoDefaultClusterRenderer) {
        self.mapView = map
        self.algorithm = algorithm
        self.renderer = renderer
        if let dgisMap = map.dgisMap {
            self.clusterObjectManager = MapObjectManager.withClustering(
                map: dgisMap,
                logicalPixel: LogicalPixel(value: algorithm.clusterDistancePoints),
                maxZoom: Zoom(value: Float(renderer.maximumClusterZoom)),
                clusterRenderer: MimoSimpleClusterRenderer(
                    iconGenerator: renderer.iconGenerator,
                    imageFactory: MimoMap.shared.imageFactory
                ),
                minZoom: Zoom(value: 0)
            )
        }
    }

    /// `GMUClusterManager.setMapDelegate(_:)` — routes map events to the delegate.
    func setMapDelegate(_ delegate: MimoMapViewDelegate) {
        mapView.delegate = delegate
    }

    /// `GMUClusterManager.add(_:)`
    func add(_ marker: MimoMarker) {
        pendingMarkers.append(marker)
    }

    /// `GMUClusterManager.cluster()`
    func cluster() {
        let objects = pendingMarkers.compactMap { $0.makeDgisMarker() }
        guard !objects.isEmpty else { return }
        clusterObjectManager?.addObjects(objects: objects)
    }

    /// `GMUClusterManager.clearItems()`
    func clearItems() {
        clusterObjectManager?.removeAll()
        pendingMarkers.removeAll()
    }
}

// MARK: - 2GIS cluster renderer

private final class MimoSimpleClusterRenderer: SimpleClusterRenderer {
    private let iconGenerator: MimoClusterIconGenerating
    private let imageFactory: IImageFactory?

    init(iconGenerator: MimoClusterIconGenerating, imageFactory: IImageFactory?) {
        self.iconGenerator = iconGenerator
        self.imageFactory = imageFactory
    }

    func renderCluster(cluster: SimpleClusterObject) -> SimpleClusterOptions {
        let count = cluster.objectCount
        let uiImage = iconGenerator.icon(forSize: UInt(count)) ?? UIImage()
        let icon = imageFactory?.make(image: uiImage)
        return SimpleClusterOptions(
            icon: icon,
            iconWidth: LogicalPixel(value: Float(max(uiImage.size.width, 1))),
            zIndex: ZIndex(value: 5)
        )
    }
}
