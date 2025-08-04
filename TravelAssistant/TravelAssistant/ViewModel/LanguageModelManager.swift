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

    init() {
        // 註冊 Tool Calling 工具
        session = LanguageModelSession(tools: [WeatherTool(),
                                               LocationTool()],
                                       instructions: """
        The following tools are available:\
        1. LocationTool (converts a place name to coordinates)\
        2. WeatherTool (retrieves real-time weather for a specified latitude/longitude)\
        Please first call `LocationTool`, then call `WeatherTool` to get the weather at the starting point.\
        If the user's input mentions a destination, please call `LocationTool` and then `WeatherTool` to obtain the destination's weather.\
        Finally, reply in Chinese with a paragraph including: starting location, starting weather, destination location, and destination weather.
        """)
        /*
         以下工具可以使用：\
         1. LocationTool (將地點名稱轉成座標)\
         2. WeatherTool (取得指定緯/經度的即時天氣)\
         請先呼叫 `LocationTool`，接著呼叫 `WeatherTool` 負責取得起始點天氣。\
         若使用者輸入文字中提到目的地名稱，請呼叫 `LocationTool` 再呼叫 `WeatherTool` 取得終點天氣。\
         最後以中文回覆一段文字，格式包含：起始點位置、起始點天氣，終點位置、終點天氣。
         */
    }

    /// 主流程：處理一筆查詢，回傳結構化結果
    func processTravelQuery(inputText: String) async throws -> String {
        // 調用 LanguageModelSession，直接用 @Generable struct 解析 inputText
        do {
//            let response = try await session.respond(to: inputText, generating: TravelResponse.self)
            let response = try await session.respond(to: inputText)
            return response.content
        } catch {
            print("Text generation failed: \(error)")
            throw error
        }
    }
}
