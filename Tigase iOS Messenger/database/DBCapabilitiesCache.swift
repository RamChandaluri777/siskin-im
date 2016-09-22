//
// DBCapabilitiesCache.swift
//
// Tigase iOS Messenger
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. Look for COPYING file in the top folder.
// If not, see http://www.gnu.org/licenses/.
//

import Foundation
import TigaseSwift

/**
 Implementation of `CapabilitiesCache` which persists cached data in database 
 for reuse during next connection or after application restart.
 */
open class DBCapabilitiesCache: CapabilitiesCache {
    
    let dbConnection: DBConnection;
    
    fileprivate lazy var getFeatureStmt: DBStatement! = try? self.dbConnection.prepareStatement("SELECT feature FROM caps_features WHERE node = :node");
    fileprivate lazy var getIdentityStmt: DBStatement! = try? self.dbConnection.prepareStatement("SELECT name, category, type FROM caps_identities WHERE node = :node");
    fileprivate lazy var getNodesWithFeatureStmt: DBStatement! = try? self.dbConnection.prepareStatement("SELECT node FROM caps_features WHERE feature = :features");
    fileprivate lazy var insertFeatureStmt: DBStatement! = try? self.dbConnection.prepareStatement("INSERT INTO caps_features (node, feature) VALUES (:node, :feature)");
    fileprivate lazy var insertIdentityStmt: DBStatement! = try? self.dbConnection.prepareStatement("INSERT INTO caps_identities (node, name, category, type) VALUES (:node, :name, :category, :type)");
    fileprivate lazy var nodeIsCached: DBStatement! = try? self.dbConnection.prepareStatement("SELECT count(feature) FROM caps_features WHERE node = :node");
    
    
    fileprivate var features = [String: [String]]();
    fileprivate var identities: [String: DiscoveryModule.Identity] = [:];
    
    public init(dbConnection: DBConnection) {
        self.dbConnection = dbConnection;
    }
    
    open func getFeatures(for node: String) -> [String]? {
        return dbConnection.dispatch_sync_with_result_local_queue() {
            var result = [String]();
            try! self.getFeatureStmt.query(node, forEachRow: {(cursor)->Void in
                result.append(cursor["feature"]!);
            });
            return result;
        }
    }
    
    open func getIdentity(for node: String) -> DiscoveryModule.Identity? {
        return dbConnection.dispatch_sync_with_result_local_queue() {
            guard let cursor: DBCursor = try! self.getIdentityStmt.execute(node)?.cursor else {
                return nil;
            }
            let category: String? = cursor["category"];
            let type: String? = cursor["type"];
            let name: String? = cursor["name"];
            return DiscoveryModule.Identity(category: category!, type: type!, name: name);
        }
    }
    
    open func getNodes(withFeature feature: String) -> [String] {
        return dbConnection.dispatch_sync_with_result_local_queue() {
            var result = [String]();
            try! self.getNodesWithFeatureStmt.query(feature, forEachRow: {(cursor)->Void in
                result.append(cursor["node"]!);
            });
            return result;
        }
    }
    
    open func isCached(node: String) -> Bool {
        let count: Int? = try! nodeIsCached.scalar(node);
        return (count ?? 0) != 0;
    }
    
    open func store(node: String, identity: DiscoveryModule.Identity?, features: [String]) {
        guard !isCached(node: node) else {
            return;
        }

        for feature in features {
            _ = try! insertFeatureStmt.insert(node, feature);
        }
        
        if identity != nil {
            _ = try! insertIdentityStmt.insert(node, identity!.name, identity!.category, identity!.type);
        }
    }
    
}
