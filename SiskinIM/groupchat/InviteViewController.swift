//
// InviteViewController.swift
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

import UIKit
import TigaseSwift

class InviteViewController: AbstractRosterViewController {

    var room: Room!;
    
    var onNext: (([BareJID])->Void)? = nil;
    var selected: [BareJID] = [];
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        if onNext != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Create", comment: "button label"), style: .plain, target: self, action: #selector(selectionFinished(_:)))
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)));
        }
    }
    
    @objc func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil);
    }
    
    @objc func selectionFinished(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil);
        
        if let onNext = self.onNext {
            self.onNext = nil;
            onNext(selected);
        }
    }
        
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let item = roster?.item(at: indexPath) else {
            return;
        }
        guard !tableView.allowsMultipleSelection else {
            if selected.contains(item.jid) {
                selected = selected.filter({ (jid) -> Bool in
                    return jid != item.jid;
                });
                tableView.deselectRow(at: indexPath, animated: true);
            } else {
                selected.append(item.jid);
            }
            return;
        }

        room.invite(JID(item.jid), reason: String.localizedStringWithFormat(NSLocalizedString("You are invied to join conversation at %@", comment: "error label"), room.roomJid.stringValue));
        self.SendrefreshrequestKey()
        self.navigationController?.dismiss(animated: true, completion: nil);
    }
 
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let item = roster?.item(at: indexPath) else {
            return;
        }
        selected = selected.filter({ (jid) -> Bool in
            return jid != item.jid;
        });
    }
    
    func SendrefreshrequestKey(){
        let ecdh = OTRECDHKeyExchange()
        let jid = BareJID("enhanced-apk@chat.securesignal.in");
        if let account = AccountManager.getActiveAccounts().first?.name {
            var conversation = DBChatStore.instance.conversation(for: account, with: jid) as? Chat
            if conversation == nil {
                guard let client = XmppService.instance.getClient(for: account) else {
                            return;
                        }
                
                switch DBChatStore.instance.createChat(for: client, with:jid) {
                case .created(let chat):
                    conversation = chat;
                case .found(let chat):
                    conversation = chat;
                case .none:
                    return;
                }
                
               
                }
            conversation?.updateOptions({ options in
                options.encryption = ChatEncryption.none;
            })
            let roomData = room.roomJid.stringValue + "/" + account.localPart!
            let Refreshdata = ["type":"TYPE_GROUP_REFRESH","roomid":roomData] as [String : Any]
            
            if let theJSONData = try? JSONSerialization.data(
                withJSONObject: Refreshdata,
                options: []) {
                let theJSONText = String(data: theJSONData,
                                           encoding: .ascii)
                print("JSON string = \(theJSONText!)")
                let RefreshRequest = ecdh.aesEncrypt(messageData: theJSONText?.data(using: .utf8) as! NSData)!
                conversation?.sendMessage(text: RefreshRequest, correctedMessageOriginId: nil)
            }
           
            
        }
       
        
    }

}
