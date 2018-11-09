//
//  AlertViewController+rx.swift
//  Combinestagram
//
//  Created by lynx on 02/11/2018.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
    func alert(_ title: String, text: String) -> Completable{
        return Completable.create { [weak self] (completable) in
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: {_ in
                completable(.completed)
            }))
                
                self?.present(alert, animated: true, completion: nil)
                
                return Disposables.create {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

