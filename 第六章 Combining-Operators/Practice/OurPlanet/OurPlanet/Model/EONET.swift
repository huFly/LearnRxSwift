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


import Foundation
import RxSwift
import RxCocoa

class EONET {
  static let API = "https://eonet.sci.gsfc.nasa.gov/api/v2.1"
  static let categoriesEndpoint = "/categories"
  static let eventsEndpoint = "/events"

  static var ISODateReader: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
    return formatter
  }()

  static func filteredEvents(events: [EOEvent], forCategory category: EOCategory) -> [EOEvent] {
    return events.filter { event in
      //正在遍历的 event 的 categories 包含 要匹配的 category.id 且 要匹配的 category.events.id  与正在遍历的 event.id 不相同
      return event.categories.contains(category.id) &&
             !category.events.contains {
               $0.id == event.id
             }
    }
    .sorted(by: EOEvent.compareDates)
  }
  
    static func request(endpoint: String, query: [String: Any] = [:]) -> Observable<[String: Any]> {
        do {
            guard let url = URL(string: API)?.appendingPathComponent(endpoint),
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw EOError.invalidURL(endpoint) }
            components.queryItems = try query.compactMap { (key, value) in
                guard let v = value as? CustomStringConvertible else {
                    throw EOError.invalidParameter(key, value)
                }
                return URLQueryItem(name: key, value: v.description)
            }
            
            guard let finalURL = components.url else {
                throw EOError.invalidURL(endpoint)
            }
            let request = URLRequest(url: finalURL)
            return URLSession.shared.rx.response(request: request)
              .map { _, data -> [String: Any] in
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []), let result = jsonObject as? [String: Any] else {
                    throw EOError.invalidJSON(finalURL.absoluteString)
                }
                return result
            }
            
        } catch {
            return Observable.empty()
        }
    }
    
    static var categories: Observable<[EOCategory]> = {
        return EONET.request(endpoint: categoriesEndpoint).map{ data in
            let categories = data["categories"] as? [[String : Any]] ?? []
            return categories.compactMap(EOCategory.init).sorted { $0.name < $1.name }
            }
            .catchErrorJustReturn([])
            .share(replay: 1, scope: .forever)
        // share(replay: 1, scope: .forever) 共享这个observe源 传递所有的元素 给第一个subscriber  然后把最后接受到的元素给其他新的 subscriber
        
    }()
    
  fileprivate static func events(forLast days: Int, closed: Bool, endpoint: String) -> Observable<[EOEvent]>{
        return request(endpoint: endpoint, query: ["days": NSNumber(value: days), "status": (closed ? "closed": "open")])
            .map{ json in
                guard let raw = json["events"] as? [[String: Any]] else {
                    throw EOError.invalidJSON(endpoint)
                }
                return raw.compactMap(EOEvent.init)
            }
            .catchErrorJustReturn([])
    }
    
    
    
  static func events(forLast days: Int = 360, category: EOCategory) -> Observable<[EOEvent]> {
    let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint)
    let closedEvent = events(forLast: days, closed: true, endpoint: category.endpoint)
        /**
         可以使用 concat 顺序的下载 event
         concat 操作符将多个 Observables 按顺序串联起来，当前一个 Observable 元素发送完毕后，后一个 Observable 才可以开始发出元素。
         
         concat 将等待前一个 Observable 产生完成事件后，才对后一个 Observable 进行订阅。
         
         所有的 Observables 结束后 会发送 完成事件  如果其中有 error 事件产生 会立即发送 error事件 并终止
         
         openEvents.concat(closedEvent)
        **/
        
        
        /**
         通过使用 merge 操作符你可以将多个 Observables 合并成一个，当某一个 Observable 发出一个元素时，他就将这个元素发出。
         
         如果，某一个 Observable 发出一个 onError 事件，那么被合并的 Observable 也会将它发出，并且立即终止序列。
         通过 reduce 函数 将结果结合起来 并最终返回 Observable<EOEvent>
        **/
    // reduce 持续的将 Observable 的每一个元素应用一个函数，然后发出<最终!>结果
    
        return Observable.of(openEvents, closedEvent).merge().reduce([]) { running, new in
            running + new
        }
        
        
    }
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
