/*
 * Copyright (c) 2014-2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import RxCocoa
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var geolocationButton: UIButton!
    
    let disposeBag = DisposeBag()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        style()
        
        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").count > 0 }
        
        let textSearch = searchInput.flatMap { text in
            return ApiController.shared.currentWeather(city: text ?? "Error")
                .catchErrorJustReturn(ApiController.Weather.empty)
        }
        
        let currentLocation = locationManager.rx
            .didUpdateLocations
            .map { $0[0] }
            .filter { location in
                return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
        }
        
        let geoInput = geolocationButton.rx.tap.asObservable()
            .do(onNext: { _ in
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
        
        let mapInput = mapView.rx.regionDidChangeAnimated
        .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        
        let mapSearch = mapInput
            .flatMap { coordinate in
                return ApiController.shared.currentWeather(latitude: coordinate.latitude, longitude: coordinate.longitude)
                .catchErrorJustReturn(ApiController.Weather.empty)
        }
        
        mapButton.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden = !self.mapView.isHidden
            })
            .disposed(by: disposeBag)
        
        mapView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation
            .flatMap { location in
                return ApiController.shared.currentWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    .catchErrorJustReturn(ApiController.Weather.empty) }
        
        let search = Observable.from([
            geoSearch, textSearch, mapSearch])
            .merge()
            .asDriver(onErrorJustReturn: ApiController.Weather.empty)
        
        let running = Observable.from([
            textSearch.map { _ in true },
            geoSearch.map { _ in true },
            search.map { _ in false }.asObservable(),
            mapInput.map { _ in true }
            ])
            .merge()
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        running.skip(1)
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        running
            .drive(tempLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        running
            .drive(iconLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        running
            .drive(humidityLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        running
            .drive(cityNameLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        search.map { Int($0.temperature.converted(to: .celsius).value) }
            .map { "\($0)° C" }
            .drive(tempLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map { $0.icon }
            .drive(self.iconLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map { "\($0.humidity)%" }
            .drive(self.humidityLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map { $0.cityName }
            .drive(self.cityNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map { [$0.overlay()] }
            .drive(mapView.rx.overlays)
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ApiController.Weather.Overlay {
            let overlayView = ApiController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        
        return MKOverlayRenderer()
    }
}
