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

import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class ViewController: UIViewController {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var mapButton: UIButton!
  @IBOutlet weak var geoLocationButton: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var searchCityName: UITextField!
  @IBOutlet weak var tempLabel: UILabel!
  @IBOutlet weak var humidityLabel: UILabel!
  @IBOutlet weak var iconLabel: UILabel!
  @IBOutlet weak var cityNameLabel: UILabel!

  let bag = DisposeBag()
  let locationManager = CLLocationManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    style()
    /**
     * 需求:当通过文字搜索城市名 和 通过地理位置获取天气数据 时显示activity 隐藏天气信息等labels. 当请求到天气数据是停止activity 并显示labels呈现相关天气数据
     **/
    
    
    
    let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
      .map { self.searchCityName.text }
      .filter { ($0 ?? "").count > 0 }
    
    let textSearch = searchInput.flatMap { text in
      return ApiController.shared.currentWeather(city: text ?? "Error")
        .catchErrorJustReturn(ApiController.Weather.dummy)
      }
    
    // 获取当前位置
    let currentLocation = locationManager.rx.didUpadateLocations.map {
      locations
      in return locations[0]
      }.filter {
        location in
        return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
    }
    //点击时处理
    let geoInput = geoLocationButton.rx.tap.asObservable()
      .do(onNext: {
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
      })
    //每次点击location按钮 只取第一个坐标 以后的坐标忽略
    let geoLocation = geoInput.flatMap { return currentLocation.take(1) }
    // 将坐标转换为 weather
    let geoSearch = geoLocation.flatMap { location in
      return ApiController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude ).catchErrorJustReturn(ApiController.Weather.dummy)
    }
    
    
    /*
     * 移动地图时刷新数据
     */
    // 取中心点的坐标 skip(1)可以防止app再第一次创建mapview时的触发
    let mapInput = mapView.rx.regionDidChangeAnimated.skip(1).map { _ in self.mapView.centerCoordinate}
    let mapSearch = mapInput.flatMap { coordinate in
      return ApiController.shared.currentWeather(lat: coordinate.latitude, lon: coordinate.longitude)
        .catchErrorJustReturn(ApiController.Weather.dummy)
    }
    //根据搜索的地址切换地图显示  练习1
    let locationSearch = Observable.from([geoSearch, textSearch]).merge().asDriver(onErrorJustReturn: ApiController.Weather.dummy)
    locationSearch.map { weather in
      return CLLocation(latitude: weather.lat, longitude: weather.lon)
    }.drive(mapView.rx.searchedLocation).disposed(by: bag)
    locationSearch.map {[$0.overlay()]}.drive(mapView.rx.overlays).disposed(by: bag)
    
    
    
    //无论是根据城市名获取数据 还是根据location 获取
    let search = Observable.from([geoSearch, textSearch, mapSearch])
      .merge()
      .asDriver(onErrorJustReturn: ApiController.Weather.dummy)
    
    
    //asObservable 在此很有必要  因为保证了 array中的数据类型的一致性
    let running = Observable.from([searchInput.map { _ in true }, geoInput.map { _ in true }, mapInput.map { _ in true }, search.map { _ in false }.asObservable()])
      .merge()
      .startWith(true)
      .asDriver(onErrorJustReturn: false)
    
    
    //练习 2
    _ = mapInput.flatMap { location in
      return ApiController.shared.currentWeatherAround(lat: location.latitude, lon: location.longitude).catchErrorJustReturn([ApiController.Weather.dummy])
      }.asDriver(onErrorJustReturn: [ApiController.Weather.dummy]).map { $0.map { $0.overlay() } }
        .drive(mapView.rx.overlays)
        .disposed(by: bag)
    
    
    
    
    
    
    
    running.skip(1).drive(activityIndicator.rx.isAnimating).disposed(by: bag)
    running.drive(tempLabel.rx.isHidden).disposed(by: bag)
    running.drive(iconLabel.rx.isHidden).disposed(by: bag)
    running.drive(humidityLabel.rx.isHidden).disposed(by: bag)
    running.drive(cityNameLabel.rx.isHidden).disposed(by: bag)

    search.map { "\($0.temperature)° C" }
      .drive(tempLabel.rx.text)
      .disposed(by: bag)

    search.map { $0.icon }
      .drive(iconLabel.rx.text)
      .disposed(by: bag)

    search.map { "\($0.humidity)%" }
      .drive(humidityLabel.rx.text)
      .disposed(by: bag)

    search.map { $0.cityName }
      .drive(cityNameLabel.rx.text)
      .disposed(by: bag)
    
    /*
     * 将天气数据展示到地图上
     */
    mapButton.rx.tap
      .subscribe(onNext: { self.mapView.isHidden = !self.mapView.isHidden })
      .disposed(by: bag)
    mapView.rx.setDelegate(self).disposed(by: bag)
    search.map {[$0.overlay()]}.drive(mapView.rx.overlays).disposed(by: bag)
    

    
    
    
    
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    Appearance.applyBottomLine(to: searchCityName)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Style

  private func style() {
    view.backgroundColor = UIColor.aztec
    searchCityName.textColor = UIColor.ufoGreen
    tempLabel.textColor = UIColor.cream
    humidityLabel.textColor = UIColor.cream
    iconLabel.textColor = UIColor.cream
    cityNameLabel.textColor = UIColor.cream
  }
}

extension ViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let overlay = overlay as? ApiController.Weather.Overlay {
      let overlayView = ApiController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
      return overlayView
    }
    return MKOverlayRenderer()
  }
}


