//
//  LanguageModelManager.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import FoundationModels
import Combine
import CoreLocation
import WeatherKit

// MARK: - LanguageModelManager
/// 管理 LLM session 與 Tool Calling
class LanguageModelManager {
    // 建立 LLM session
    private let session: LanguageModelSession

    // 位置、天氣服務
    private let locationManager = LocationManager()
    private let weatherService = WeatherService()

    // Tool Calling handler
    private let toolHandler: ToolCallingHandler

    init() {
        // 註冊 Tool Calling 工具
        toolHandler = ToolCallingHandler(locationManager: locationManager, weatherService: weatherService)
        session = LanguageModelSession(toolHandler: toolHandler)
    }

    /// 主流程：處理一筆查詢，回傳結構化結果
    func processTravelQuery(inputText: String) async throws -> TravelResponse {
        // 調用 LanguageModelSession，直接用 @Generable struct 解析 inputText
        let queryStruct = try await session.generate(
            from: inputText,
            as: TravelQuery.self
        )

        // 取得起點位置（如果無明確指定就用 GPS），並查天氣
        var startLocation: String?
        if let s = queryStruct.startLocation, !s.isEmpty {
            startLocation = s
        } else {
            startLocation = await locationManager.currentLocationName()
        }
        let startWeather = try? await weatherService.weatherSummary(for: await locationManager.currentLocationCoordinate())

        // 若有目的地，解析並查天氣
        var destWeather: String? = nil
        var destLocationName: String? = nil
        if let destination = queryStruct.destination, !destination.isEmpty {
            // 以 LLM 解析到的目的地地名進行 geocode
            if let coord = await locationManager.coordinate(for: destination) {
                destLocationName = destination
                destWeather = try? await weatherService.weatherSummary(for: coord)
            }
        }

        // 包裝結果
        return TravelResponse(
            startLocation: startLocation,
            startWeather: startWeather,
            destination: destLocationName,
            destinationWeather: destWeather
        )
    }
}
