//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa



// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    return TimelineView(width: 400, height: 100)
  }
  public func on(_ event: Event<E>) {
    switch event {
    case .next(let value):
      add(.Next(String(describing: value)))
    case .completed:
      add(.Completed())
    case .error(_):
      add(.Error())
    }
  }
}
/*:
 Copyright (c) 2014-2017 Razeware LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */
let elementsPerSecond = 1
let maxElements = 20
let replayedElements = 4
let replayDelay: TimeInterval = 3


let sourceObservable = Observable<Int>.create { observer in
  var value = 1
  let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main, handler: {
    if value <= maxElements {
      observer.onNext(value)
      value = value + 1
    }
  })
  return Disposables.create {
    timer.suspend()
  }
}.replay(replayedElements)
//replay 新的订阅者会收到observable的重放元素


let sourceTimeline = TimelineView<Int>.make()
let replayedTimeline = TimelineView<Int>.make()

let stackView = UIStackView.makeVertical([
  UILabel.make("replay"),
  UILabel.make("Emit \(elementsPerSecond) per second:"),
  sourceTimeline,
  UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
  replayedTimeline
  
  ])
// 立即订阅
  _ = sourceObservable.subscribe(sourceTimeline)
//三秒后 再次订阅
  DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
    _ = sourceObservable.subscribe(replayedTimeline)
  }
// replay 操作符返回的是ConnectableObservable<E> 类型 这种类型的observable需要调用connect（）才能发出事件 类似的还有 replayAll() multicast(_:) publish()
  _ = sourceObservable.connect()

let hostView = setupHostView()
hostView.addSubview(stackView)
hostView






















