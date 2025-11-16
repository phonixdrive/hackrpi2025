// NotificationManager.swift
// HealthGotchi
//
// Very small helper to schedule local "pet" reminders.

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func scheduleNudge(in seconds: TimeInterval, title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification auth error:", error)
                return
            }
            guard granted else {
                print("Notification permission not granted")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, seconds),
                                                            repeats: false)
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Notification schedule error:", error)
                }
            }
        }
    }
}
