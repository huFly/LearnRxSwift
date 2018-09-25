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
import MapKit
import RxSwift
import RxCocoa

extension MKMapView: HasDelegate {
  public typealias Delegate = MKMapViewDelegate
}

class RxMKMapViewDelegateProxy: DelegateProxy<MKMapView, MKMapViewDelegate>, DelegateProxyType, MKMapViewDelegate {
  public weak private(set) var mapView: MKMapView?
  public init(mapView: ParentObject) {
    self.mapView = mapView
    super.init(parentObject: mapView, delegateProxy: RxMKMapViewDelegateProxy.self)
  }
  static func registerKnownImplementations() {
    self.register { RxMKMapViewDelegateProxy(mapView: $0) }
  }
}

extension Reactive where Base: MKMapView {
  public var delegate: DelegateProxy<MKMapView, MKMapViewDelegate> {
    return RxMKMapViewDelegateProxy.proxy(for: base)
  }

  public func setDelegate(_ delegate: MKMapViewDelegate) -> Disposable {
    //你想要遵循带有返回值的委托方法的实用性，就像你在普通UIKit开发中做的那样，但是你也想要从委托函数中使用observables。
    //  有了这个函数，您现在可以安装一个转发委托，它将转发调用并在必要时提供返回值。
    return RxMKMapViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: self.base)
  }
  var overlays: Binder<[MKOverlay]> {
    return Binder(self.base){ mapview, overlays in
      mapview.removeOverlays(mapview.overlays)
      mapview.addOverlays(overlays)
    }
  }
  
  var searchedLocation: Binder<CLLocation> {
    return Binder(self.base) { mapView, location in
//      let currentRegion = mapView.region
      let toReagion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), span: MKCoordinateSpanMake(0.8, 0.8))
      mapView.setRegion(toReagion, animated: true)
    }
  }
  
  
  public var regionDidChangeAnimated: ControlEvent<Bool> {
    let source = delegate.methodInvoked(#selector(MKMapViewDelegate.mapView(_:regionDidChangeAnimated:)))
      .map { parameter in return (parameter[1] as? Bool) ?? false }
    return ControlEvent(events: source)
    
  }
  
}
