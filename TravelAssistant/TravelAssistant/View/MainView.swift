//
//  MainView.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import SwiftUI

/// 主畫面
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        ZStack {
            // liquid 背景
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.45), Color.cyan.opacity(0.35), Color.purple.opacity(0.24)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // 輸入框
                        TextField("example: I want to go to Taipei 101.", text: $viewModel.inputText)
                            .padding(10)
                            .background(Color.white.opacity(0.85))
                            .cornerRadius(16)
                            .shadow(color: Color.white.opacity(0.18), radius: 2, x: 0, y: 1)
                        // clearButton
                        // (UIKit UITextField() clearButtonMode = .whileEditing 的功能)
                        if !viewModel.inputText.isEmpty {
                            Button(action: { viewModel.inputText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    // 送出查詢 按鈕
                    Button {
                        Task { await viewModel.onQuerySubmit() }
                    } label: {
                        Text("Send")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.blue.opacity(0.23), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 4)
                    .opacity(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 6)
                .padding([.leading, .trailing])
                // 顯示 response 內容
                ScrollView {
                    Text(viewModel.displayText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 6)
                .padding([.leading, .trailing])
            }
            .navigationTitle("旅行助理")
            .padding(.top, 40)
        }
    }
}

#Preview {
    MainView()
}

