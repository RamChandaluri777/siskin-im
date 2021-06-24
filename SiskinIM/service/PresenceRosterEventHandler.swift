//
// PresenceRosterEventHandler.swift
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
import Combine

class PresenceRosterEventHandler: XmppServiceExtension {
    
    public static let instance = PresenceRosterEventHandler();
    
    private init() {
    }
    
    func register(for client: XMPPClient, cancellables: inout Set<AnyCancellable>) {
        XmppService.instance.expectedStatus.combineLatest( XmppService.instance.$applicationState).sink(receiveValue: { [weak client] status, appState in
            if let presenceModule = client?.module(.presence) {
                let shouldSendInitialPresence = appState != .suspended;
                presenceModule.initialPresence = shouldSendInitialPresence;
                if shouldSendInitialPresence {
                    presenceModule.setPresence(show: status.show, status: status.message, priority: nil);
                }
            }
        }).store(in: &cancellables);
        client.module(.presence).subscriptionPublisher.sink(receiveValue: { [weak client] change in
            guard let client = client else {
                return;
            }
            switch change.action {
            case .subscribe:
                InvitationManager.instance.addPresenceSubscribe(for: client.userBareJid, from: change.jid);
            default:
                break;
            }
        }).store(in: &cancellables);
    }
        
}
