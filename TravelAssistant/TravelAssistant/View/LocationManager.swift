//
//  LocationManager.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation
import CoreLocation

// MARK: - 位置管理 LocationManager
/// 取得使用者當前位置名稱、經緯度、以及 geocode 查詢
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Never>?
    private let geocoder = CLGeocoder()

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
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: nil)
                return
            }
            if self.geocoder.isGeocoding {
                self.geocoder.cancelGeocode()
            }
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let name = placemarks?.first?.name {
                    continuation.resume(returning: name)
                } else {
                    continuation.resume(returning: "未知位置")
                }
            }
        }
    }

    /// 由地名查經緯度
    func coordinate(for place: String) async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: nil)
                return
            }
            if self.geocoder.isGeocoding {
                self.geocoder.cancelGeocode()
            }
            self.geocoder.geocodeAddressString(place) { placemarks, error in
                let coord = placemarks?.first?.location?.coordinate
                continuation.resume(returning: coord)
            }
        }
    }
}
