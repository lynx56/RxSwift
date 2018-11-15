/*
 * Copyright (c) 2016 Razeware LLC
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

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    let categories = Variable<[EOCategory]>([])
    let disposeBag = DisposeBag()
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        indicator.hidesWhenStopped = true
        
        return indicator
    }()
    
    let download = DownloadView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        view.addSubview(download)
        view.layoutIfNeeded()
        
        categories.asObservable().subscribe(onNext: { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }).disposed(by: disposeBag)
        
        startDownload()
    }
    
    func startDownload() {
        DispatchQueue.main.async {
            self.download.progress.progress = 0.0
            self.download.label.text = "Download: 0%"
            self.download.isHidden = false
            self.activityIndicator.startAnimating()
        }
        
        let eoCategories = EONET.categories
        eoCategories.bind(to: categories)
            .disposed(by: disposeBag)
        
        let events = eoCategories.flatMap {
            categories in
            return Observable.from(categories.map {
                category in EONET.events(forLast: 360, category: category)
            })
            }.merge(maxConcurrent: 2)
        
        let updatedCategories = eoCategories.flatMap { categories in
            events.scan((0,categories)) { tuple, events in
                return (tuple.0 + 1, tuple.1.map { category in
                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    return category
                })
            }
            }
            .do(onNext: { [weak self] tuple in
                DispatchQueue.main.async {
                    let progress = Float(tuple.0) / Float(tuple.1.count)
                    self?.download.progress.progress = progress
                    let percent = Int(progress * 100.0)
                    self?.download.label.text = "Download: \(percent)%"
                }
            })
            .do(onCompleted: { [weak self] in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.download.isHidden = true
                }
            })
        
        _ = Observable.combineLatest(eoCategories, events) { (categories, events) -> [EOCategory] in
            
            return categories.map { category in
                var cat = category
                cat.events = events.filter {
                    $0.categories.contains(category.id)
                }
                
                return cat
            }
        }
        
        eoCategories.concat(updatedCategories.map{$0.1})
            .bind(to: categories)
            .disposed(by: disposeBag)
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        
        let category = categories.value[indexPath.row]
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.accessoryType = category.events.count > 0 ? .disclosureIndicator : .none
        cell.detailTextLabel?.text = category.description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let category = categories.value[indexPath.row]
        
        if !category.events.isEmpty {
            let eventsController = storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
            eventsController.title = category.name
            eventsController.events.value = category.events
            
            navigationController!.pushViewController(eventsController, animated: true)
        }
    }
}

