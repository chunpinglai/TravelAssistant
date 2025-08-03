//
//  MainView.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import SwiftUI

// MARK: - 主畫面 MainView
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // 使用者輸入框，綁定到 inputText
            TextField("請輸入想查詢的地點或行程，例如：我想去台北101", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .padding()

            // 顯示 LLM 回傳資訊與 Tool Calling 結果
            ScrollView {
                Text(viewModel.displayText)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding([.leading, .trailing])

            // 送出查詢按鈕
            Button {
                Task { await viewModel.onQuerySubmit() }
            } label: {
                Text("送出查詢")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding([.leading, .trailing])
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .navigationTitle("旅行助理")
        .padding(.top, 40)
    }
}

#Preview {
    MainView()
}
