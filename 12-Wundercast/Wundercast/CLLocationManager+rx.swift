//
//  CLLocationManager.swift
//  Wundercast
//
//  Created by lynx on 20/11/2018.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import MapKit
import RxSwift
import RxCocoa

extension CLLocationManager: HasDelegate {
    public typealias Delegate = CLLocationManagerDelegate
}

class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>,
DelegateProxyType, CLLocationManagerDelegate{
    public weak private(set) var _locationManager: CLLocationManager?
    
    public init(locationManager: ParentObject) {
        _locationManager = locationManager
        
        super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register {
            RxCLLocationManagerDelegateProxy(locationManager: $0)
        }
    }
}

extension Reactive where Base: CLLocationManager {
    public var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        return RxCLLocationManagerDelegateProxy.proxy(for: base)
    }
    
    var didUpdateLocations: Observable<[CLLocation]> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
        .map { parameters in
            return parameters[1] as! [CLLocation]
        }
    }
}
