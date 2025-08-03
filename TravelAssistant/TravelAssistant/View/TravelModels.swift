//
//  TravelModels.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation
import FoundationModels

// MARK: - @Generable struct：TravelQuery 
/// 用於 LLM 解析 inputText，產生結構化查詢
@Generable
struct TravelQuery: Decodable {
    /// 使用者當前輸入的出發地名稱，若未指定請為空
    @Guide(description: "使用者當前輸入的出發地或起始地點名稱，若未指定請為空")
    var startLocation: String?

    /// 使用者想要前往的目的地名稱，若未指定請為空
    @Guide(description: "使用者想要前往的目的地名稱，若未指定請為空")
    var destination: String?
}

// MARK: - 統一包裝顯示資料
struct TravelResponse {
    let startLocation: String?
    let startWeather: String?
    let destination: String?
    let destinationWeather: String?
}
