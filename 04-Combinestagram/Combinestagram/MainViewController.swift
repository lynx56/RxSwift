/*
 * Copyright (c) 2016-present Razeware LLC
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

class MainViewController: UIViewController {
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    let limitPhotoCount = 6
    var disposeBag = DisposeBag()
    var photos = Variable<[UIImage]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photos.asObservable().throttle(0.5, scheduler: MainScheduler.instance).subscribe{
            switch($0) {
            case .next(let photos):
                self.imagePreview.image = UIImage.collage(images: photos, size: self.imagePreview.frame.size)
                self.updateUI()
            case .error(let error):
                self.showMessage(error.localizedDescription)
            case .completed:
                print("completed")
            }
            }.disposed(by: disposeBag)
        
        self.photos.asObservable().subscribe { _ in
            if self.photos.value.isEmpty {
                self.navigationItem.leftBarButtonItem = nil
            }}.disposed(by: disposeBag)
    }
    
    @IBAction func actionClear() {
        self.photos.value = []
    }
    
    @IBAction func actionSave() {
        PhotoWriter().save(photo: self.imagePreview.image!).asSingle().subscribe(
            onSuccess: { [unowned self]_ in self.showMessage("Коллаж сохранен в Фото")},
            onError: { [unowned self](error) in self.showMessage("Случилась ошибка", description: error.localizedDescription) }).disposed(by: disposeBag)
    }
    
    func updateUI() {
        self.buttonSave.isEnabled = photos.value.count > 0
        self.buttonClear.isEnabled = photos.value.count > 0
        self.itemAdd.isEnabled = photos.value.count < self.limitPhotoCount
    }
    
    func updateNavigationIcon() {
        let icon = imagePreview.image?.scaled(CGSize(width: 22, height: 22)).withRenderingMode(.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
    
    private var imageCache = [Int]()
    @IBAction func actionAdd() {
        let photoController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        let newPhotos = photoController.selectedPhoto.share()
        
        newPhotos.takeWhile { [weak self] _ in return self != nil && self!.photos.value.count < self!.limitPhotoCount }.filter { [unowned self] (val) in
            let cacheValue = UIImagePNGRepresentation(val)?.count ?? 0
            
            guard !self.imageCache.contains(cacheValue)
                else { return false }
            
            self.imageCache.append(cacheValue)
            return true
            }
            .subscribe { [unowned self] event in
                switch event {
                case .next(let photo): self.photos.value.append(photo)
                case .error(let error): self.showMessage("Error occured: \(error)")
                case .completed: print("completed")
                }
            }.disposed(by: photoController.disposedBag)
        
        newPhotos.ignoreElements().subscribe(
            {[weak self]  event in
                self?.updateNavigationIcon()}).disposed(by: photoController.disposedBag)
        
        
        self.navigationController?.pushViewController(photoController, animated: true)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
        present(alert, animated: true, completion: nil)
    }
}
