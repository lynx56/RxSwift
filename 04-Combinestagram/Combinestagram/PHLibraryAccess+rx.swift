//
//  PHLibraryAccess+rx.swift
//  Combinestagram
//
//  Created by lynx on 02/11/2018.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import Photos
import RxSwift

extension PHPhotoLibrary {
    static var access: Observable<Bool> {
        get {
            return Observable<Bool>.create { observable in
                DispatchQueue.main.async {
                    if PHPhotoLibrary.authorizationStatus() == .authorized {
                        observable.onNext(true)
                        observable.onCompleted()
                    }else {
                        observable.onNext(false)
                        
                        PHPhotoLibrary.requestAuthorization { newStatus in
                            observable.onNext(newStatus == .authorized)
                            observable.onCompleted()
                        }
                    }
                }
                
                return Disposables.create()
            }
        }
    }
}
