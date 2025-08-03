//
//  MainViewModel.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import FoundationModels // WWDC25 新增的自然語言模型套件
import CoreLocation
import WeatherKit
import Combine
import MapKit

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

// MARK: - LanguageModelManager
/// 管理 LLM session 與 Tool Calling
class LanguageModelManager {
    // 建立 LLM session
    private let session: LanguageModelSession

    // 位置、天氣服務
    private let locationManager = LocationManager()
    private let weatherService = WeatherService()

    // Tool Calling handler
    private let toolHandler: ToolCallingHandler

    init() {
        // 註冊 Tool Calling 工具
        toolHandler = ToolCallingHandler(locationManager: locationManager, weatherService: weatherService)
        session = LanguageModelSession(toolHandler: toolHandler)
    }

    /// 主流程：處理一筆查詢，回傳結構化結果
    func processTravelQuery(inputText: String) async throws -> TravelResponse {
        // 調用 LanguageModelSession，直接用 @Generable struct 解析 inputText
        // (LLM 會自動依 @Guide 指示，從 inputText 判斷出發地/目的地)
        let queryStruct = try await session.generate(
            from: inputText,
            as: TravelQuery.self
        )

        // 取得起點位置（如果無明確指定就用 GPS），並查天氣
        var startLocation: String?
        if let s = queryStruct.startLocation, !s.isEmpty {
            startLocation = s
        } else {
            startLocation = await locationManager.currentLocationName()
        }
        let startWeather = try? await weatherService.weatherSummary(for: await locationManager.currentLocationCoordinate())

        // 若有目的地，解析並查天氣
        var destWeather: String? = nil
        var destLocationName: String? = nil
        if let destination = queryStruct.destination, !destination.isEmpty {
            // 以 LLM 解析到的目的地地名進行 geocode
            if let coord = await locationManager.coordinate(for: destination) {
                destLocationName = destination
                destWeather = try? await weatherService.weatherSummary(for: coord)
            }
        }

        // 包裝結果
        return TravelResponse(
            startLocation: startLocation,
            startWeather: startWeather,
            destination: destLocationName,
            destinationWeather: destWeather
        )
    }
}

// MARK: - @Generable struct：TravelQuery
/// 用於 LLM 解析 inputText，產生結構化查詢
@Generable
struct TravelQuery: Decodable {
    /// 使用者當前輸入的出發地名稱，若未指定請為空
    @Guide(description: "使用者當前輸入的出發地名稱，若未指定請為空")
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

// MARK: - 位置管理 LocationManager
/// 取得使用者當前位置名稱、經緯度、以及 geocode 查詢
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Never>?
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// 取得目前經緯度 (簡化版本，實務建議完善權限處理與多次調用管理)
    func currentLocationCoordinate() async -> CLLocationCoordinate2D {
        // 請求定位權限
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // 注意：多次呼叫時可能會覆寫 continuation，這裡示意可依專案需求調整處理方式
        if locationContinuation != nil {
            locationContinuation?.resume(returning: locationManager.location?.coordinate ?? CLLocationCoordinate2D())
        }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
        }
    }

    /// CLLocationManagerDelegate 回調
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let continuation = locationContinuation else { return }
        if let loc = locations.first {
            locationManager.stopUpdatingLocation()
            continuation.resume(returning: loc.coordinate)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: CLLocationCoordinate2D())
        locationContinuation = nil
    }

    /// 由經緯度反查地名
    func currentLocationName() async -> String? {
        let coord = await currentLocationCoordinate()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: nil)
                return
            }
            if self.geocoder.isGeocoding {
                self.geocoder.cancelGeocode()
            }
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let name = placemarks?.first?.name {
                    continuation.resume(returning: name)
                } else {
                    continuation.resume(returning: "未知位置")
                }
            }
        }
    }

    /// 由地名查經緯度
    func coordinate(for place: String) async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: nil)
                return
            }
            if self.geocoder.isGeocoding {
                self.geocoder.cancelGeocode()
            }
            self.geocoder.geocodeAddressString(place) { placemarks, error in
                let coord = placemarks?.first?.location?.coordinate
                continuation.resume(returning: coord)
            }
        }
    }
}

// MARK: - 天氣查詢服務 WeatherService
/// 以 WeatherKit 取得指定經緯度的天氣摘要
class WeatherService {
    private let service = WeatherServiceKit()

    func weatherSummary(for coord: CLLocationCoordinate2D) async throws -> String {
        let weather = try await service.weather(for: coord)
        // 取出摘要
        let summary = "溫度：\(weather.temperature)°C，狀態：\(weather.condition)"
        return summary
    }
}

/// 假設的 WeatherKit 封裝（實際專案需引用 WeatherKit API 或自訂實作）
class WeatherServiceKit {
    // 模擬取得天氣（真實專案需整合 WeatherKit 或第三方 API）
    func weather(for coord: CLLocationCoordinate2D) async throws -> (temperature: Int, condition: String) {
        // 這裡僅示意，實際請串接 Apple WeatherKit API
        return (temperature: 28, condition: "晴時多雲")
    }
}

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

