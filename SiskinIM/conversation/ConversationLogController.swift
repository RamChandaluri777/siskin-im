//
// ConversationLogController.swift
//
// Siskin IM
// Copyright (C) 2020 "Tigase, Inc." <office@tigase.com>
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
import Combine
import CoreAudio

class ConversationLogController: UIViewController, ConversationDataSourceDelegate, UITableViewDataSource, UITableViewDelegate {
    
    public static let REFRESH_CELL = Notification.Name("ConversationCellRefresh");
    
    private let firstRowIndexPath = IndexPath(row: 0, section: 0);

    @IBOutlet var tableView: UITableView!;
    
    var dataSource = ConversationDataSource();
    var newlyAddedRow:Int?
   // let dataSource = ConversationDataSource();
    var dataSourceArraySection = [[ConversationEntry]]()
    var arrayDateSection = NSMutableArray()

    var conversation: Conversation!;
        
    weak var conversationLogDelegate: ConversationLogDelegate?;

    var refreshControl: UIRefreshControl?;

    private let newestVisibleDateSubject = PassthroughSubject<Date,Never>();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.setupTable()
        dataSource.delegate = self;
        if let refreshControl = self.refreshControl {
            tableView.addSubview(refreshControl);
        }
        
        conversationLogDelegate?.initialize(tableView: self.tableView);
        
     //   tableView.dataSource = self;
        
        NotificationCenter.default.addObserver(self, selector: #selector(showEditToolbar), name: NSNotification.Name("tableViewCellShowEditToolbar"), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCell(_:)), name: ConversationLogController.REFRESH_CELL, object: nil);
            }
    
