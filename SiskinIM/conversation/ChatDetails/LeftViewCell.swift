//
//  LeftViewCell.swift
//  ChatSample
//
//  Created by Hafiz on 20/09/2019.
//  Copyright © 2019 Nibs. All rights reserved.
//

import UIKit

class LeftViewCell : BaseChatTableViewCell {

    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var textMessageLabel: UILabel!
    @IBOutlet var lblTimeOfMessage: UILabel!
    @IBOutlet var heightTimestampCons: NSLayoutConstraint!
    @IBOutlet var lblTimeStamp: UILabel!
    var id: Int = 0;
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 12
        messageContainerView.backgroundColor = .lightGray
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
    override func set(item: ConversationEntry) {
        super.set(item: item);
        id = item.id;
    }
    
    func configureCell(item: ConversationEntry, message inMessage: String, correctionTimestamp: Date?, nickname: String? = nil) {
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "hh:mm a"

        if let dateChat = item.timestamp as Date? {
            self.lblTimeOfMessage?.text = dateFormatterPrint.string(from: dateChat)
        } else {
           print("There was an error decoding the string")
        }
        
        let message = messageBody(item: item, message: inMessage);
      /*  if message == "" {
            messageContainerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            textMessageLabel.heightAnchor.constraint(equalToConstant: 0).isActive = true
            lblTimeOfMessage.heightAnchor.constraint(equalToConstant: 0).isActive = true
            heightTimestampCons.constant = 0
        }*/
        let attrText = NSMutableAttributedString(string: message);       

        if let detect = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue | NSTextCheckingResult.CheckingType.address.rawValue | NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detect.matches(in: message, options: .reportCompletion, range: NSMakeRange(0, message.count));
            for match in matches {
                var url: URL? = nil;
                if match.url != nil {
                    url = match.url;
                }
                if match.phoneNumber != nil {
                    url = URL(string: "tel:\(match.phoneNumber!.replacingOccurrences(of: " ", with: "-"))");
                }
                if match.addressComponents != nil {
                    if let query = match.addressComponents!.values.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                        url = URL(string: "http://maps.apple.com/?q=\(query)");
                    }
                }
                if match.date != nil {
                    url = URL(string: "calshow:\(match.date!.timeIntervalSinceReferenceDate)");
                }
                if let url = url {
                    attrText.setAttributes([.link : url], range: match.range);
                }
            }
        }
        
        textMessageLabel.attributedText = attrText
    }
    
    fileprivate func messageBody(item: ConversationEntry, message: String) -> String {
        guard let msg = item.options.encryption.message() else {
            switch item.state {
            case .incoming_error(_, let errorMessage), .outgoing_error(_, let errorMessage):
                if let error = errorMessage {
                    //return "\(message)"
                    return "\(message)\n-----\n\(error)"
                }
            default:
                break;
            }
            return message;
        }
        return msg;
    }
}

    
    
    
  /*  func set(item: ConversationEntry, message inMessage: String, correctionTimestamp: Date?, nickname: String? = nil) {
        messageTextView.textView.delegate = self;
        set(item: item);
        
        
        if correctionTimestamp != nil, case .incoming(_) = item.state {
            self.stateView?.text = "✏️\(self.stateView!.text ?? "")";
        }
       
        let message = messageBody(item: item, message: inMessage);
        let attrText = NSMutableAttributedString(string: message);
        
            
        if let detect = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue | NSTextCheckingResult.CheckingType.address.rawValue | NSTextCheckingResult.CheckingType.date.rawValue) {
            let matches = detect.matches(in: message, options: .reportCompletion, range: NSMakeRange(0, message.count));
            for match in matches {
                var url: URL? = nil;
                if match.url != nil {
                    url = match.url;
                }
                if match.phoneNumber != nil {
                    url = URL(string: "tel:\(match.phoneNumber!.replacingOccurrences(of: " ", with: "-"))");
                }
                if match.addressComponents != nil {
                    if let query = match.addressComponents!.values.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                        url = URL(string: "http://maps.apple.com/?q=\(query)");
                    }
                }
                if match.date != nil {
                    url = URL(string: "calshow:\(match.date!.timeIntervalSinceReferenceDate)");
                }
                if let url = url {
                    attrText.setAttributes([.link : url], range: match.range);
                }
            }
        }
        attrText.addAttribute(.foregroundColor, value: UIColor(named: "chatMessageText") as Any, range: NSRange(location: 0, length: attrText.length));
        if Settings.enableMarkdownFormatting {
            Markdown.applyStyling(attributedString: attrText, defTextStyle: .body, showEmoticons: Settings.showEmoticons);
        } else {
            attrText.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .subheadline), range: NSRange(location: 0, length: attrText.length));
            attrText.fixAttributes(in: NSRange(location: 0, length: attrText.length));

        }
        self.messageTextView.attributedText = attrText;
        switch item.state {
        case.incoming(_):
            self.messageTextView.textView.textAlignment = .left
        case.outgoing(_):
            self.messageTextView.textView.textAlignment = .right
        case .none:
                print("none")
        case .incoming_error(_, errorMessage: _):
            print("incoming error")
        case .outgoing_error(_, errorMessage: _):
            print("outgoing error")
        }
        
//        if item.state.isError {
//            if (self.messageTextView.text?.isEmpty ?? true), let error = item.error {
//                self.messageTextView.text = "Error: \(error)";
//            }
//            if item.state.direction == .incoming {
//                self.messageTextView.textView.textColor = UIColor.red;
//            }
//        } else {
//            if item.encryption == .notForThisDevice || item.encryption == .decryptionFailed {
//                self.messageTextView.textView.textColor = UIColor(named: "chatMessageText");
//            }
//        }
    }*/
    
    
    
    
    

