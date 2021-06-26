//
// BaseChatTableViewCell.swift
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

class BaseChatTableViewCellFormatter {
    
    fileprivate static let todaysFormatter = ({()-> DateFormatter in
        var f = DateFormatter();
        f.dateStyle = .none;
        f.timeStyle = .short;
        return f;
    })();
    fileprivate static let defaultFormatter = ({()-> DateFormatter in
        var f = DateFormatter();
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "dd.MM, jj:mm", options: 0, locale: NSLocale.current);
        //        f.timeStyle = .NoStyle;
        return f;
    })();
    fileprivate static let fullFormatter = ({()-> DateFormatter in
        var f = DateFormatter();
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "dd.MM.yyyy, jj:mm", options: 0, locale: NSLocale.current);
        //        f.timeStyle = .NoStyle;
        return f;
    })();

}

class BaseChatTableViewCell: UITableViewCell, UIDocumentInteractionControllerDelegate {

    @IBOutlet var avatarView: AvatarView?
    @IBOutlet var nicknameView: UILabel?;
    @IBOutlet var timestampView: UILabel?
    @IBOutlet var stateView: UILabel?;
                    
    var originalTimestampColor: UIColor!;
        
    func formatTimestamp(_ ts: Date) -> String {
        let flags: Set<Calendar.Component> = [.day, .year];
        let components = Calendar.current.dateComponents(flags, from: ts, to: Date());
        if (components.day! < 1) {
            return BaseChatTableViewCellFormatter.todaysFormatter.string(from: ts);
        }
        if (components.year! != 0) {
            return BaseChatTableViewCellFormatter.fullFormatter.string(from: ts);
        } else {
            return BaseChatTableViewCellFormatter.defaultFormatter.string(from: ts);
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if avatarView != nil {
            avatarView!.layer.masksToBounds = true;
            avatarView!.layer.cornerRadius = avatarView!.frame.height / 2;
        }
        originalTimestampColor = timestampView?.textColor;
        nicknameView?.textColor = UIColor.secondaryLabel;
        nicknameView?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: UIFont(descriptor: UIFont.preferredFont(forTextStyle: .subheadline).fontDescriptor.withSymbolicTraits(.traitBold)!, size: 0));
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            let colors = contentView.subviews.map({ it -> UIColor in it.backgroundColor ?? UIColor.clear });
            super.setSelected(selected, animated: animated)
            selectedBackgroundView = UIView();
            contentView.subviews.enumerated().forEach { (offset, view) in
                if view .responds(to: #selector(setHighlighted(_:animated:))) {
                    view.setValue(false, forKey: "highlighted");
                }
                print("offset", offset, "view", view);
                view.backgroundColor = colors[offset];
            }
        } else {
            super.setSelected(selected, animated: animated);
            selectedBackgroundView = nil;
        }
        // Configure the view for the selected state
    }
    
    
    func set(item: ChatViewItemProtocol) {
        var timestamp = formatTimestamp(item.timestamp);
        switch item.encryption {
        case .decrypted, .notForThisDevice, .decryptionFailed:
            timestamp = "\u{1F512} \(timestamp)";
        default:
            break;
        }
        switch item.state {
        case .incoming_error, .incoming_error_unread:
            self.stateView?.text = "\u{203c}";
        case .outgoing_unsent:
            self.stateView?.text = "\u{1f4e4}";
        case .outgoing_delivered:
            self.stateView?.text = "\u{2713}";
        case .outgoing_error, .outgoing_error_unread:
            self.stateView?.text = "\u{203c}";
        default:
            self.stateView?.text = nil;//NSColor.textColor;
        }
        if stateView == nil {
            if item.state.direction == .outgoing {
                timestampView?.textColor = originalTimestampColor;
                if item.state.isError {
                    timestampView?.textColor = UIColor.red;
                    timestamp = "\(timestamp) Not delivered\u{203c}";
                } else if item.state == .outgoing_delivered {
                    timestamp = "\(timestamp) \u{2713}";
                }
            }
        }
        timestampView?.text = timestamp;
                
        if item.state.isError {
            if item.state.direction == .outgoing {
                self.accessoryType = .detailButton;
                self.tintColor = UIColor.red;
            }
        } else {
            self.accessoryType = .none;
            self.tintColor = stateView?.tintColor;
        }
        
        self.stateView?.textColor = item.state.isError && item.state.direction == .incoming ? UIColor.red : originalTimestampColor;
        self.timestampView?.textColor = item.state.isError && item.state.direction == .incoming ? UIColor.red : originalTimestampColor;
    }
    
    @objc func actionMore(_ sender: UIMenuController) {
        NotificationCenter.default.post(name: NSNotification.Name("tableViewCellShowEditToolbar"), object: self);
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender) || action == #selector(actionMore(_:));
    }
    
    override func didTransition(to state: UITableViewCell.StateMask) {
        super.didTransition(to: state);
        UIView.setAnimationsEnabled(false);
        if state.contains(.showingEditControl) {
            for view in self.subviews {
                if view != self.contentView {
                    view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
                }
            }
        }
        UIView.setAnimationsEnabled(true);
    }
        
}
