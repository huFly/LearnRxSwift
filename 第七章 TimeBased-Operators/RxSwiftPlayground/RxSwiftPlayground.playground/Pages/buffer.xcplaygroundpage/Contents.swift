//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

let bufferTimeSpan: RxTimeInterval = 5
let bufferMaxCount = 3

let sourceObservable = PublishSubject<String>()
let sourceTimeline = TimelineView<String>.make()
let bufferedTimeline = TimelineView<Int>.make()


let stack = UIStackView.makeVertical([
  UILabel.makeTitle("buffer"),
  UILabel.make("Emitted elements:"),
  sourceTimeline, UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds):"),
  bufferedTimeline])

_ = sourceObservable.subscribe(sourceTimeline)
//通过 buffer 将bufferTimeSpan时间内接收的元素变成array再发出 每个array最多有 bufferMaxCount个元素 如果在bufferTimeSpan时间内收到的元素多于bufferMaxCount 就把 bufferMaxCount 个元素的array 发出，然后再开始计时。
sourceObservable
  .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
  .map { $0.count }
  .subscribe(bufferedTimeline)

let hostView = setupHostView()
hostView.addSubview(stack)
hostView
//时间间隔为4s 第一个时间段为 0个元素 第2个时间段为 2个元素 第3时间段为 1个元素
//DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//  sourceObservable.onNext("🐱")
//  sourceObservable.onNext("🐱")
//  sourceObservable.onNext("🐱")
//}

let elementsPerSecond = 1
//每个时间间隔内都会有2个元素
let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
  sourceObservable.onNext("🐱")
}













// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    let view = TimelineView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
    view.setup()
    return view
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

