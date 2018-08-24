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
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    
    
    
    categories.asObservable().subscribe(onNext:{ [weak self] _ in
        DispatchQueue.main.async {
            self?.tableView.reloadData()
        }
    })
    .disposed(by: disposeBag)
    
    
    startDownload()
  }

  
  
  
  
  func startDownload() {
    /***
     首先 下载 categories 并显示 然后 下载过去一年的events
    ***/
    let eoCategories = EONET.categories
    activityIndicator.startAnimating()
    let downloadedEvents = eoCategories.flatMap { categories in
      return Observable.from(categories.map { category in
        EONET.events(forLast: 360, category: category)
      })
      }.merge(maxConcurrent: 2)
    
    downloadedEvents.subscribe( onError: { [weak self] _ in
      DispatchQueue.main.async {
        self?.activityIndicator.stopAnimating()
      }
    }, onCompleted: { [weak self] in
      DispatchQueue.main.async {
        self?.activityIndicator.stopAnimating()
      }
      
    }).disposed(by: disposeBag)
    
    
    
    /***
     combineLatest 操作符将多个 Observables 中最新的元素通过一个函数组合起来，然后将这个组合的结果发出来。这些源 Observables 中任何一个发出一个元素，他都会发出一个元素（前提是，这些 Observables 曾经发出过元素）。
     //    let updateCategories = Observable.combineLatest(eoCategories, downloadedEvents) {
     //        (categories, events) -> [EOCategory] in
     //        return categories.map{ category in
     //            var cat = category
     //            cat.events = events.filter{
     //                $0.categories.contains(category.id)
     //            }
     //            return cat
     //        }
     //    }
    ***/
    
    /**
     scan 操作符将对第一个元素应用一个函数，将结果作为第一个元素发出。然后，将结果作为参数填入到第二个元素的应用函数中，创建第二个元素。以此类推，直到遍历完全部的元素。
     
     这种操作符在其他地方有时候被称作是 accumulator。
    **/
    // 目的是更新 Categorie 因为每个Category下载下来的 events observable 通过merge() 是无序发射的 所以每次收到 downloadedEvents 所发出的事件 进行scan 通过 accumulator整合 categories
    let updateCategories = eoCategories.flatMap { categories in
      //对所下载下来的 events 进行 scan 返回 [EOCategory]
      downloadedEvents.scan(categories) {updated, events in
        return updated.map {category in
          let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)//过滤出最新的event
          if !eventsForCategory.isEmpty {
            var cat = category
            cat.events = cat.events + eventsForCategory
            return cat
          }
          return category
        }
      }
    }

    eoCategories.concat(updateCategories).bind(to: categories).disposed(by: disposeBag)

  }
  
  // MARK: UITableViewDataSource
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return categories.value.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
    let category = categories.value[indexPath.row]
    cell.textLabel?.text = "\(category.name) (\(category.events.count)"
    cell.detailTextLabel?.text = category.description
    cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
    
    
    return cell
  }
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let category = categories.value[indexPath.row]
    if !category.events.isEmpty {
      let eventsController = storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
      eventsController.title = category.name
      eventsController.events.value = category.events
      navigationController?.pushViewController(eventsController, animated: true)
      
    }
    tableView.deselectRow(at: indexPath, animated: true)
    
  }
  
}