    func setupTable() {
        // config tableView
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160;
        tableView.separatorStyle = .none;
        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
        tableView.dataSource = self
        tableView.delegate = self
        
        
        /*
         if Settings.appearance.description == "Auto" || Settings.appearance.description == "Light" {
         //           nb.barTintColor = UIColor.white
         //           nb.tintColor = UIColor.black;
         //       } else if Settings.appearance.description == "Dark" {
         //            nb.barTintColor = UIColor.black
         //            nb.tintColor = UIColor.white;
         //       }
         */
        if Settings.appearance.description == "Auto" || Settings.appearance.description == "Light" {
            tableView.backgroundColor = .white
        } else if Settings.appearance.description == "Dark" {
            tableView.backgroundColor = .black
        }
      //  tableView.backgroundColor = .white//UIColor(named: "E4DDD6")
        tableView.tableFooterView = UIView()
        // cell setup
        tableView.register(UINib(nibName: "RightViewCell", bundle: nil), forCellReuseIdentifier: "RightViewCell")
        tableView.register(UINib(nibName: "LeftViewCell", bundle: nil), forCellReuseIdentifier: "LeftViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let conversation = self.conversation {
            newestVisibleDateSubject.onlyGreater().throttledSink(for: 0.5, scheduler: DispatchQueue.main, receiveValue: { date in
                DBChatHistoryStore.instance.markAsRead(for: conversation, before: date);
            });
            dataSource.loadItems(.unread(overhead: 50));
            NotificationManager.instance.dismissAllNotifications(on: conversation.account, with: conversation.jid);
        }
        
        super.viewWillAppear(animated);
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        hideEditToolbar();
    }
            
//    func numberOfSections(in tableView: UITableView) -> Int {
//     //   print(arrayDateSection.count)
//      //  return arrayDateSection.count;
//
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       // print("section>>>", section)
      ///  print(dataSourceArraySection[section].count)
      //  return dataSourceArraySection[section].count
       // return dataSourceArraySection!.count;
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = dataSource.getItem(at: indexPath.row) else {
            return tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCellIncoming", for: indexPath);
        }
      //  let abc = dataSourceArraySection[indexPath.section]
      //  let item = abc[indexPath.row]
        print(item.state)
        print(item.state.errorMessage)
        print(item.state.isError)
        switch item.payload {
        case .unreadMessages:
            let cell: ChatTableViewSystemCell = tableView.dequeueReusableCell(withIdentifier: "ChatTableViewSystemCell", for: indexPath) as! ChatTableViewSystemCell;
            cell.messageView.text = NSLocalizedString("Unread messages", comment: "conversation log label");
            cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
            return cell;
        case .messageRetracted:
            let id = isContinuation(at: indexPath.row, for: item) ? "ChatTableViewMessageContinuationCell" : "ChatTableViewMessageCell";
            let cell: ChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ChatTableViewCell;
            cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
            cell.setRetracted(item: item);
//            cell.setNeedsUpdateConstraints();
//            cell.updateConstraintsIfNeeded();
        
            return cell;
        case .message(let message, let correctionTimestamp):
            if message.starts(with: "/me") {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTableViewMeCell", for: indexPath) as! ChatTableViewMeCell;
                cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
                cell.set(item: item, message: message);
                return cell;
            } else {
//
                if item.sender.isGroupchat{
                    
                    let id = isContinuation(at: indexPath.row, for: item) ? "ChatTableViewMessageContinuationCell" : "ChatTableViewMessageCell";
                                     let cell: ChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ChatTableViewCell;
                                     cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
                                     cell.set(item: item, message: message, correctionTimestamp: correctionTimestamp);
                                     return cell;
                }else{
                    switch item.state {
                    case.incoming(_):
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: "LeftViewCell") as! LeftViewCell
                        cell.contentView.transform = tableView.transform
                        if indexPath.row == 0 && self.newlyAddedRow == nil && dataSource.count == 1 {
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                               cell.heightTimestampCons.constant = 30
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                       } else if dataSource.count > 1 && self.newlyAddedRow == nil {
                           if indexPath.row + 1 != dataSource.count {
                               if dataSource.getItem(at: indexPath.row + 1) != nil && dataSource.getItem(at: indexPath.row) != nil {
                                   let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: indexPath.row + 1)!, item2: dataSource.getItem(at: indexPath.row)!, index:indexPath.row, message:message)
                                   cell.heightTimestampCons.constant = 30
                                   if str1 == "" {
                                       cell.heightTimestampCons.constant = 0
                                       cell.lblTimeStamp.isHidden = true
                                   } else {
                                       cell.lblTimeStamp.isHidden = false
                                       cell.lblTimeStamp.text = str1
                                   }
                               }
                           } else if indexPath.row + 1 == dataSource.count {
                               if dataSource.getItem(at: indexPath.row) != nil {
                                   cell.lblTimeStamp.isHidden = false
                                   let dateFormatterPrint = DateFormatter()
                                   dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                                   let item = dataSource.getItem(at: indexPath.row)
                                   cell.heightTimestampCons.constant = 30
                                       cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                               }
                           }
                            
                       } else if self.newlyAddedRow != nil && dataSource.count > 1 {
                           if dataSource.getItem(at: self.newlyAddedRow! + 1) != nil && dataSource.getItem(at: self.newlyAddedRow!) != nil {
                               let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: self.newlyAddedRow! + 1)!, item2: dataSource.getItem(at: self.newlyAddedRow!)!, index:indexPath.row, message:message)
                               cell.heightTimestampCons.constant = 30
                               if str1 == "" {
                                cell.heightTimestampCons.constant = 0
                                   cell.lblTimeStamp.isHidden = true
                               } else {
                                   cell.lblTimeStamp.isHidden = false
                                   cell.lblTimeStamp.text = str1
                               }
                           }
                           self.newlyAddedRow = nil
                       } else if self.newlyAddedRow != nil && dataSource.count == 1 {
                           
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                               cell.heightTimestampCons.constant = 30
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                           self.newlyAddedRow = nil
                       }
                        cell.configureCell(item: item, message: message, correctionTimestamp: correctionTimestamp)//(message: message)
                        return cell
                    case.outgoing(_):
                        let cell = tableView.dequeueReusableCell(withIdentifier: "RightViewCell") as! RightViewCell
                        cell.contentView.transform = tableView.transform
                        if indexPath.row == 0 && self.newlyAddedRow == nil && dataSource.count == 1 {
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                               cell.heightTimeStampConstraints.constant = 30
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                       } else if dataSource.count > 1 && self.newlyAddedRow == nil {
                           if indexPath.row + 1 != dataSource.count {
                               if dataSource.getItem(at: indexPath.row + 1) != nil && dataSource.getItem(at: indexPath.row) != nil {
                                   let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: indexPath.row + 1)!, item2: dataSource.getItem(at: indexPath.row)!, index:indexPath.row, message:message)
                                   print(str1)
                                   cell.heightTimeStampConstraints.constant = 30
                                   if str1 == "" {
                                       cell.heightTimeStampConstraints.constant = 0
                                       cell.lblTimeStamp.isHidden = true
                                   } else {
                                       cell.lblTimeStamp.isHidden = false
                                       cell.lblTimeStamp.text = str1
                                   }
                               }
                           } else if indexPath.row + 1 == dataSource.count {
                               if dataSource.getItem(at: indexPath.row) != nil {
                                   cell.lblTimeStamp.isHidden = false
                                   let dateFormatterPrint = DateFormatter()
                                   dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                                   let item = dataSource.getItem(at: indexPath.row)
                                   cell.heightTimeStampConstraints.constant = 30
                                       cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                               }
                           }
                            
                       } else if self.newlyAddedRow != nil && dataSource.count > 1 {
                           if dataSource.getItem(at: self.newlyAddedRow! + 1) != nil && dataSource.getItem(at: self.newlyAddedRow!) != nil {
                               let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: self.newlyAddedRow! + 1)!, item2: dataSource.getItem(at: self.newlyAddedRow!)!, index:indexPath.row, message:message)
                               cell.heightTimeStampConstraints.constant = 30
                               if str1 == "" {
                                   cell.heightTimeStampConstraints.constant = 0
                                   cell.lblTimeStamp.isHidden = true
                               } else {
                                   cell.lblTimeStamp.isHidden = false
                                   cell.lblTimeStamp.text = str1
                               }
                           }
                           self.newlyAddedRow = nil
                       } else if self.newlyAddedRow != nil && dataSource.count == 1 {
                           
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               cell.heightTimeStampConstraints.constant = 30
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                           self.newlyAddedRow = nil
                       }
                        cell.configureCell(item: item, message: message, correctionTimestamp:correctionTimestamp)//(message: message)
                        return cell
                    case .none:
                            print("none")
                       return UITableViewCell()
                     //   return tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCellIncoming", for: indexPath);
                    case .incoming_error(_, errorMessage: _):
                        print("incoming error")
                       let cell = tableView.dequeueReusableCell(withIdentifier: "LeftViewCell") as! LeftViewCell
                       cell.contentView.transform = tableView.transform
                        if indexPath.row == 0 && self.newlyAddedRow == nil && dataSource.count == 1 {
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                               cell.heightTimestampCons.constant = 30
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                       } else if dataSource.count > 1 && self.newlyAddedRow == nil {
                           if indexPath.row + 1 != dataSource.count {
                               if dataSource.getItem(at: indexPath.row + 1) != nil && dataSource.getItem(at: indexPath.row) != nil {
                                   let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: indexPath.row + 1)!, item2: dataSource.getItem(at: indexPath.row)!, index:indexPath.row, message:message)
                                   cell.heightTimestampCons.constant = 30
                                   if str1 == "" {
                                       cell.heightTimestampCons.constant = 0
                                       cell.lblTimeStamp.isHidden = true
                                   } else {
                                       cell.lblTimeStamp.isHidden = false
                                       cell.lblTimeStamp.text = str1
                                   }
                               }
                           } else if indexPath.row + 1 == dataSource.count {
                               if dataSource.getItem(at: indexPath.row) != nil {
                                   cell.lblTimeStamp.isHidden = false
                                   let dateFormatterPrint = DateFormatter()
                                   dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                                   let item = dataSource.getItem(at: indexPath.row)
                                   cell.heightTimestampCons.constant = 30
                                       cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                               }
                           }
                            
                       } else if self.newlyAddedRow != nil && dataSource.count > 1 {
                           if dataSource.getItem(at: self.newlyAddedRow! + 1) != nil && dataSource.getItem(at: self.newlyAddedRow!) != nil {
                               let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: self.newlyAddedRow! + 1)!, item2: dataSource.getItem(at: self.newlyAddedRow!)!, index:indexPath.row, message:message)
                               cell.heightTimestampCons.constant = 30
                               if str1 == "" {
                                cell.heightTimestampCons.constant = 0
                                   cell.lblTimeStamp.isHidden = true
                               } else {
                                   cell.lblTimeStamp.isHidden = false
                                   cell.lblTimeStamp.text = str1
                               }
                           }
                           self.newlyAddedRow = nil
                       } else if self.newlyAddedRow != nil && dataSource.count == 1 {
                           
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                               cell.heightTimestampCons.constant = 30
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                           self.newlyAddedRow = nil
                       }
                       cell.configureCell(item: item, message: message, correctionTimestamp: correctionTimestamp)//(message: message)
                       return cell
                       // return tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCellIncoming", for: indexPath);
                    case .outgoing_error(_, errorMessage: _):
                       let cell = tableView.dequeueReusableCell(withIdentifier: "RightViewCell") as! RightViewCell
                       cell.contentView.transform = tableView.transform
                        if indexPath.row == 0 && self.newlyAddedRow == nil && dataSource.count == 1 {
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                               cell.heightTimeStampConstraints.constant = 30
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                       } else if dataSource.count > 1 && self.newlyAddedRow == nil {
                           if indexPath.row + 1 != dataSource.count {
                               if dataSource.getItem(at: indexPath.row + 1) != nil && dataSource.getItem(at: indexPath.row) != nil {
                                   let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: indexPath.row + 1)!, item2: dataSource.getItem(at: indexPath.row)!, index:indexPath.row, message:message)
                                   print(str1)
                                   cell.heightTimeStampConstraints.constant = 30
                                   if str1 == "" {
                                       cell.heightTimeStampConstraints.constant = 0
                                       cell.lblTimeStamp.isHidden = true
                                   } else {
                                       cell.lblTimeStamp.isHidden = false
                                       cell.lblTimeStamp.text = str1
                                   }
                               }
                           } else if indexPath.row + 1 == dataSource.count {
                               if dataSource.getItem(at: indexPath.row) != nil {
                                   cell.lblTimeStamp.isHidden = false
                                   let dateFormatterPrint = DateFormatter()
                                   dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                                   let item = dataSource.getItem(at: indexPath.row)
                                   cell.heightTimeStampConstraints.constant = 30
                                       cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                               }
                           }
                            
                       } else if self.newlyAddedRow != nil && dataSource.count > 1 {
                           if dataSource.getItem(at: self.newlyAddedRow! + 1) != nil && dataSource.getItem(at: self.newlyAddedRow!) != nil {
                               let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: self.newlyAddedRow! + 1)!, item2: dataSource.getItem(at: self.newlyAddedRow!)!, index:indexPath.row, message:message)
                               cell.heightTimeStampConstraints.constant = 30
                               if str1 == "" {
                                   cell.heightTimeStampConstraints.constant = 0
                                   cell.lblTimeStamp.isHidden = true
                               } else {
                                   cell.lblTimeStamp.isHidden = false
                                   cell.lblTimeStamp.text = str1
                               }
                           }
                           self.newlyAddedRow = nil
                       } else if self.newlyAddedRow != nil && dataSource.count == 1 {
                           
                           if dataSource.getItem(at: indexPath.row) != nil {
                               cell.lblTimeStamp.isHidden = false
                               let dateFormatterPrint = DateFormatter()
                               cell.heightTimeStampConstraints.constant = 30
                               dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                               let item = dataSource.getItem(at: indexPath.row)
                                   cell.lblTimeStamp.text = dateFormatterPrint.string(from: item!.timestamp)
                           }
                           self.newlyAddedRow = nil
                       }
                       cell.configureCell(item: item, message: message, correctionTimestamp:correctionTimestamp)//(message: message)
                       return cell
                       // return tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCellIncoming", for: indexPath);
                    }
                }
             }
        case .linkPreview(let url):
            let id = "ChatTableViewLinkPreviewCell";
            let cell: LinkPreviewChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! LinkPreviewChatTableViewCell;
            cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
            cell.set(item: item, url: url);
            return cell;
        case .attachment(let url, let appendix):
            let id = isContinuation(at: indexPath.row, for: item) ? "ChatTableViewAttachmentContinuationCell" : "ChatTableViewAttachmentCell" ;
            let cell: AttachmentChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! AttachmentChatTableViewCell;
            cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
            let lbl = UILabel()
            lbl.frame = CGRect(x: 0, y: 0, width: cell.frame.size.width, height: 30)
            lbl.font = UIFont.systemFont(ofSize: 12.0)
            lbl.backgroundColor = .white
            lbl.textAlignment = .center
            lbl.textColor = .black
            lbl.text = "today"
            cell.contentView.addSubview(lbl)
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "hh:mm"
                            
            if let dateChat = item.timestamp as Date? {
                cell.lblTime?.text = dateFormatterPrint.string(from: dateChat)
            }
            
            if indexPath.row == 0 && self.newlyAddedRow == nil && dataSource.count == 1 {
               if dataSource.getItem(at: indexPath.row) != nil {
                   lbl.isHidden = false
                   let dateFormatterPrint = DateFormatter()
                   dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                   let item = dataSource.getItem(at: indexPath.row)
                   lbl.frame.size.height = 0
                   lbl.text = dateFormatterPrint.string(from: item!.timestamp)
               }
           } else if dataSource.count > 1 && self.newlyAddedRow == nil {
               if indexPath.row + 1 != dataSource.count {
                   if dataSource.getItem(at: indexPath.row + 1) != nil && dataSource.getItem(at: indexPath.row) != nil {
                       let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: indexPath.row + 1)!, item2: dataSource.getItem(at: indexPath.row)!, index:indexPath.row, message:"")
                       print(str1)
                       lbl.frame.size.height = 30
                       if str1 == "" {
                           lbl.frame.size.height = 0
                           lbl.isHidden = true
                       } else {
                           lbl.isHidden = false
                           lbl.text = str1
                       }
                   }
               } else if indexPath.row + 1 == dataSource.count {
                   if dataSource.getItem(at: indexPath.row) != nil {
                       lbl.isHidden = false
                       let dateFormatterPrint = DateFormatter()
                       dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                       let item = dataSource.getItem(at: indexPath.row)
                       lbl.frame.size.height = 0
                       lbl.text = dateFormatterPrint.string(from: item!.timestamp)
                   }
               }
                
           } else if self.newlyAddedRow != nil && dataSource.count > 1 {
               if dataSource.getItem(at: self.newlyAddedRow! + 1) != nil && dataSource.getItem(at: self.newlyAddedRow!) != nil {
                   let str1 = self.dataAccordingToDate(item1: dataSource.getItem(at: self.newlyAddedRow! + 1)!, item2: dataSource.getItem(at: self.newlyAddedRow!)!, index:indexPath.row, message:"")
                   lbl.frame.size.height = 30
                   if str1 == "" {
                       lbl.frame.size.height = 0
                       lbl.isHidden = true
                   } else {
                       lbl.isHidden = false
                       lbl.text = str1
                   }
               }
               self.newlyAddedRow = nil
           } else if self.newlyAddedRow != nil && dataSource.count == 1 {
               if dataSource.getItem(at: indexPath.row) != nil {
                   lbl.isHidden = false
                   let dateFormatterPrint = DateFormatter()
                   lbl.frame.size.height = 0
                   dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                   let item = dataSource.getItem(at: indexPath.row)
                       lbl.text = dateFormatterPrint.string(from: item!.timestamp)
               }
               self.newlyAddedRow = nil
           }
            cell.set(item: item, url: url, appendix: appendix);
            return cell;
        case .invitation(let message, let appendix):
            let id = "ChatTableViewInvitationCell";
            let cell: InvitationChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! InvitationChatTableViewCell;
            cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
            cell.set(item: item, message: message, appendix: appendix);
            return cell;
        case .marker(let type, let senders):
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTableViewMarkerCell", for: indexPath) as! ChatTableViewMarkerCell;
            cell.set(item: item, type: type, senders: senders);
            cell.contentView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0);
            return cell;
        default:
            return UITableViewCell()
                // return tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCellIncoming", for: indexPath);
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//
//        //if section < arrayDateSection.count {
//            if (arrayDateSection[section-1] as! Date).compare(Date()) == .orderedSame {
//                return "today"
//            } else {
//                let dateFormatterPrint = DateFormatter()
//                dateFormatterPrint.dateFormat = "dd MMMM YYYY"
//                print(dateFormatterPrint.string(from: arrayDateSection[section-1] as! Date))
//                return dateFormatterPrint.string(from: arrayDateSection[section-1] as! Date)
//            }
//          // }
//        //   return nil
//    }
    
    
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//            return 20
//        }
//
//     func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//             let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 20))
//
//             let label = UILabel()
//            // label.frame = CGRect.init(x: 5, y: 5, width: headerView.frame.width-10, height: headerView.frame.height-10)
//             label.font = .systemFont(ofSize: 16)
//             label.textColor = .white
//         label.textAlignment = .center
//         print(section)
//         print(arrayDateSection[section] as! Date)
//        if (arrayDateSection[section] as! Date).compare(Date()) == .orderedSame {
//                         label.text = "today"
//        } else {
//                         let dateFormatterPrint = DateFormatter()
//                         dateFormatterPrint.dateFormat = "dd MMMM YYYY"
//                         label.text = dateFormatterPrint.string(from: arrayDateSection[section] as! Date)
//        }
//         label.backgroundColor = .darkGray
//         label.layer.cornerRadius = 10.0
//         label.layer.borderColor = UIColor.gray.cgColor
//         label.layer.borderWidth = 0.5
//         label.clipsToBounds = true
//         label.sizeToFit()
//         label.frame.size.width = label.frame.size.width + 20
//         label.center.x = headerView.center.x
//
//             headerView.addSubview(label)
//             return headerView
//         }

    private func getPreviousEntry(before row: Int) -> ConversationEntry? {
        guard row >= 0 && (row + 1) < dataSource.count else {
            return nil;
        }
        return dataSource.getItem(at: row + 1);
    }
    
    private func isContinuation(at row: Int, for entry: ConversationEntry) -> Bool {
        guard let prevEntry = getPreviousEntry(before: row) else {
            return false;
        }
        switch prevEntry.payload {
        case .messageRetracted, .message(_, _), .attachment(_, _):
            return entry.isMergeable(with: prevEntry);
        case .marker(_, _), .linkPreview(_):
            return isContinuation(at: row + 1, for: entry);
        default:
            return false;
        }
    }
    
    func beginUpdates() {
        tableView.beginUpdates();
    }
    
    func endUpdates() {
        tableView.endUpdates();
    }
    
    func itemsAdded(at rows: IndexSet, initial: Bool) {
        let paths = rows.map({ IndexPath(row: $0, section: 0)});
        self.newlyAddedRow = paths.last?.row
//        let abc = (previousViewController as! ChatsListViewController).getDatabaseData()
//        self.dataSource = abc.item(at: 0).chat
//
//        print(self.dataSourceArraySection[0].count)
      //  tableView.insertRows(at: [IndexPath(row: self.dataSourceArraySection[0].count + 1, section: 0)], with: initial ? .none : .fade)
        tableView.insertRows(at: paths, with: initial ? .none : .fade)
    }
    
    func itemsUpdated(forRowIndexes rows: IndexSet) {
        let paths = rows.map({ IndexPath(row: $0, section: 0) });
        tableView.reloadRows(at: paths, with: .fade)
        markAsReadUpToNewestVisibleRow();
    }
    
    func itemUpdated(indexPath: IndexPath) {
        tableView.deleteRows(at: [indexPath], with: .fade);
        tableView.insertRows(at: [indexPath], with: .fade);
        markAsReadUpToNewestVisibleRow();
    }

    func isVisible(row: Int) -> Bool {
        return tableView.indexPathsForVisibleRows?.contains(where: { $0.row == row }) ?? false;
    }
    
    func scrollRowToVisible(_ row: Int) {
            tableView.scrollToRow(at: IndexPath(row: row, section:0), at: .none, animated: true);
    }
    
    func itemsRemoved(at rows: IndexSet) {
        let paths = rows.map({ IndexPath(row: $0, section: 0)});
        tableView.deleteRows(at: paths, with: .fade);
    }
    
    func itemsReloaded () {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData();
        markAsReadUpToNewestVisibleRow();
    }
    
    func dataAccordingToDate(item1:ConversationEntry, item2:ConversationEntry, index:Int, message:String) -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd:MM:YYYY"
        if dateFormatterPrint.string(from: item1.timestamp) != dateFormatterPrint.string(from: item2.timestamp) {
            if dateFormatterPrint.string(from: Date()) == dateFormatterPrint.string(from: item2.timestamp) {
                return "today"
            } else {
                dateFormatterPrint.dateFormat = "dd MMMM YYYY"
                return dateFormatterPrint.string(from: item2.timestamp)
            }
        }
        return ""
        
