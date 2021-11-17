//
//  RightViewCell.swift
//  ChatSample
//
//  Created by Hafiz on 20/09/2019.
//  Copyright © 2019 Nibs. All rights reserved.
//

import UIKit

class RightViewCell: BaseChatTableViewCell, UIContextMenuInteractionDelegate {

    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var textMessageLabel: UILabel!
    @IBOutlet var lblTimeOfMessage: UILabel!
    @IBOutlet var heightTimeStampConstraints: NSLayoutConstraint!
    @IBOutlet var lblTimeStamp: UILabel!
    var id: Int = 0;
    
    @IBOutlet var imgVWOfstate: UIImageView!
    
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?;
    fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer?;
    private var item: ConversationEntry?;
    
    var cellDelegate:attachmentFeaturesCellDelegate?
    var indexPath:IndexPath?
    var index = Int()
    var messageString:String = ""
    
    var documentController: UIDocumentInteractionController? {
        didSet {
            if let value = oldValue {
                for recognizer in value.gestureRecognizers {
                    self.removeGestureRecognizer(recognizer)
                }
            }
            if let value = documentController {
                value.delegate = self;
                for recognizer in value.gestureRecognizers {
                    self.addGestureRecognizer(recognizer)
                }
            }
            longPressGestureRecognizer?.isEnabled = documentController == nil;
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 12
        //RGB: (18, 140, 126)
        messageContainerView.backgroundColor = UIColor(red: 18/255, green: 140/255, blue: 126/255, alpha: 1.0)
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureDidFire));
        tapGestureRecognizer?.cancelsTouchesInView = false;
        tapGestureRecognizer?.numberOfTapsRequired = 2;
        messageContainerView.addGestureRecognizer(tapGestureRecognizer!);
        
        if #available(iOS 13.0, *) {
            messageContainerView.addInteraction(UIContextMenuInteraction(delegate: self));
        } else {
            longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureDidFire));
            longPressGestureRecognizer?.cancelsTouchesInView = true;
            longPressGestureRecognizer?.delegate = self;
                
            messageContainerView.addGestureRecognizer(longPressGestureRecognizer!);
        }        
    }
    
//    override func set(item: ConversationEntry) {
//        super.set(item: item);
//        id = item.id;
//    }
    
    //Gesture's Method
    @objc func longPressGestureDidFire(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .recognized else {
            return;
        }
        downloadOrOpen();
    }
    
    @objc func tapGestureDidFire(_ recognizer: UITapGestureRecognizer) {
        downloadOrOpen();
    }
    
    private func downloadOrOpen() {
        guard let item = self.item else {
            return;
        }
        if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
//            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent(localUrl.lastPathComponent);
//            try? FileManager.default.copyItem(at: localUrl, to: tmpUrl);
            open(url: localUrl, preview: true);
        }
    }
    
    func open(url: URL, preview: Bool) {
        print("opening a file:", url, "exists:", FileManager.default.fileExists(atPath: url.path));// "tmp:", tmpUrl);
        let documentController = UIDocumentInteractionController(url: url);
        documentController.delegate = self;
        print("detected uti:", documentController.uti as Any, "for:", documentController.url as Any);
        if preview && documentController.presentPreview(animated: true) {
            self.documentController = documentController;
        } else if documentController.presentOptionsMenu(from: self.superview?.convert(self.frame, to: self.superview?.superview) ?? CGRect.zero, in: self.self, animated: true) {
            self.documentController = documentController;
        }
    }
    
    //Protocol Context Menu Interaction Delegate
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            return self.prepareContextMenu();
        };
    }
    
    func prepareContextMenu() -> UIMenu {
        let item = self.item!
//        guard let item = self.item, case .attachment(let url, _) = item.payload else {
//            return UIMenu(title: "");
//        }
        print(item.id)
       // if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
            let items = [
//                UIAction(title: "Preview", image: UIImage(systemName: "eye.fill"), handler: { action in
//                    print("preview called");
//                    self.open(url: localUrl, preview: true);
//                }),
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: { action in
                    UIPasteboard.general.strings = [self.messageString]//[url];
                    UIPasteboard.general.string = self.messageString//url;
                }),
//                UIAction(title: "Share..", image: UIImage(systemName: "square.and.arrow.up"), handler: { action in
//                    print("share called");
//                    self.open(url: localUrl, preview: false);
//                }),
//                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: [.destructive], handler: { action in//[self] [self] action in
//                    print("delete called");
//                    DownloadStore.instance.deleteFile(for: "\(item.id)");
//                    DBChatHistoryStore.instance.updateItem(for: item.conversation, id: item.id, updateAppendix: { appendix in
//                        appendix.state = .removed;
//                    })
//                    DBChatHistoryStore.instance.remove(item: item)
//                    self.callProtocolFunction()
//                    
//                }),
                UIAction(title: "More..", image: UIImage(systemName: "ellipsis"), handler: { action in
                    NotificationCenter.default.post(name: Notification.Name("tableViewCellShowEditToolbar"), object: self);
                })
            ];
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items);
        //}
     //   return UIMenu(title: "");
    }
    
    func callProtocolFunction() {
        if self.indexPath != nil {
            self.cellDelegate?.featuresWorking?(indexPath: indexPath!, index: index)
        }
    }
    
    func configureCell(item: ConversationEntry, message inMessage: String, correctionTimestamp: Date?, nickname: String? = nil) {
     //   set(item: item);
        self.item = item
        self.messageString = inMessage
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "hh:mm"
                        

        if let dateChat = item.timestamp as Date? {
            self.lblTimeOfMessage?.text = dateFormatterPrint.string(from: dateChat)
                       
            
            if item.state.code == 3 {
                //UNSENT
                imgVWOfstate.image = UIImage(named: "unsent")
            } else if item.state.code == 1 {
                //SENT
                imgVWOfstate.image = UIImage(named: "singletik")
            } else if item.state.code == 9 || item.state.code == 5 {
                //Delivered
                imgVWOfstate.image = UIImage(named: "greenTik")
            } else if item.state.code == 11 || item.state.code == 7 {
                //DISPLAYED
                imgVWOfstate.image = UIImage(named: "grayTik")
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
