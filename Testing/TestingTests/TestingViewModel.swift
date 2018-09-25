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
import RxCocoa
import RxTest
@testable import Testing

class TestingViewModel : XCTestCase {

  var viewModel: ViewModel!
  var scheduler: ConcurrentDispatchQueueScheduler!

  override func setUp() {
    super.setUp()
    viewModel = ViewModel()
    scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
  }
  // xctest 自己的测试 异步的api expectation
  func testColorIsRedWhenHexStringIsFF0000_async() {
    let disposeBag = DisposeBag()
    let expect = expectation(description: #function)
    let expectedColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    var result: UIColor!
    
    viewModel.color.asObservable()
      //因为 driver 在订阅时会重放初始的元素
      .skip(1)
      .subscribe(onNext: {
        result = $0
        //标记 expect 已经执行
        expect.fulfill()
      })
    .disposed(by: disposeBag)
    //更改 Variable 的值
    viewModel.hexString.value = "#ff0000"
    //等待 expect 执行 超时时间为 1秒
    waitForExpectations(timeout: 1.0) { error in
      guard error == nil else {
        XCTFail(error!.localizedDescription)
        return
      }
    }
  }
  // 使用 rxblocking 测试异步
  func testColotIsRedWhenHexStringIsFF0000() {
    //1
    let colorObservable = viewModel.color.asObservable().subscribeOn(scheduler)
    viewModel.hexString.value = "ff0000"
    
    do {
      //first() 阻塞 当前线程直至发出第一个元素
      guard let result = try colorObservable.toBlocking(timeout: 1.0).first() else {
        return
      }
      XCTAssertEqual(result, .red)
    } catch {
      print(error)
    }
    
  }
  
  func testRgbIs010WhenHexStringIs00FF00() {
    let rgbObservable = viewModel.rgb.asObservable().subscribeOn(scheduler)
    viewModel.hexString.value = "#00ff00"
    let result = try! rgbObservable.toBlocking().first()!
    XCTAssertEqual(0 * 255, result.0)
    XCTAssertEqual(1 * 255, result.1)
    XCTAssertEqual(0 * 255, result.2)
    
  }
  
  func testColorNameIsRayWenderlichGreenWhenHexStringIs006636() {
    let colorNameObservable = viewModel.colorName.asObservable().subscribeOn(scheduler)
    viewModel.hexString.value = "#006636"
    let result = try! colorNameObservable.toBlocking().first()!
    XCTAssertEqual("rayWenderlichGreen", result)
    
  }
  
  
  
  
}