//        let arr = NSMutableArray()
//        print(dataSource.count)
//        for index in 0...(dataSource.count - 1) {
//            let item1 = dataSource.getItem(at: index)
//            var item2 : ConversationEntry?
//            if index == dataSource.count - 1 {
//                item2 = nil
//            } else {
//                item2 = dataSource.getItem(at: index+1)
//            }
//
//            let dateFormatterPrint = DateFormatter()
//            dateFormatterPrint.dateFormat = "dd MMMM YYYY"
//            dateFormatterPrint.string(from: item1!.timestamp)
//            print(dateFormatterPrint.string(from: item1!.timestamp) as! String)
//            print(dateFormatterPrint.string(from: Date()))
//            if dateFormatterPrint.string(from: item1!.timestamp) as! String == dateFormatterPrint.string(from: Date()) {
//                arr.add(item1!)
//             //   dataSourceArraySection.append(arr as! [ConversationEntry])
//              //  arrayDateSection.add(item1!.timestamp)
//             //   arr.removeAllObjects()
//            } else {
//                let item3 = dataSource.getItem(at: index-1)
//                if index > 0 && dateFormatterPrint.string(from: item3!.timestamp) as! String == dateFormatterPrint.string(from: Date()) {
//                    dataSourceArraySection.append(arr as! [ConversationEntry])
//                    arrayDateSection.add(item1!.timestamp)
//                    arr.removeAllObjects()
//                }
//            if item2 != nil{
//                if dateFormatterPrint.string(from: item1!.timestamp) == dateFormatterPrint.string(from: item2!.timestamp) {
//                    arr.add(item1!)
//                } else if (item1!.timestamp).compare(item2!.timestamp) == .orderedAscending {
//                    arr.add(item1!)
//                    dataSourceArraySection.append(arr as! [ConversationEntry])
//                    arrayDateSection.add(item1!.timestamp)
//                    arr.removeAllObjects()
//                } else if (item1!.timestamp).compare(item2!.timestamp) == .orderedDescending {
//                    //Not Possible
//                    print("Not Possible")
//                    arr.add(item1!)
//                    dataSourceArraySection.append(arr as! [ConversationEntry])
//                    print(dataSourceArraySection)
//                    arrayDateSection.add(item1!.timestamp)
//                    print(arrayDateSection)
//                    arr.removeAllObjects()
//                }
//            } else {
//                arr.add(item1!)
//                dataSourceArraySection.append(arr as! [ConversationEntry])
//                arrayDateSection.add(item1!.timestamp)
//                arr.removeAllObjects()
//            }
////            if (item1!.timestamp).compare(Date()) == .orderedAscending {
////                print(dateFormatterPrint.string(from: item1!.timestamp))
////                dataSourceArraySection.append(arr as! [ConversationEntry])
////                arrayDateSection.add(item1!.timestamp)
////                arr.removeAllObjects()
////                if item2 != nil{
////                    print(dateFormatterPrint.string(from: item2!.timestamp))
////                }
//
//
//
//            } /*else if (item1!.timestamp).compare(Date()) == .orderedDescending {
//                print("Not Possible")
//                arr.add(item1!)
//                dataSourceArraySection.append(arr as! [ConversationEntry])
//                arrayDateSection.add(item1!.timestamp)
//                arr.removeAllObjects()
//            }*/
//        }
    }
    
    

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //super.scrollViewDidScroll(scrollView);
      //  self.reloadVisibleItems()
        markAsReadUpToNewestVisibleRow();
    }
    
    
    
    func markAsReadUpToNewestVisibleRow() {
        if let visibleRows = tableView.indexPathsForVisibleRows {
            print(visibleRows)
            if visibleRows.contains(IndexPath(row: 0, section: 0)) {
                self.dataSource.trimStore();
            }
            
            if UIApplication.shared.applicationState == .active, let newestVisibleUnreadTimestamp = visibleRows.compactMap({ index -> Date? in
                guard let item = dataSource.getItem(at: index.row) else {
                    return nil;
                }
                return item.timestamp;
            }).max() {
                newestVisibleDateSubject.send(newestVisibleUnreadTimestamp);
            }
        }
    }

    func reloadVisibleItems() {
        if let indexPaths = self.tableView.indexPathsForVisibleRows {
            self.tableView.reloadRows(at: indexPaths, with: .none);
        }
    }
        
    @objc func refreshCell(_ notification: Notification) {
        guard let cell = notification.object as? UITableViewCell, let idx = tableView.indexPath(for: cell) else {
            return;
        }
        
        tableView.reloadRows(at: [idx], with: .automatic);
    }
    
    private var tempRightBarButtonItem: UIBarButtonItem?;
}

