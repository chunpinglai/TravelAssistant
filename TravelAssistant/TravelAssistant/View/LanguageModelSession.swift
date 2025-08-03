//
//  LanguageModelSession.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import Foundation

// MARK: - LanguageModelSession (Stub)
/// 假設 LLM 的 generate 接口
/// 實際用法依 WWDC25 FoundationModel.framework 官方 API 實作
class LanguageModelSession {
    let toolHandler: ToolCallingHandler
    init(toolHandler: ToolCallingHandler) { self.toolHandler = toolHandler }

    /// 以 LLM 產生 struct，支援 @Generable/@Guide
    func generate<T: Decodable>(from input: String, as: T.Type) async throws -> T {
        // 這裡示意：你可以直接呼叫 FoundationModel 的 generate function
        // 真實專案請依官方 API 使用
        // 範例：return try await foundationModel.generate(T.self, from: input, tools: ...)

        // 模擬解析輸入
        // "我想去台北101" -> destination: "台北101"
        if T.self == TravelQuery.self {
            let text = input.lowercased()
            let dest: String? = text.contains("台北101") ? "台北101" : nil
            let query = TravelQuery(startLocation: nil, destination: dest)
            return query as! T
        }
        throw NSError(domain: "LLM", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法解析輸入"])
    }
}
