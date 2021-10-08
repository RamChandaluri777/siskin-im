//
//  AttachmentsCell.swift
//  Siskin IM
//
//  Created by Nandini Barve on 05/10/21.
//  Copyright © 2021 Tigase, Inc. All rights reserved.
//

import UIKit

class AttachmentsCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet var lblAttachment: UILabel!
    @IBOutlet var collectionViewAttachment: UICollectionView!
    
    private var items: [ConversationEntry] = [];
    var conversation: Conversation!;
    private var loaded: Bool = false;
//    private var cancellables: Set<AnyCancellable> = [];
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//              //  layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
//        layout.itemSize = CGSize(width: self.collectionViewAttachment.frame.size.width/3, height: self.collectionViewAttachment.frame.size.width/3)
//                layout.minimumInteritemSpacing = 0
//                layout.minimumLineSpacing = 0
//                collectionViewAttachment!.collectionViewLayout = layout
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func reloadCollectionView() {
        
        self.collectionViewAttachment.dataSource = self
        self.collectionViewAttachment.delegate = self
        
        print(self.conversation!)
        let conversation = self.conversation!;
       /* DBChatHistoryStore.instance.events.compactMap({ it -> ConversationEntry? in
            if case .updated(let item) = it {
                return item;
            }
            return nil;
        }).filter({ item in
            if case .attachment(_, _) = item.payload, item.conversation.account == conversation.account && item.conversation.jid == conversation.jid {
                return true;
            }
            return false;
        }).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] value in
            if let idx = self?.items.firstIndex(where: { $0.id == value.id }) {
                self?.items[idx] = value;
                self?.collectionView.reloadItems(at: [IndexPath(row: idx, section: 0)]);
            }
        }).store(in: &cancellables);*/
        if !loaded {
            self.loaded = true;
            DBChatHistoryStore.instance.loadAttachments(for: conversation, completionHandler: { attachments in
                DispatchQueue.main.async {
                    self.items = attachments.filter({ (attachment) -> Bool in
                        return DownloadStore.instance.url(for: "\(attachment.id)") != nil;
                    });
                    print(self.items)
                    self.collectionViewAttachment.reloadData();
                }
            });
        }
    }
    
//     func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1;
//    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if items.isEmpty {
            if self.collectionViewAttachment.backgroundView == nil {
                let label = UILabel(frame: CGRect(x: 0, y:0, width: self.contentView.bounds.size.width, height: self.contentView.bounds.size.height));
                label.text = NSLocalizedString("No attachments", comment: "attachments view label");
                label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize + 2, weight: .medium);
                label.numberOfLines = 0;
                label.textAlignment = .center;
                label.sizeToFit();
                self.collectionViewAttachment.backgroundView = label;
            }
        } else {
            self.collectionViewAttachment.backgroundView = nil;
        }
        print(items.count)
        return items.count;
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionViewAttachment.dequeueReusableCell(withReuseIdentifier: "AttachmentCellView", for: indexPath) as! ChatAttachmentsCellView;
        print(indexPath.item)
        print(items[indexPath.item])
        cell.set(item: items[indexPath.item]);
        return cell;
    }

}
