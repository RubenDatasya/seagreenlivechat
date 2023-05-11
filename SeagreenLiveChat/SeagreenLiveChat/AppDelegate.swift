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
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = .white
        self.window!.makeKeyAndVisible()
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled =  true
        self.registerAPNS()
        self.voipRegistration()
        LiveChat.setMode(isDemoMode: true)
        return true
    }

    private func authentificate() async throws -> String {
       let result = try await Auth.auth().signInAnonymously()
       let uid =  result.user.uid
        return uid
    }

    private func voipRegistration() {
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
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

extension AppDelegate {

    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
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
        Task {
            let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            Messaging.messaging().apnsToken = deviceToken
            let uid = try await authentificate()
            let userApi = UserApi()
            let names =  ["Pikachu","Gengar", "Mario"]
            let name = names.randomElement()!
            let user = try await userApi.create(.init(id: uid, name: name, pushToken: token))
            print("didUpdate", user)
        }

    }



    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification")
        let conversationtype = userInfo["conversationType"] as! String
        let caller = userInfo["caller"] as! String
        let channelName = userInfo["channelName"] as! String
        LiveChat.shared.showIncomingCall(of: caller, withData: userInfo)
        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        dump(response)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) async {}


    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {}
}

extension AppDelegate : MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {}
}
