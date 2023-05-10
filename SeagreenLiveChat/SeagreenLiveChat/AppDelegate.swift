//
//  AppDelegate.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 09/05/2023.
//

import Foundation

import UIKit
import UserNotifications
import AgoraChat
import AgoraRtcKit
import PushKit
import Firebase

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = .white
        self.window!.makeKeyAndVisible()
        self.registerAPNS()
        self.registerNotifications()

        if let agoraUid = UserDefaults.standard.object(forKey: "user_agora_uid") as? UInt {
          //  AgoraChatCallKitManager.shared.update(agoraUid: agoraUid)
        }
        voipRegistration()
        return true
    }

    func voipRegistration() {
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }


    private func registerAPNS() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    private func registerNotifications() {
        AgoraChatClient.shared().add(self, delegateQueue: nil)
    }
}

extension AppDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        AgoraChatClient.shared().applicationDidEnterBackground(application)
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        AgoraChatClient.shared().applicationWillEnterForeground(application)
    }
}

extension AppDelegate: AgoraChatClientDelegate {
    func autoLoginDidCompleteWithError(_ error: AgoraChatError?) {
//        if error != nil {
//            self.loadLoginPage()
//        }
 //   }

//    func tokenWillExpire(_ errorCode: AgoraChatErrorCode) {
//        if errorCode == .tokeWillExpire, let username = self.username, let password = UserDefaults.standard.object(forKey: "user_pwd") as? String {
//            AgoraChatHttpRequest.shared.loginToApperServer(username: username, password: password) { statusCode, response in
//                var alertStr: String?
//                if let response = response, response.count > 0, let responsedict = try? JSONSerialization.jsonObject(with: response) as? [String: Any] {
//                    if let token = responsedict["accessToken"] as? String, token.count > 0 {
//                        if AgoraChatClient.shared().renewToken(token) != nil {
//                            alertStr = "Renew token failed".localized
//                        }
//                    } else {
//                        alertStr = "login analysis token failure".localized
//                    }
//                } else {
//                    alertStr = "Login failed".localized
//                }
//                if let alertStr = alertStr {
//                    self.showHint(alertStr)
//                }
//            }
//        }
    }

    func tokenDidExpire(_ errorCode: AgoraChatErrorCode) {
//        if errorCode == .tokenExpire || errorCode.rawValue == 401 {
//            let finishClosure: (_ username: String, _ error: AgoraChatError?) -> Void  = { username, error in
//                let showText: String?
//                switch error?.code {
//                case .serverNotReachable:
//                    showText = "Connect to the server failed!".localized
//                case .networkUnavailable:
//                    showText = "No network connection!".localized
//                case .serverTimeout:
//                    showText = "Connect to the server timed out!".localized
//                default:
//                    showText = nil
//                }
//                guard let showText = showText else {
//                    return
//                }
//                let vc = UIAlertController(title: nil, message: showText, preferredStyle: .alert)
//                vc.addAction(UIAlertAction(title: LocalizedString.Ok, style: .default))
//                UIWindow.keyWindow?.rootViewController?.present(vc, animated: true)
//            }
//
//            guard let password = UserDefaults.standard.object(forKey: "user_pwd") as? String, password.count > 0, let username = self.username, username.count > 0 else {
//                return
//            }

//            AgoraChatHttpRequest.shared.loginToApperServer(username: username, password: password) { statusCode, responseData in
//                DispatchQueue.main.async {
//                    var alertStr: String?
//                    if let responseData = responseData {
//                        let responsedict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]
//                        let token = responsedict?["accessToken"] as? String
//                        let loginName = responsedict?["chatUserName"] as? String
//                        if let token = token, token.count > 0, let loginName = loginName {
//                            AgoraChatClient.shared().login(withUsername: loginName.lowercased(), agoraToken: token) { username, error in
//                                finishClosure(username, error)
//                            }
//                            return
//                        } else {
//                            alertStr = "Login analysis token failure".localized
//                        }
//                    } else {
//                        alertStr = "Login failed".localized
//                    }
//                    if let alertStr = alertStr {
//                        let vc = UIAlertController(title: nil, message: alertStr, preferredStyle: .alert)
//                        UIWindow.keyWindow?.rootViewController?.present(vc, animated: true)
//                    }
//                }
//            }
 //       }
//    }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DispatchQueue.global().async {
         //   AgoraChatClient.shared().bindDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AgoraChatClient.shared().application(application, didReceiveRemoteNotification: userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        AgoraChatClient.shared().application(UIApplication.shared, didReceiveRemoteNotification: notification.request.content.userInfo)
    }
}

extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) async {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        let content = UNMutableNotificationContent()


        let userInfo: [String: Any] = [
            "Hello": "Test",
            "Push": "info"
        ]
        content.sound = UNNotificationSound.default
        content.body = "Push kit test"
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: "push kit test 2", content: content, trigger: trigger)
        try! await UNUserNotificationCenter.current().add(request)
    }


    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("pushCredentials")
        AgoraChatClient.shared().bindDeviceToken(pushCredentials.token)

        //dump(pushCredentials.token)
    }


}
