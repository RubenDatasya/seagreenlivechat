//
//  AppDelegate.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

import UIKit
import UserNotifications
import AgoraRtcKit
import PushKit
import FirebaseAuth
import Firebase
import CallKit
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var voipRegistry: PKPushRegistry!
    let callManager = CallManager()
    var providerDelegate: ProviderDelegate!

    static var shared: AppDelegate!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = .white
        self.window!.makeKeyAndVisible()
        self.registerAPNS()
        self.voipRegistration()
        AppDelegate.shared = self
        LiveChat.setMode(isDemoMode: true)
        providerDelegate = ProviderDelegate(callManager: callManager)
        return true
    }

    private func authentificate() async throws -> String {
        let result = try await Auth.auth().signInAnonymously()
        let uid =  result.user.uid
        UserDefaults.saveFuid(uid)
        return uid
    }

    private func voipRegistration() {
        let queue = DispatchQueue.global()
        voipRegistry = PKPushRegistry(queue: queue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }


    private func registerAPNS() {
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        dump(notification)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError \(error)")

    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("didRegisterForRemoteNotificationsWithDeviceToken")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {}

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        dump(response)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        handlePushPayload(payload.dictionaryPayload)
        completion()
    }


    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("PKPushRegistryDelegate", "didUpdate with token \(token)")
        Task {
            let uid = try await authentificate()
            let userApi = UserApi()
            let tokenApi =  PushTokenApi()
            let _ = try await tokenApi.create(.init(id:token,ownedby: uid, pushToken: token, deviceOS: "iOS"))
            let names =  ["Pikachu","Gengar", "Mario"]
            let name = names.randomElement()!
            let user = try await userApi.create(.init(id: uid, name: name, pushToken: token))
            print("didUpdate", user)
        }
    }


    func handlePushPayload(_ payload: [AnyHashable : Any]) {
        let callState = payload.toCallStatus()
        switch callState {
        case .incoming:
            providerDelegate.reportIncomingCall(callData: CallData.toCallData(payload)) { error in
                Logger.severe("handlePushPayload, incoming",error: error)
            }
        case .accepted:
            AgoraRtc.shared.toggleAudio(isOn: true)
            Logger.debug("Call accepted \(payload)")
        case .notAnswered:
            callManager.end()
        case .ended:
            callManager.end()
        }
    }
}
