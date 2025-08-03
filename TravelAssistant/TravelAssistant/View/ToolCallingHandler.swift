//
//  ToolCallingHandler.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation

// MARK: - ToolCallingHandler
/// 註冊與管理可被 LLM 呼叫的工具
class ToolCallingHandler {
    private let locationManager: LocationManager
    private let weatherService: WeatherService

    init(locationManager: LocationManager, weatherService: WeatherService) {
        self.locationManager = locationManager
        self.weatherService = weatherService
    }

    // LLM Tool Calling 可支援如「取得現在位置」、「查詢天氣」等工具
    // 若要支援多種 Tool，可設計更通用的 Registry 機制
}
