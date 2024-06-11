//
//  SearchViewController.swift
//  MapBoxNav
//
//  Created by Robbie Elliott on 2024-06-05.
//

import MapboxMaps
import MapboxSearch
import MapboxSearchUI
import MapKit
import UIKit

class SearchViewController: MapsViewController {

    lazy var searchController: MapboxSearchController = {

        let latitude = CLLocationManager().location?.coordinate.latitude
        let longitude = CLLocationManager().location?.coordinate.longitude
        let location = CLLocationCoordinate2D(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0)

        let locationProvider = PointLocationProvider(coordinate: location)
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        var configuration = Configuration(
            locationProvider: locationProvider,
            distanceFormatter: formatter
        )

        return MapboxSearchController(configuration: configuration)
    }()

    lazy var panelController = MapboxPanelController(rootViewController: searchController)

    override func viewDidLoad() {
        super.viewDidLoad()

        let cameraOptions = CameraOptions(center: .sanFrancisco, zoom: 15)
        mapView.camera.fly(to: cameraOptions, duration: 1, completion: nil)

        let horizontalMargin: CGFloat = 4
        mapView.ornaments.options.logo = LogoViewOptions(
            position: .topLeading,
            margins: CGPoint(x: horizontalMargin, y: 0)
        )


        mapView.ornaments.options.attributionButton = AttributionButtonOptions(
            position: .topLeading,
            margins: CGPoint(x: 0, y: 4)
        )

        let scalarX = mapView.ornaments.logoView.bounds.maxX + 12
        mapView.ornaments.options.scaleBar = ScaleBarViewOptions(
            position: .topLeading,
            margins: CGPoint(x: scalarX, y: 0),
            visibility: .hidden,
            useMetricUnits: false
        )

        searchController.delegate = self
        addChild(panelController)
    }
}

extension SearchViewController: SearchControllerDelegate {
    func categorySearchResultsReceived(category: SearchCategory, results: [SearchResult]) {
        showAnnotations(results: results)
    }

    func searchResultSelected(_ searchResult: SearchResult) {
        showAnnotation(searchResult)
    }

    func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
        showAnnotation(userFavorite)
    }
}

