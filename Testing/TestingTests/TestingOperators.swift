/*
 * Copyright (c) 2014-2017 Razeware LLC
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

import XCTest
import RxSwift
import RxTest//测试同步
import RxBlocking//测试异步

/*
 
 */



class TestingOperators : XCTestCase {

  var scheduler: TestScheduler!
  var subscription: Disposable!

  override func setUp() {
    super.setUp()
    scheduler = TestScheduler(initialClock: 0)
  }

  override func tearDown() {
    scheduler.scheduleAt(1000) {
      self.subscription.dispose()
    }

    super.tearDown()
  }
  
  func testToArrayMaterialized() {
    //rxblock 主要作用是通过 toBlock()方法将observable转换成 BlockingObservable , 阻塞当前的线程直到 observable 终止
    //在此方法指定 timeout参数(默认为 nil) 如果timeout指定的时间 小于 observable 终止的时间 则会抛出RxError.timeout
    //这本质上是将一个异步的操作转换成同步的操作
    
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    let toArrayObservable = Observable.of(1, 2).subscribeOn(scheduler)
    //当observable 成功终止, 返回 .completed(elements) 并携带observabel所发出的元素集, 失败的话 则返回 .failed(elements, error)
    let resultObservable  = toArrayObservable.toBlocking().materialize()
    
    switch resultObservable {
    case .completed(elements: let elements):
      XCTAssertEqual(elements, [1, 2])
    case .failed(elements: _, error: let error):
      XCTFail(error.localizedDescription)
    }    
  }
  
  
  
  func testToArray() {
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    let toArrayObservable = Observable.of(1, 2).subscribeOn(scheduler)
    XCTAssertEqual(try! toArrayObservable.toBlocking().toArray(), [1, 2])
    
  }
  
  func testFilter() {
    //使用RxTest 测试同步observable
    let observer = scheduler.createObserver(Int.self)
    let observable = scheduler.createHotObservable([
      next(100, 1),
      next(200, 2),
      next(300, 3),
      next(400, 2),
      next(500, 1)
      ])
    let filterObservable = observable.filter {
      $0 < 3
    }
    scheduler.scheduleAt(0) {
      self.subscription = filterObservable.subscribe(observer)
    }
    scheduler.start()
    let result = observer.events.map {
      $0.value.element!
    }
    XCTAssertEqual(result, [1, 2, 2, 1])
  }
  
  
  func testAmb() {
    let observer = scheduler.createObserver(String.self)
    let observableA = scheduler.createHotObservable([
      next(100, "a"),
      next(200, "b"),
      next(300, "c")
      ])
    let observableB = scheduler.createHotObservable([
      next(90, "1"),
      next(200, "2"),
      next(300, "3")
      ])
    let ambObservable = observableA.amb(observableB)
    scheduler.scheduleAt(0) {
      self.subscription = ambObservable.subscribe(observer)
    }
    scheduler.start()
    let results = observer.events.map {
      $0.value.element!
    }
    XCTAssertEqual(results, ["1", "2", "No you didn't!"])
    
    
  }
  
}
