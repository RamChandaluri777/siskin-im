//
//  RightViewCell.swift
//  ChatSample
//
//  Created by Hafiz on 20/09/2019.
//  Copyright © 2019 Nibs. All rights reserved.
//

import UIKit

class RightViewCell: UITableViewCell {

    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var textMessageLabel: UILabel!
    @IBOutlet var lblTimeOfMessage: UILabel!
    @IBOutlet var heightTimeStampConstraints: NSLayoutConstraint!
    @IBOutlet var lblTimeStamp: UILabel!
    var id: Int = 0;
    
    @IBOutlet var imgVWOfstate: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 12
        //RGB: (18, 140, 126)
        messageContainerView.backgroundColor = UIColor(red: 18/255, green: 140/255, blue: 126/255, alpha: 1.0)
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
//    override func set(item: ConversationEntry) {
//        super.set(item: item);
//        id = item.id;
//    }
    
    
    func configureCell(item: ConversationEntry, message inMessage: String, correctionTimestamp: Date?, nickname: String? = nil) {
     //   set(item: item);
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "hh:mm"
                        

        if let dateChat = item.timestamp as Date? {
            self.lblTimeOfMessage?.text = dateFormatterPrint.string(from: dateChat)
                       
            
            if item.state.code == 3 {
                //UNSENT
                imgVWOfstate.image = UIImage(named: "unsent")
                imgVWOfstate.backgroundColor = .red
            } else if item.state.code == 1 {
                //SENT
                imgVWOfstate.image = UIImage(named: "singletik")
                imgVWOfstate.backgroundColor = .black
            } else if item.state.code == 9 || item.state.code == 5 {
                //Delivered
                imgVWOfstate.image = UIImage(named: "greenTik")
                imgVWOfstate.backgroundColor = .green
                    
            } else if item.state.code == 11 || item.state.code == 7 {
                //DISPLAYED
                imgVWOfstate.image = UIImage(named: "grayTik")
                imgVWOfstate.backgroundColor = .gray
            }
            
        } else {
           print("There was an error decoding the string")
        }
                
        let message = messageBody(item: item, message: inMessage);
       /* if message == "" {
                   messageContainerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
                   textMessageLabel.heightAnchor.constraint(equalToConstant: 0).isActive = true
                   lblTimeOfMessage.heightAnchor.constraint(equalToConstant: 0).isActive = true
            heightTimeStampConstraints.constant = 0
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
                    //return "\(message)\n-----\n\(error)"
                    return "\(message)"
                }
            default:
                break;
            }
            return message;
        }
        return msg;
    }
}
