//
// AvatarStore.swift
//
// Siskin IM
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
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

import UIKit
import TigaseSwift

open class AvatarStore {
    
    let avatarCacheUrl: URL;
    let dbConnection: DBConnection;
    
    let dispatcher: QueueDispatcher;
    
    fileprivate lazy var findAvatarHashForJidStmt: DBStatement! = try? self.dbConnection.prepareStatement("SELECT type, hash FROM avatars_cache WHERE jid = :jid AND account = :account");
    fileprivate lazy var deleteAvatarHashForJidStmt: DBStatement! = try? self.dbConnection.prepareStatement("DELETE FROM avatars_cache WHERE jid = :jid AND account = :account AND (:type IS NULL OR type = :type)");
    fileprivate lazy var insertAvatarHashForJidStmt: DBStatement! = try? self.dbConnection.prepareStatement("INSERT INTO avatars_cache (jid, account, hash, type) VALUES (:jid,:account,:hash,:type)");
    
    public init(dbConnection: DBConnection) {
        self.dispatcher = QueueDispatcher(queue: DispatchQueue(label: "AvatarStore", attributes: .concurrent), queueTag: DispatchSpecificKey<DispatchQueue?>());
        self.dbConnection = dbConnection;
        
        avatarCacheUrl = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("avatars", isDirectory: true);
    }
    
    open func removeAvatar(hash: String) {
        dispatcher.sync(flags: .barrier) {
            try? FileManager.default.removeItem(at: avatarCacheUrl.appendingPathComponent(hash));
        }
    }
    
    open func storeAvatar(data: Data, hash: String) {
        dispatcher.sync(flags: .barrier) {
            if !FileManager.default.fileExists(atPath: avatarCacheUrl.path) {
                try? FileManager.default.createDirectory(at: avatarCacheUrl, withIntermediateDirectories: true, attributes: nil);
            }
            
            _ = FileManager.default.createFile(atPath: avatarCacheUrl.appendingPathComponent(hash).path, contents: data, attributes: nil);
        }
    }
    
    open func getAvatarHashes(for jid: BareJID, on account: BareJID) -> [AvatarType:String] {
        let params = ["account": account, "jid": jid] as [String : Any?];
        var hashes: [AvatarType:String] = [:];
        try! self.findAvatarHashForJidStmt.query(params, forEach: { (cursor) -> Void in
            guard let typeRawValue: String = cursor["type"], let hash: String = cursor["hash"] else {
                return;
            }
            guard let avatarType = AvatarType(rawValue: typeRawValue) else {
                return;
            }
            hashes[avatarType] = hash;
        });
        return hashes;
    }
    
    open func getAvatar(hash: String) -> UIImage? {
        return UIImage(contentsOfFile: avatarCacheUrl.appendingPathComponent(hash).path);
    }
    
    open func isAvatarAvailable(hash: String) -> Bool {
        return FileManager.default.fileExists(atPath: avatarCacheUrl.appendingPathComponent(hash).path);
    }
    
    open func updateAvatar(hash: String?, type: AvatarType, for jid: BareJID, on account: BareJID, onFinish: @escaping ()->Void) {
        dispatcher.async(flags: .barrier) {
            let oldHash = self.getAvatarHashes(for: jid, on: account)[type];
            guard oldHash != hash else {
                return;
            }
        
            if oldHash != nil {
                DispatchQueue.global(qos: .background).async {
                    self.removeAvatar(hash: oldHash!);
                }
            }
        
            var params = ["account": account, "jid": jid, "type": type.rawValue] as [String : Any?];
            _ = try! self.deleteAvatarHashForJidStmt.update(params);
    
            guard hash != nil else {
                return;
            }
        
            params["hash"] = hash!;
            _ = try! self.insertAvatarHashForJidStmt.insert(params);
            
            DispatchQueue.global(qos: .background).async {
                onFinish();
            }
        }
    }
}

public enum AvatarType: String {
    case vcardTemp
    case pepUserAvatar
    
    public static let ALL = [AvatarType.pepUserAvatar, AvatarType.vcardTemp];
}