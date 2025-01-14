//
// NotificationsManagerHelper.swift
//
// Siskin IM
// Copyright (C) 2019 "Tigase, Inc." <office@tigase.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. Look for COPYING file in the top folder.
// If not, see https://www.gnu.org/licenses/.
//

import Foundation
import TigaseSwift
import UserNotifications
import os

public struct ConversationNotificationDetails {
    public let name: String;
    public let notifications: ConversationNotification;
    public let type: ConversationType;
    public let nick: String?;
    
    public init(name: String, notifications: ConversationNotification, type: ConversationType, nick: String?) {
        self.name = name;
        self.notifications = notifications;
        self.type = type;
        self.nick = nick;
    }
}

public class NotificationsManagerHelper {
    
    public static func unreadChatsThreadIds(completionHandler: @escaping (Set<String>)->Void) {
        unreadThreadIds(for: [.MESSAGE], completionHandler: completionHandler);
    }
    
    public static func unreadThreadIds(for categories: [NotificationCategory], completionHandler: @escaping (Set<String>)->Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            let unreadChats = Set(notifications.filter({(notification) in
                let category = NotificationCategory.from(identifier: notification.request.content.categoryIdentifier);
                return categories.contains(category);
            }).map({ (notification) in
                return notification.request.content.threadIdentifier;
            }));
            
            completionHandler(unreadChats);
        }
    }
    
    public static func generateMessageUID(account: BareJID, sender: BareJID?, body: String?) -> String? {
        if let sender = sender, let body = body {
            return Digest.sha256.digest(toHex: "\(account)|\(sender)|\(body)".data(using: .utf8));
        }
        return nil;
    }
        
    public static func prepareNewMessageNotification(content: UNMutableNotificationContent, account: BareJID, sender jid: BareJID?, nickname: String?, body msg: String?, provider: NotificationManagerProvider, completionHandler: @escaping (UNMutableNotificationContent)->Void) {
        let timestamp = Date();
        content.sound = .default;        
        content.categoryIdentifier = NotificationCategory.MESSAGE.rawValue;
        if let sender = jid, let body = msg {
            let uid = generateMessageUID(account: account, sender: sender, body: body)!;
            content.threadIdentifier = "account=\(account.stringValue)|sender=\(sender.stringValue)";
            provider.conversationNotificationDetails(for: account, with: sender, completionHandler: { details in
                os_log("%{public}@", log: OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SiskinPush"), "Found: name: \(details.name), type: \(String(describing: details.type.rawValue))");

                switch details.type {
                case .chat:
                    content.title = details.name;
                    if body.starts(with: "/me ") {
                        content.body = String(body.dropFirst(4));
                    } else {
                        content.body = body;
                    }
                case .channel, .room:
                    content.title = details.name
                    if body.starts(with: "/me ") {
                        if let nickname = nickname {
                            content.body = "\(nickname) \(body.dropFirst(4))";
                        } else {
                            content.body = String(body.dropFirst(4));
                        }
                    } else {
                        content.body = body;
                        if let nickname = nickname {
                            content.subtitle = nickname;
                        }
                    }
                }
                content.userInfo = ["account": account.stringValue, "sender": sender.stringValue, "uid": uid, "timestamp": timestamp];
                provider.countBadge(withThreadId: content.threadIdentifier, completionHandler: { count in
                    content.badge = count as NSNumber;
                    completionHandler(content);
                });
            })
        } else {
            content.threadIdentifier = "account=\(account.stringValue)";
            content.body = NSLocalizedString("New message!", comment: "new message without content notification");
            provider.countBadge(withThreadId: content.threadIdentifier, completionHandler: { count in
                content.badge = count as NSNumber;
                completionHandler(content);
            });
        }
    }
}

public protocol NotificationManagerProvider {
    
    func conversationNotificationDetails(for account: BareJID, with jid: BareJID, completionHandler: @escaping (ConversationNotificationDetails)->Void);
 
    func countBadge(withThreadId: String?, completionHandler: @escaping (Int)->Void);
    
    func shouldShowNotification(account: BareJID, sender: BareJID?, body: String?, completionHandler: @escaping (Bool)->Void);
    
}

public class Payload: Decodable {
    public var unread: Int;
    public var sender: JID;
    public var type: Kind;
    public var nickname: String?;
    public var message: String?;
    public var sid: String?;
    public var media: [String]?;
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self);
        unread = try container.decode(Int.self, forKey: .unread);
        sender = try container.decode(JID.self, forKey: .sender);
        type = Kind(rawValue: (try container.decodeIfPresent(String.self, forKey: .type)) ?? Kind.unknown.rawValue)!;
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname);
        message = try container.decodeIfPresent(String.self, forKey: .message);
        sid = try container.decodeIfPresent(String.self, forKey: .sid)
        media = try container.decodeIfPresent([String].self, forKey: .media);
        // -- and so on...
    }
    
    public enum Kind: String {
        case unknown
        case groupchat
        case chat
        case call
    }
    
    public enum CodingKeys: String, CodingKey {
        case unread
        case sender
        case type
        case nickname
        case message
        case sid
        case media
    }
}