extension ConversationLogController {
    
    private var withTimestamps: Bool {
        get {
            return Settings.copyMessagesWithTimestamps;
        }
    };
        
    @objc func editCancelClicked() {
        hideEditToolbar();
    }
    
    func copySelectedMessages() {
        copyMessageInt(paths: tableView.indexPathsForSelectedRows ?? []);
        hideEditToolbar();
    }

    @objc func shareSelectedMessages() {
        shareMessageInt(paths: tableView.indexPathsForSelectedRows ?? []);
        hideEditToolbar();
    }

    func copyMessageInt(paths: [IndexPath]) {
        getTextOfSelectedRows(paths: paths, withTimestamps: false) { (texts) in
            UIPasteboard.general.strings = texts;
            UIPasteboard.general.string = texts.joined(separator: "\n");
        };
    }
    
    func shareMessageInt(paths: [IndexPath]) {
        getTextOfSelectedRows(paths: paths, withTimestamps: withTimestamps) { (texts) in
            let text = texts.joined(separator: "\n");
            let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil);
            let visible = self.tableView.indexPathsForVisibleRows ?? [];
            if let firstVisible = visible.first(where:{ (indexPath) -> Bool in
                return paths.contains(indexPath);
                }) ?? visible.first {
                activityController.popoverPresentationController?.sourceRect = self.tableView.rectForRow(at: firstVisible);
                activityController.popoverPresentationController?.sourceView = self.tableView.cellForRow(at: firstVisible);
                self.navigationController?.present(activityController, animated: true, completion: nil);
            }
        }
    }
    
    @objc func showEditToolbar(_ notification: Notification) {
        guard let cell = notification.object as? UITableViewCell else {
            return;
        }

        DispatchQueue.main.async {
            self.view.endEditing(true);
            DispatchQueue.main.async {
                let selected = self.tableView?.indexPath(for: cell);
                UIView.animate(withDuration: 0.3) {
                    self.tableView?.isEditing = true;
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                        self.tableView?.selectRow(at: selected, animated: false, scrollPosition: .none);
                    }
                
                    self.tempRightBarButtonItem = self.conversationLogDelegate?.navigationItem.rightBarButtonItem;
                    self.conversationLogDelegate?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ConversationLogController.editCancelClicked));
                
                    let timestampsSwitch = TimestampsBarButtonItem();
                    self.conversationLogDelegate?.navigationController?.toolbar.tintColor = UIColor(named: "tintColor");
                    let items = [
                        timestampsSwitch,
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(ConversationLogController.shareSelectedMessages))
                        //                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                    ];
                
                    self.conversationLogDelegate?.navigationController?.setToolbarHidden(false, animated: true);
                    self.conversationLogDelegate?.setToolbarItems(items, animated: true);
                }
            }
        }
    }
        
    func hideEditToolbar() {
        UIView.animate(withDuration: 0.3) {
            self.conversationLogDelegate?.navigationController?.setToolbarHidden(true, animated: true);
            self.conversationLogDelegate?.setToolbarItems(nil, animated: true);
            self.conversationLogDelegate?.navigationItem.rightBarButtonItem = self.tempRightBarButtonItem;
            self.tableView?.isEditing = false;
        }
    }
    
    func getTextOfSelectedRows(paths: [IndexPath], withTimestamps: Bool, handler: (([String]) -> Void)?) {
        let items: [ConversationEntry] = paths.map({ index in dataSource.getItem(at: index.row)! }).sorted { (it1, it2) -> Bool in
              it1.timestamp.compare(it2.timestamp) == .orderedAscending;
        };
        
        let withoutPrefix = Set(items.map({it in it.state.direction})).count == 1;
    
        let formatter = DateFormatter();
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "dd.MM.yyyy jj:mm", options: 0, locale: NSLocale.current);
    
        let texts = items.compactMap({ (it) -> String? in
            switch it.payload {
            case .message(let message, _):
                let prefix = withoutPrefix ? "" : "\(it.sender.nickname ?? "") ";
                if withTimestamps {
                    return "\(formatter.string(from: it.timestamp)) \(prefix)\(message)"
                } else {
                    return "\(prefix)\(message)"
                }
            default:
                return nil;
            }
        });
            
        handler?(texts);
    }

    class TimestampsBarButtonItem: UIBarButtonItem {
        
        var value: Bool {
            get {
                Settings.copyMessagesWithTimestamps;
            }
            set {
                Settings.copyMessagesWithTimestamps = newValue;
                updateTimestampSwitch();
            }
        }
        
        override init() {
            super.init();
            self.style = .plain;
            self.target = self;
            self.action = #selector(switchWithTimestamps)
            self.updateTimestampSwitch();
        }
        
        required init?(coder: NSCoder) {
            return nil;
        }
        
        @objc private func switchWithTimestamps() {
            value = !value;
        }
        
        private func updateTimestampSwitch() {
            image = UIImage(systemName: value ? "clock.fill" : "clock");
            title = nil;
        }
    }
}

protocol ConversationLogDelegate: AnyObject {
 
    var navigationItem: UINavigationItem { get }
    var navigationController: UINavigationController? { get }
    
    func initialize(tableView: UITableView);
    
    func setToolbarItems(_ toolbarItems: [UIBarButtonItem]?,
                         animated: Bool);
}
