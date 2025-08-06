//
//  WeatherTool.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/4.
//

import FoundationModels
import CoreLocation

/// 從輸入文字中取得經緯度，call api 取得天氣
struct WeatherTool: Tool {
    
    let name = "getWeather"
    let description = """
    Look up the current weather for a given coordinate (latitude/longitude) \
    or a human-readable place name. Returns a concise, structured summary.
    """
    
    private let weatherService = WeatherService()

    @Generable
    struct Arguments {
        @Guide(description: "Decimal latitude of the point, e.g. 25.0330.")
        var latitude: Double?

        @Guide(description: "Decimal longitude of the point, e.g. 121.5654.")
        var longitude: Double?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        
        let weather = try? await weatherService.weatherSummary(for: CLLocationCoordinate2D(latitude: arguments.latitude ?? 0.0, longitude: arguments.longitude ?? 0.0))
        return ToolOutput("\(weather)")
    }
}
