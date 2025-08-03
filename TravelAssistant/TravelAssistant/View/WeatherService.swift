//
//  WeatherService.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation
import CoreLocation
import WeatherKit

// MARK: - 天氣查詢服務 WeatherService
/// 以 WeatherKit 取得指定經緯度的天氣摘要
class WeatherService {
    private let weatherService = WeatherKit.WeatherService()

    func weatherSummary(for coord: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let weather = try await weatherService.weather(for: location)
        let tempC = weather.currentWeather.temperature.value
        let condition = weather.currentWeather.condition.description
        let summary = "溫度：\(tempC)°C，狀態：\(condition)"
        return summary
    }
}
