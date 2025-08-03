//
//  MainViewModel.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import FoundationModels // WWDC25 新增的自然語言模型套件
import Foundation
import Combine

// MARK: - 主畫面 ViewModel
class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var displayText: String = "請輸入查詢內容，系統會自動解析您的起點與終點，並顯示位置與天氣資訊"

    private let languageModelManager = LanguageModelManager()

    // 使用者點擊送出查詢時觸發
    @MainActor
    func onQuerySubmit() async {
        displayText = "資料查詢中，請稍候..."
        do {
            let result = try await languageModelManager.processTravelQuery(inputText: inputText)
            // 組合顯示內容
            var output = ""
            if let start = result.startLocation {
                output += "【起始點位置】：\(start)\n"
            }
            if let startWeather = result.startWeather {
                output += "【起始點天氣】：\(startWeather)\n"
            }
            if let dest = result.destination {
                output += "【終點位置】：\(dest)\n"
            }
            if let destWeather = result.destinationWeather {
                output += "【終點天氣】：\(destWeather)\n"
            }
            displayText = output.isEmpty ? "查無結果，請確認輸入內容" : output
        } catch {
            displayText = "查詢失敗：\(error.localizedDescription)"
        }
    }
}
