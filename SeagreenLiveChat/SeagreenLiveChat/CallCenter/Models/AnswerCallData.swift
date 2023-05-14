//
//  AnswerCallData.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 14/05/2023.
//

import Foundation

struct AnswerCallData {
    var bundleId  : String
    var channel   : String
    var callerid  : String
    var callState : CallState = .answered
}
