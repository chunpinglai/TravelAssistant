//
//  TravelModels.swift
//  TravelAssistant
//
//  Created by Abby on 2025/8/3.
//

import FoundationModels

@Generable
struct TravelResponse {
    /// 使用者當前輸入的出發地名稱，若未指定請為空
    //    @Guide(description: "使用者當前輸入的出發地或起始地點名稱，若未指定請為空")
    @Guide(description: "The name of the departure or starting location currently entered by the user; leave empty if not specified.")
    let startLocation: String?
    @Guide(description: "The weather of the departure or starting location currently entered by the user; leave empty if not specified.")
    let startWeather: String?
    /// 使用者想要前往的目的地名稱，若未指定請為空
    //    @Guide(description: "使用者想要前往的目的地名稱，若未指定請為空")
    @Guide(description: "The name of the destination the user wants to go to; leave empty if not specified.")
    let destination: String?
    @Guide(description: "The weather of the destination the user wants to go to; leave empty if not specified.")
    let destinationWeather: String?
}
