//
//  LocationManager.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - 位置管理 LocationManager
/// 取得使用者當前位置名稱、經緯度、以及 geocode 查詢
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// 取得目前經緯度 (簡化版本，實務建議完善權限處理與多次調用管理)
    func currentLocationCoordinate() async -> CLLocationCoordinate2D {
        // 如果已經有位置且不太久遠，直接返回
        if let currentLocation = locationManager.location,
           currentLocation.timestamp.timeIntervalSinceNow > -60 { // 60秒內的位置
            return currentLocation.coordinate
        }
        
        // 檢查定位權限
        let authStatus = locationManager.authorizationStatus
        if authStatus == .denied || authStatus == .restricted {
            print("定位權限被拒絕")
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        
        // 如果還沒有權限，請求權限
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // 給一點時間等待權限回應
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }
        
        // 如果已經在進行定位，等待現有的 continuation
        if locationContinuation != nil {
            return await withCheckedContinuation { continuation in
                // 這裡我們需要排隊等待
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume(returning: self.locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
                }
            }
        }

        locationManager.startUpdatingLocation()
        
        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            
            // 設置超時處理
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.locationContinuation != nil {
                    print("定位超時")
                    self.locationManager.stopUpdatingLocation()
                    self.locationContinuation?.resume(returning: CLLocationCoordinate2D(latitude: 0, longitude: 0))
                    self.locationContinuation = nil
                }
            }
        }
    }

    /// CLLocationManagerDelegate 回調
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let continuation = locationContinuation else { return }
        if let loc = locations.first {
            locationManager.stopUpdatingLocation()
            continuation.resume(returning: loc.coordinate)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失敗: \(error.localizedDescription)")
        locationManager.stopUpdatingLocation()
        locationContinuation?.resume(returning: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        locationContinuation = nil
    }
    
    /// 處理權限變更
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("定位權限狀態變更: \(status.rawValue)")
        switch status {
        case .denied, .restricted:
            print("定位權限被拒絕或限制")
            locationContinuation?.resume(returning: CLLocationCoordinate2D(latitude: 0, longitude: 0))
            locationContinuation = nil
        case .authorizedWhenInUse, .authorizedAlways:
            print("定位權限已授權")
            // 權限獲得後，如果有等待的 continuation，開始定位
            if locationContinuation != nil {
                locationManager.startUpdatingLocation()
            }
        default:
            break
        }
    }

    /// 由經緯度反查地名 
    func currentLocationName() async -> String? {
        let coord = await currentLocationCoordinate()
        
        return await withCheckedContinuation { continuation in
            let searchRequest = MKLocalSearchRequest()
            // 使用座標建立搜索區域
            let region = MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            searchRequest.region = region
            searchRequest.naturalLanguageQuery = "地標"
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                if let error = error {
                    print("反向地理編碼錯誤: \(error.localizedDescription)")
                    continuation.resume(returning: "未知位置")
                    return
                }
                
                guard let response = response,
                      let firstItem = response.mapItems.first else {
                    continuation.resume(returning: "未知位置")
                    return
                }
                
                // 使用新的 API 替代已棄用的 placemark 屬性
                let locationName: String
                if let name = firstItem.name {
                    locationName = name
                } else if let address = firstItem.address {
                    // 使用 address 屬性，它包含格式化的地址字串
                    locationName = address
                } else if #available(iOS 18.0, *), let addressRepresentation = firstItem.addressRepresentations.first {
                    // 使用 addressRepresentations（iOS 18+）
                    locationName = addressRepresentation.formattedAddress
                } else {
                    locationName = "未知位置"
                }
                continuation.resume(returning: locationName)
            }
        }
    }

    /// 由地名查經緯度
    func coordinate(for place: String) async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            let searchRequest = MKLocalSearchRequest()
            searchRequest.naturalLanguageQuery = place
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                if let error = error {
                    print("地名搜索錯誤: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let response = response,
                      let firstItem = response.mapItems.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // 使用新的 location 屬性替代已棄用的 placemark.coordinate
                let coordinate = firstItem.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                continuation.resume(returning: coordinate)
            }
        }
    }
    
    /// 使用 MapKit 的替代方法：由地名查詢並取得詳細資訊
    func searchPlaces(for query: String) async -> [MKMapItem] {
        return await withCheckedContinuation { continuation in
            let searchRequest = MKLocalSearchRequest()
            searchRequest.naturalLanguageQuery = query
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                if let error = error {
                    print("地點搜索錯誤: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let mapItems = response?.mapItems ?? []
                continuation.resume(returning: mapItems)
            }
        }
    }
}
