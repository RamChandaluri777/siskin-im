//
// NotificationEncryptionKeys.swift
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

public class NotificationEncryptionKeys {
    
    private static let storage = UserDefaults(suiteName: "group.Sigmavani.notifications")!;
    
    public static func key(for account: BareJID) -> Data? {
        storage.data(forKey: account.stringValue)
    }
    
    public static func set(key: Data?, for account: BareJID) {
        storage.setValue(key, forKey: account.stringValue);
    }
}



