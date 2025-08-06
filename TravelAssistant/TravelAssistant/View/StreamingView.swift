import SwiftUI
import FoundationModels

struct StreamingView: View {
    @State private var inputText: String = ""
    @State private var streamingContent: String = ""
    @State private var isStreaming: Bool = false
    private let manager = LanguageModelManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.45), Color.cyan.opacity(0.35), Color.purple.opacity(0.24)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Input Card
                    VStack(spacing: 12) {
                        HStack {
                            TextField("輸入內容", text: $inputText)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                                )
                            
                            if !inputText.isEmpty {
                                Button {
                                    inputText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button {
                            let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmedText.isEmpty else { return }
                            streamingContent = ""
                            isStreaming = true
                            Task {
                                do {
                                    let stream = manager.session.streamResponse(to: trimmedText)
                                    for try await partial in stream {
                                        streamingContent += partial
                                    }
                                } catch {
                                    streamingContent = "錯誤：\(error.localizedDescription)"
                                }
                                isStreaming = false
                            }
                        } label: {
                            Text("送出")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .disabled(isStreaming || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(isStreaming || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Output ScrollView
                    ScrollView {
                        Text(streamingContent)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Streaming")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StreamingView()
}
