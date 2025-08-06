//
//  MainViewModel.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import FoundationModels
import Foundation
import Combine

/// 主畫面 ViewModel
class MainViewModel: ObservableObject {
    
    /// user input
    @Published var inputText: String = ""
    
    /// 顯示在 scrollView 的內容
    @Published var displayText: String = "請輸入查詢內容，系統會自動解析您的起點與終點，並顯示位置與天氣資訊"

    private let languageModelManager = LanguageModelManager()

    // 使用者點擊送出查詢時觸發
    @MainActor
    func onQuerySubmit() async {
        displayText = "資料查詢中，請稍候..."
        do {
            displayText = try await languageModelManager.processInputText(inputText)
        } catch {
            displayText = "查詢失敗：\(error.localizedDescription)"
        }
    }
}
