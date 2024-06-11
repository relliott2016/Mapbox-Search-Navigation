//
//  MapsViewController.swift
//  MapBoxNav
//
//  Created by Robbie Elliott on 2024-06-05.
//

import MapboxMaps
import MapboxSearchUI
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapKit

class NavViewController: UIViewController {
    let mapView = MapView(frame: .zero)
    let mapStyle: MapboxMaps.StyleURI = .satelliteStreets
    let locationManager = CLLocationManager()
    
    lazy var annotationsManager = mapView.annotations.makePointAnnotationManager()
    var currentLocation = CLLocationCoordinate2D()
    var cameraOptions = CameraOptions()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        mapView.frame = view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.mapboxMap.styleURI = mapStyle
        view.addSubview(mapView)

        mapView.location.options.puckType = .puck2D()
    }

    func showAnnotations(results: [SearchResult], cameraShouldFollow: Bool = true) {
        annotationsManager.annotations = results.map(PointAnnotation.init)

        if cameraShouldFollow {
            cameraToAnnotations(annotationsManager.annotations)
        }
    }

    func cameraToAnnotations(_ annotations: [PointAnnotation]) {
        if annotations.count == 1, let annotation = annotations.first {
            mapView.camera.fly(
                to: .init(center: annotation.point.coordinates, zoom: 15),
                duration: 0.25,
                completion: nil
            )
        } else {
            let coordinates = annotations.map { $0.point.coordinates }
            let padding = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
            do {
                let cameraCoordinates = try mapView.mapboxMap.camera(
                    for: coordinates,
                    camera: CameraOptions(),
                    coordinatesPadding: padding,
                    maxZoom: nil,
                    offset: .zero
                )
                mapView.camera.fly(to: cameraCoordinates, duration: 0.25, completion: nil)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func showAnnotation(_ result: SearchResult) {
        showAnnotations(results: [result])
    }

    func showAnnotation(_ favorite: FavoriteRecord) {
        annotationsManager.annotations = [PointAnnotation(favoriteRecord: favorite)]

        cameraToAnnotations(annotationsManager.annotations)
    }

    func navigateToSearchResult(_ searchResult: SearchResult) {

        // Define the Mapbox Navigation entry point.
        let mapboxNavigationProvider = MapboxNavigationProvider(coreConfig: .init())
        lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

        // Define two waypoints to travel between
        let origin = Waypoint(coordinate: currentLocation, name: "Current location")
        let destination = Waypoint(coordinate: searchResult.coordinate, name: "\(searchResult.name)")
        let navigationRouteOptions = NavigationRouteOptions(waypoints: [origin, destination])

        // Request a route using RoutingProvider
        let request = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)
        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                // Pass the generated navigation routes to the the NavigationViewController
                let navigationOptions = NavigationOptions(mapboxNavigation: mapboxNavigation,
                                                          voiceController: mapboxNavigationProvider.routeVoiceController,
                                                          eventsManager: mapboxNavigationProvider.eventsManager())

                let navigationViewController = NavigationViewController(navigationRoutes: navigationRoutes,
                                                                        navigationOptions: navigationOptions)

                navigationViewController.navigationMapView?.mapView.mapboxMap.setCamera(to: cameraOptions)
                navigationViewController.navigationMapView?.mapView.mapboxMap.styleURI = mapStyle
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.delegate = self

                present(navigationViewController, animated: true, completion: nil)
            }
        }
    }

    func showError(_ error: Error) {
        let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: CLLocationManagerDelegate

extension NavViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .notDetermined:
            print("Location access not determined")
        @unknown default:
            fatalError()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        currentLocation = CLLocationCoordinate2D(latitude: locations.first?.coordinate.latitude ?? 45.51806,
                                                 longitude: locations.first?.coordinate.longitude ?? -75.79369)
        
        cameraOptions = CameraOptions(center: currentLocation, zoom: 17)
        mapView.camera.fly(to: cameraOptions, duration: 4, completion: nil)
        
        lazy var searchController: MapboxSearchController = {
            let locationProvider = PointLocationProvider(coordinate: currentLocation)
            let formatter = MKDistanceFormatter()
            formatter.unitStyle = .abbreviated
            var configuration = Configuration(
                locationProvider: locationProvider,
                distanceFormatter: formatter
            )
            
            return MapboxSearchController(configuration: configuration)
        }()
        
        let panelController = MapboxPanelController(rootViewController: searchController)
        
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

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        let clError = CLError(_nsError: error as NSError)
        switch clError.code {
        case .locationUnknown:
            print("Location unknown. Retrying...")
            // Optionally, you can add a delay and retry fetching the location
        case .denied:
            print("Location access denied by the user.")
            // Handle denial of location access
        case .network:
            print("Network issues. Please check your connection.")
            // Handle network errors
        default:
            print("Location manager error: \(error.localizedDescription)")
        }
    }
}

// MARK: NavigationViewControllerDelegate

extension NavViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.mapView.camera.fly(to: self.cameraOptions, duration: 4, completion: nil)
        }
    }
}

// MARK: SearchControllerDelegate

extension NavViewController: SearchControllerDelegate {
    func categorySearchResultsReceived(category: SearchCategory, results: [SearchResult]) {
        showAnnotations(results: results)
    }

    func searchResultSelected(_ searchResult: SearchResult) {
        showAnnotation(searchResult)

        navigateToSearchResult(searchResult)
    }

    func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
        showAnnotation(userFavorite)
    }

}

extension PointAnnotation {
    init(searchResult: SearchResult) {
        self.init(coordinate: searchResult.coordinate)
        textField = searchResult.name
    }

    init(favoriteRecord: FavoriteRecord) {
        self.init(coordinate: favoriteRecord.coordinate)
        textField = favoriteRecord.name
    }
}
