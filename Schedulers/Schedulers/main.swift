/*
 * Copyright (c) 2014-2016 Razeware LLC
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

print("\n\n\n===== Schedulers =====\n")
//全局并行队列
let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
let bag = DisposeBag()
let animal = BehaviorSubject(value: "[dog]")

let fruit = Observable<String>.create { (observer) -> Disposable in
  observer.onNext("[apple]")
  sleep(2)
  observer.onNext("[pineapple]")
  sleep(2)
  observer.onNext("[strawberry]")
  return Disposables.create()
}

//fruit
//  .subscribeOn(globalScheduler)
//  .dump()
//  .observeOn(MainScheduler.instance)
//  .dumpingSubscription()
//  .disposed(by: bag)

animal
  .dump()
  .observeOn(globalScheduler)
  .dumpingSubscription()
  .disposed(by: bag)

//在子线程发出元素
let animalsThreed = Thread {
  sleep(3)
  animal.onNext("[cat]")
  sleep(3)
  animal.onNext("[tiger]")
  sleep(3)
  animal.onNext("[fox]")
  sleep(3)
  animal.onNext("leopard")
}
animalsThreed.name = "Animals Thread"
animalsThreed.start()




// runloop 中没有 port 或 timer 处理时 就会退出 runloop循环 设定终止时间可以阻止runloop退出 它通过重复调用run(mode:before:)来运行NSDefaultRunLoopMode中的接收器，直到指定的过期日期
RunLoop.main.run(until: Date(timeIntervalSinceNow: 13))
