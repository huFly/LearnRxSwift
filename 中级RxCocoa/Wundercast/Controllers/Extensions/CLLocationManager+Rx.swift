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
import CoreLocation
import RxSwift
import RxCocoa

extension CLLocationManager: HasDelegate {
  public typealias Delegate = CLLocationManagerDelegate
}

class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
  //通过使用这两个函数，您可以初始化委托并注册所有实现，这些实现将是用于将数据从CLLocationManager实例驱动连接到Observavbles。这是扩展类以使用RxCocoa中的委托代理模式的方法。
  public weak private(set) var locationManager: CLLocationManager?
  public init(locationManager: ParentObject) {
    self.locationManager = locationManager
    super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
  }
  static func registerKnownImplementations() {
    self.register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
  }
}


//创建 obervable 来观察location的变化
//通过 扩展 Reactive 可以将扩展之内的 方法 暴露在 CLLocationManager 的 rx 命名空间下
extension Reactive where Base: CLLocationManager {
  public var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
    
    return RxCLLocationManagerDelegateProxy.proxy(for: base)
  }
  // delegate 将监听 CLLocationManagerDelegate.locationManager
  var didUpadateLocations: Observable<[CLLocation]> {
    return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:))).map { parameters in
      //parameters 指的是 methodInvoked中指定方法参数的数组
      return parameters[1] as! [CLLocation]
    }
  }
  
  
  
}
































