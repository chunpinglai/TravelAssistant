//
//  WeatherService.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation
import CoreLocation
import WeatherKit

// MARK: - 天氣資料模型
struct WeatherData: Codable {
    let main: Main
    let weather: [Weather]
    let name: String
    
    struct Main: Codable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
        }
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
    }
}

// MARK: - 天氣查詢服務 WeatherService
/// 支援 WeatherKit 和 OpenWeatherMap API 的天氣服務
/*
這個錯誤是因為 WeatherKit 需要特殊的配置和授權才能正常工作。WeatherKit 需要：

Apple Developer Program 會員資格
正確的 App ID 配置
WeatherKit 服務授權
正確的 Bundle Identifier
讓我幫你創建一個備用的天氣服務，使用免費的 OpenWeatherMap API 作為替代方案：
*/
class WeatherService {
    private let weatherService = WeatherKit.WeatherService()
    
    // OpenWeatherMap API Key - 請替換為你自己的 API Key
    // 註冊地址: https://openweathermap.org/api
    private let openWeatherAPIKey = "6d0b0aa63c63fb18a2fcfc7250f4cf41"
    
    /// 使用 WeatherKit 取得天氣資訊（需要正確的開發者配置）
    func weatherSummaryWithWeatherKit(for coord: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let weather = try await weatherService.weather(for: location)
        let tempC = weather.currentWeather.temperature.value
        let condition = weather.currentWeather.condition.description
        let summary = "溫度：\(tempC)°C，狀態：\(condition)"
        return summary
    }
    
    /// 使用 OpenWeatherMap API 取得天氣資訊（免費替代方案）
    func weatherSummaryWithOpenWeather(for coord: CLLocationCoordinate2D) async throws -> String {
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coord.latitude)&lon=\(coord.longitude)&appid=\(openWeatherAPIKey)&units=metric&lang=zh_tw"
        
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherServiceError.networkError
        }
        
        let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
        
        let tempC = Int(weatherData.main.temp.rounded())
        let condition = weatherData.weather.first?.description ?? "未知"
        let humidity = weatherData.main.humidity
        let location = weatherData.name
        
        let summary = "\(location) - 溫度：\(tempC)°C，狀態：\(condition)，濕度：\(humidity)%"
        return summary
    }
    
    /// 主要的天氣查詢方法 - 先嘗試 WeatherKit，失敗時使用 OpenWeatherMap
    func weatherSummary(for coord: CLLocationCoordinate2D) async throws -> String {
        // 先嘗試使用 WeatherKit
        do {
            return try await weatherSummaryWithWeatherKit(for: coord)
        } catch {
            print("WeatherKit 失敗，切換至 OpenWeatherMap: \(error)")
            
            // 如果 WeatherKit 失敗，使用 OpenWeatherMap 作為備選
            do {
                return try await weatherSummaryWithOpenWeather(for: coord)
            } catch {
                // 如果兩個都失敗，返回模擬資料
                print("OpenWeatherMap 也失敗，使用模擬資料: \(error)")
                return try await getMockWeatherData(for: coord)
            }
        }
    }
    
    /// 模擬天氣資料（用於測試和開發）
    private func getMockWeatherData(for coord: CLLocationCoordinate2D) async throws -> String {
        // 模擬網路延遲
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        let mockTemperatures = [18, 22, 25, 28, 30, 26, 23]
        let mockConditions = ["晴天", "多雲", "陰天", "小雨", "大雨", "雷雨"]
        
        let temp = mockTemperatures.randomElement() ?? 25
        let condition = mockConditions.randomElement() ?? "晴天"
        
        return "模擬資料 - 溫度：\(temp)°C，狀態：\(condition)，濕度：65%"
    }
}

// MARK: - 錯誤類型
enum WeatherServiceError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "請設定 OpenWeatherMap API Key"
        case .invalidURL:
            return "無效的 URL"
        case .networkError:
            return "網路請求失敗"
        case .decodingError:
            return "資料解析失敗"
        }
    }
}
