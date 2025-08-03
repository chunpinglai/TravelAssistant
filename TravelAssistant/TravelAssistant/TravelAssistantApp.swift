//
//  TravelAssistantApp.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import SwiftUI
import FoundationModels // WWDC25 新增的自然語言模型套件
import CoreLocation
import WeatherKit

@main
struct TravelAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

