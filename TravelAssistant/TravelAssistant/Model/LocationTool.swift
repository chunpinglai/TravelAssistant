//
//  LocationTool.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/4.
//

import CoreLocation
import FoundationModels

/// 從輸入文字中取得起始點跟終點，轉換成地點、經緯度
struct LocationTool: Tool {
    
    let name = "get startLocation and destination"
    let description = """
    Look up current location (latitude/longitude) 
    or a human-readable place name. Returns latitude longitude.
    """
    
    /// 取得經緯度及地點用
    private let locationManager = LocationManager()

    @Generable
    struct Arguments {
        //    @Guide(description: "使用者當前輸入的出發地或起始地點名稱，若未指定請為空")
        @Guide(description: "The name of the departure or starting location currently entered by the user; leave empty if not specified.")
        var startLocation: String?
        
        /// 使用者想要前往的目的地名稱，若未指定請為空
        //    @Guide(description: "使用者想要前往的目的地名稱，若未指定請為空")
        @Guide(description: "The name of the destination the user wants to go to; leave empty if not specified.")
        var destination: String?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        
        // 輸出文字
        var result: String = ""
        if let startLocation = arguments.startLocation, !startLocation.isEmpty {
            // 有起始點，轉換成經緯度
            let coordinateResult = await locationManager.coordinate(for: startLocation)
            result += "Start location coordinate: \(coordinateResult?.latitude ?? 0.0), \(coordinateResult?.longitude ?? 0.0)"
        }
        else {
            // 無起始點，取使用者位置，轉換成經緯度
            let coordinateResult = await locationManager.currentLocationCoordinate()
            let nameResult = await locationManager.currentLocationName()
            result += "Start location from:\(nameResult ?? ""). coordinate: \(coordinateResult.latitude), \(coordinateResult.longitude)"
        }
        
        if let destination = arguments.destination, !destination.isEmpty {
            // 有終點，轉換成經緯度
            let coordinateResult = await locationManager.coordinate(for: destination)
            result += "\nDestination location coordinate: \(coordinateResult?.latitude ?? 0.0), \(coordinateResult?.longitude ?? 0.0)"
        }
        return ToolOutput("\(result)")
    }
}
