//
//  MapKit+rx.swift
//  Wundercast
//
//  Created by lynx on 20/11/2018.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import MapKit
import RxCocoa
import RxSwift

extension MKMapView: HasDelegate {
    public typealias Delegate = MKMapViewDelegate
}

class RxMKMapViewDelegateProxy: DelegateProxy<MKMapView,MKMapViewDelegate>,
DelegateProxyType, MKMapViewDelegate {
    public weak private(set) var _mapView: MKMapView?
    
    public init(mapView: MKMapView) {
        _mapView = mapView
        
        super.init(parentObject: mapView, delegateProxy: RxMKMapViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register {
            RxMKMapViewDelegateProxy(mapView: $0)
        }
    }
}

extension Reactive where Base: MKMapView {
    var delegate: DelegateProxy<MKMapView,MKMapViewDelegate> {
        return RxMKMapViewDelegateProxy.proxy(for: base)
    }
    
    func setDelegate(_ delegate: MKMapViewDelegate) -> Disposable {
        return RxMKMapViewDelegateProxy.installForwardDelegate(
            delegate,
            retainDelegate: false,
            onProxyForObject: self.base)
    }
    
    var overlays: Binder<[MKOverlay]> {
        return Binder(self.base) {
            mapView, overlays in
            mapView.removeOverlays(overlays)
            mapView.addOverlays(overlays)
        }
    }
    
    public var regionDidChangeAnimated: ControlEvent<Bool> {
        let source = delegate
            .methodInvoked(#selector(MKMapViewDelegate.mapView(_:regionDidChangeAnimated:)))
            .map { parameters in
                return (parameters[1] as? Bool) ?? false
        }
        
        return ControlEvent(events: source)
    }
}
