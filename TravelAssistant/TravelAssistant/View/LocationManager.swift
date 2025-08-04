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
        // 請求定位權限
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // 注意：多次呼叫時可能會覆寫 continuation，這裡示意可依專案需求調整處理方式
        if locationContinuation != nil {
            locationContinuation?.resume(returning: locationManager.location?.coordinate ?? CLLocationCoordinate2D())
        }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
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
        locationContinuation?.resume(returning: CLLocationCoordinate2D())
        locationContinuation = nil
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
                
                // 優先使用地點名稱，如果沒有則使用地址
                let locationName = firstItem.name ?? 
                                 firstItem.placemark.locality ?? 
                                 firstItem.placemark.administrativeArea ?? 
                                 "未知位置"
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
                
                let coordinate = firstItem.placemark.coordinate
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
