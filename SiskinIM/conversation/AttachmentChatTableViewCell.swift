//
// AttachmentChatTableViewCell.swift
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


/*import UIKit
import MobileCoreServices
import LinkPresentation
import TigaseSwift

class AttachmentChatTableViewCell: BaseChatTableViewCell, UIContextMenuInteractionDelegate {
    
    @IBOutlet var customView: UIView!;
    @IBOutlet var lblTime: UILabel!
    override var backgroundColor: UIColor? {
        didSet {
            customView?.backgroundColor = backgroundColor;
        }
    }
    
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?;
    fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer?;
    
    private var item: ConversationEntry?;
    
    private var linkView: UIView? {
        didSet {
            if let old = oldValue, let new = linkView {
                guard old != new else {
                    return;
                }
            }
            if let view = oldValue {
                view.removeFromSuperview();
            }
            if let view = linkView {
                self.customView.addSubview(view);
                if #available(iOS 13.0, *) {
                    view.addInteraction(UIContextMenuInteraction(delegate: self));
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureDidFire));
        tapGestureRecognizer?.cancelsTouchesInView = false;
        tapGestureRecognizer?.numberOfTapsRequired = 2;
        customView.addGestureRecognizer(tapGestureRecognizer!);
        
        if #available(iOS 13.0, *) {
            customView.addInteraction(UIContextMenuInteraction(delegate: self));
        } else {
            longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureDidFire));
            longPressGestureRecognizer?.cancelsTouchesInView = true;
            longPressGestureRecognizer?.delegate = self;
                
            customView.addGestureRecognizer(longPressGestureRecognizer!);
        }
    }
        
    func set(item: ConversationEntry, url: String, appendix: ChatAttachmentAppendix) {
        self.item = item;
        super.set(item: item);
        
        self.customView?.isOpaque = true;
        self.customView?.backgroundColor = self.backgroundColor;
        
        
        
        
        if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
            documentController = UIDocumentInteractionController(url: localUrl);
            //self.longPressGestureRecognizer?.isEnabled = false;
            var metadata = MetadataCache.instance.metadata(for: "\(item.id)");
            
           let isNew = metadata == nil;
            if metadata == nil {
                metadata = LPLinkMetadata();
                metadata!.originalURL = localUrl;
                metadata?.title = ""
            } else {
                metadata!.originalURL = nil;
                //metadata!.url = nil;
                //metadata!.originalURL = localUrl;
                metadata!.url = localUrl;
            }
            
                
            let linkView = /*(self.linkView as? LPLinkView) ??*/LPLinkView(metadata: metadata!);
            
            linkView.setContentHuggingPriority(.defaultHigh, for: .vertical);
            linkView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical);
            linkView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            linkView.translatesAutoresizingMaskIntoConstraints = false;
            linkView.isUserInteractionEnabled = false;

            self.linkView = linkView;
            
            NSLayoutConstraint.activate([
                linkView.topAnchor.constraint(equalTo: self.customView.topAnchor, constant: 0),
                linkView.bottomAnchor.constraint(equalTo: self.customView.bottomAnchor, constant: 0),
                linkView.leadingAnchor.constraint(equalTo: self.customView.leadingAnchor, constant: 0),
                linkView.trailingAnchor.constraint(equalTo: self.customView.trailingAnchor, constant: 0),
                linkView.heightAnchor.constraint(lessThanOrEqualToConstant: 350)
            ]);
                
            if isNew {
                MetadataCache.instance.generateMetadata(for: localUrl, withId: "\(item.id)", completionHandler: { meta1 in
                    guard meta1 != nil else {
                        return;
                    }
                    DBChatHistoryStore.instance.updateItem(for: item.conversation, id: item.id, updateAppendix: { appendix in
                    });
                })
            }
        } else {
            documentController = nil;

            let attachmentInfo = (self.linkView as? AttachmentInfoView) ?? AttachmentInfoView(frame: .zero);
            //attachmentInfo.backgroundColor = self.backgroundColor;
            //attachmentInfo.isOpaque = true;

            //attachmentInfo.cellView = self;
            self.linkView = attachmentInfo;
            NSLayoutConstraint.activate([
                customView.leadingAnchor.constraint(equalTo: attachmentInfo.leadingAnchor),
                customView.trailingAnchor.constraint(greaterThanOrEqualTo: attachmentInfo.trailingAnchor),
                customView.topAnchor.constraint(equalTo: attachmentInfo.topAnchor),
                customView.bottomAnchor.constraint(equalTo: attachmentInfo.bottomAnchor)
            ])
            attachmentInfo.set(item: item, url: url, appendix: appendix);

            switch appendix.state {
            case .new:
                let sizeLimit = Settings.fileDownloadSizeLimit;
                if sizeLimit > 0 {
                    if (DBRosterStore.instance.item(for: item.conversation.account, jid: JID(item.conversation.jid))?.subscription ?? .none).isFrom || (DBChatStore.instance.conversation(for: item.conversation.account, with: item.conversation.jid) as? Room != nil) {
                        _ = DownloadManager.instance.download(item: item, url: url, maxSize: sizeLimit >= Int.max ? Int64.max : Int64(sizeLimit * 1024 * 1024));
                        attachmentInfo.progress(show: true);
                        return;
                    }
                }
                attachmentInfo.progress(show: DownloadManager.instance.downloadInProgress(for: item));
            default:
                attachmentInfo.progress(show: DownloadManager.instance.downloadInProgress(for: item));
            }
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            return self.prepareContextMenu();
        };
    }
    
    func prepareContextMenu() -> UIMenu {
        guard let item = self.item, case .attachment(let url, _) = item.payload else {
            return UIMenu(title: "");
        }
        
        if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
            let items = [
                UIAction(title: "Preview", image: UIImage(systemName: "eye.fill"), handler: { action in
                    print("preview called");
                    self.open(url: localUrl, preview: true);
                }),
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: { action in
                    UIPasteboard.general.strings = [url];
                    UIPasteboard.general.string = url;
                }),
                UIAction(title: "Share..", image: UIImage(systemName: "square.and.arrow.up"), handler: { action in
                    print("share called");
                    self.open(url: localUrl, preview: false);
                }),
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: [.destructive], handler: { action in
                    print("delete called");
                    DownloadStore.instance.deleteFile(for: "\(item.id)");
                    DBChatHistoryStore.instance.updateItem(for: item.conversation, id: item.id, updateAppendix: { appendix in
                        appendix.state = .removed;
                    })
                }),
                UIAction(title: "More..", image: UIImage(systemName: "ellipsis"), handler: { action in
                    NotificationCenter.default.post(name: Notification.Name("tableViewCellShowEditToolbar"), object: self);
                })
            ];
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items);
        } else {
            let items = [
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: { action in
                    UIPasteboard.general.strings = [url];
                    UIPasteboard.general.string = url;
                }),
                UIAction(title: "Download", image: UIImage(systemName: "square.and.arrow.down"), handler: { action in
                    print("download called");
                    self.download(for: item);
                }),
                UIAction(title: "More..", image: UIImage(systemName: "ellipsis"), handler: { action in
                    NotificationCenter.default.post(name: Notification.Name("tableViewCellShowEditToolbar"), object: self);
                })
            ];
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items);
        }
    }
    
    @objc func longPressGestureDidFire(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .recognized else {
            return;
        }
        downloadOrOpen();
    }
    
    @objc func tapGestureDidFire(_ recognizer: UITapGestureRecognizer) {
        downloadOrOpen();
    }
    
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
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        let rootViewController = ((UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController)!;
        if let viewController = rootViewController.presentingViewController {
            return viewController;
        }
        return rootViewController;
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
    
    func download(for item: ConversationEntry) {
        guard let item = self.item, case .attachment(let url, _) = item.payload else {
            return;
        }
        _ = DownloadManager.instance.download(item: item, url: url, maxSize: Int64.max);
        (self.linkView as? AttachmentInfoView)?.progress(show: true);
    }
    
//    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
//        return self;
//    }
    
//    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
//        print("file sharing cancelled!");
//        self.documentController = nil;
//    }
//
//    func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
//        print("file shared with:", application);
//        self.documentController = nil;
//    }
    
    private func downloadOrOpen() {
        guard let item = self.item else {
            return;
        }
        if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
//            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent(localUrl.lastPathComponent);
//            try? FileManager.default.copyItem(at: localUrl, to: tmpUrl);
            open(url: localUrl, preview: true);
        } else {
            let alert = UIAlertController(title: "Download", message: "File is not available locally. Should it be downloaded?", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.download(for: item);
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil));
            if let controller = (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController {
                controller.present(alert, animated: true, completion: nil);
            }
        }
    }
        
    class AttachmentInfoView: UIView {
        
        let iconView: ImageAttachmentPreview;
        let filename: UILabel;
        let details: UILabel;
        
        private var viewType: ViewType = .none {
            didSet {
                guard viewType != oldValue else {
                    return;
                }
                switch oldValue {
                case .none:
                    break;
                case .file:
                    NSLayoutConstraint.deactivate(fileViewConstraints);
                case .imagePreview:
                    NSLayoutConstraint.deactivate(imagePreviewConstraints);
                }
                switch viewType {
                    case .none:
                        break;
                    case .file:
                        NSLayoutConstraint.activate(fileViewConstraints);
                    case .imagePreview:
                        NSLayoutConstraint.activate(imagePreviewConstraints);
                }
                iconView.contentMode = viewType == .imagePreview ? .scaleAspectFill : .scaleAspectFit;
                iconView.isImagePreview = viewType == .imagePreview;
            }
        }
        
        private var fileViewConstraints: [NSLayoutConstraint] = [];
        private var imagePreviewConstraints: [NSLayoutConstraint] = [];
        
        override init(frame: CGRect) {
            iconView = ImageAttachmentPreview(frame: .zero);
            iconView.clipsToBounds = true
            iconView.image = UIImage(named: "defaultAvatar")!;
            iconView.translatesAutoresizingMaskIntoConstraints = false;
            iconView.setContentHuggingPriority(.defaultHigh, for: .vertical);
            iconView.setContentHuggingPriority(.defaultHigh, for: .horizontal);
            iconView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical);
            iconView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);

            filename = UILabel(frame: .zero);
            filename.font = UIFont.systemFont(ofSize: UIFont.systemFontSize - 1, weight: .semibold);
            filename.translatesAutoresizingMaskIntoConstraints = false;
            filename.setContentHuggingPriority(.defaultHigh, for: .horizontal);
            filename.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            
            details = UILabel(frame: .zero);
            details.font = UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .regular);
            details.translatesAutoresizingMaskIntoConstraints = false;
            details.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            details.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);

            super.init(frame: frame);
            self.clipsToBounds = true
            self.translatesAutoresizingMaskIntoConstraints = false;
            self.isOpaque = false;
            
            addSubview(iconView);
            addSubview(filename);
            addSubview(details);
            
            fileViewConstraints = [
                iconView.heightAnchor.constraint(equalToConstant: 30),
                iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
                
                iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
                iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
                iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                
                filename.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                filename.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
                filename.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -12),
                
                details.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                details.topAnchor.constraint(equalTo: filename.bottomAnchor, constant: 0),
                details.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                // -- this is causing issue with progress indicatior!!
                details.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -12),
                details.heightAnchor.constraint(equalTo: filename.heightAnchor)
            ];
            
            imagePreviewConstraints = [
                iconView.widthAnchor.constraint(lessThanOrEqualToConstant: 350),
                iconView.heightAnchor.constraint(lessThanOrEqualToConstant: 350),
                iconView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                iconView.heightAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                
                iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                iconView.topAnchor.constraint(equalTo: self.topAnchor),
                iconView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                
                filename.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
                filename.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
                filename.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -12),
                
                details.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
                details.topAnchor.constraint(equalTo: filename.bottomAnchor, constant: 0),
                details.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                details.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -12),
                details.heightAnchor.constraint(equalTo: filename.heightAnchor)
            ];
        }
        
        required init?(coder: NSCoder) {
            return nil;
        }
        
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 10);
            path.addClip();
            if #available(iOS 13.0, *) {
                UIColor.secondarySystemBackground.setFill();
            } else {
                UIColor.lightGray.withAlphaComponent(0.5).setFill();
            }
            path.fill();
            
            super.draw(rect);
        }
        
        func set(item: ConversationEntry, url: String, appendix: ChatAttachmentAppendix) {
            if let fileUrl = DownloadStore.instance.url(for: "\(item.id)") {
                filename.text = fileUrl.lastPathComponent;
                let fileSize = fileSizeToString(try! FileManager.default.attributesOfItem(atPath: fileUrl.path)[.size] as? UInt64);
                if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileUrl.pathExtension as CFString, nil)?.takeRetainedValue(), let typeName = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
                    details.text = "\(typeName) - \(fileSize)";
                    if UTTypeConformsTo(uti, kUTTypeImage) {
                        self.viewType = .imagePreview;
                        print("preview of:" , fileUrl, fileUrl.path);
                        iconView.image = UIImage(contentsOfFile: fileUrl.path)!;
                    } else {
                        self.viewType = .file;
                        iconView.image = UIImage.icon(forFile: fileUrl, mimeType: appendix.mimetype);
                    }
                } else {
                    details.text = fileSize;
                    iconView.image = UIImage.icon(forFile: fileUrl, mimeType: appendix.mimetype);
                    self.viewType = .file;
                }
            } else {
                let filename = appendix.filename ?? URL(string: url)?.lastPathComponent ?? "";
                if filename.isEmpty {
                    self.filename.text =  "Unknown file";
                } else {
                    self.filename.text = filename;
                }
                if let size = appendix.filesize {
                    if let mimetype = appendix.mimetype, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimetype as CFString, nil)?.takeRetainedValue(), let typeName = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
                        let fileSize = size >= 0 ? fileSizeToString(UInt64(size)) : "";
                        details.text = "\(typeName) - \(fileSize)";
                        iconView.image = UIImage.icon(forUTI: uti as String);
                    } else {
                        details.text = fileSizeToString(UInt64(size));
                        iconView.image = UIImage.icon(forUTI: "public.content");
                    }
                } else {
                    details.text = "--";
                    iconView.image = UIImage.icon(forUTI: "public.content");
                }
                self.viewType = .file;
            }
        }
        
        var progressView: UIActivityIndicatorView?;
        
        func progress(show: Bool) {
            guard show != (progressView != nil) else {
                return;
            }
            
            if show {
                let view = UIActivityIndicatorView(style: .medium);
                view.translatesAutoresizingMaskIntoConstraints = false;
                self.addSubview(view);
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: filename.trailingAnchor, constant: 8),
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: details.trailingAnchor, constant: 8),
                    view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
                    view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    view.topAnchor.constraint(lessThanOrEqualTo: self.topAnchor)
                ])
                self.progressView = view;
                view.startAnimating();
            } else if let view = progressView {
                view.stopAnimating();
                self.progressView = nil;
                view.removeFromSuperview();
            }
        }

        
        func fileSizeToString(_ sizeIn: UInt64?) -> String {
            guard let size = sizeIn else {
                return "";
            }
            let formatter = ByteCountFormatter();
            formatter.countStyle = .file;
            return formatter.string(fromByteCount: Int64(size));
        }
        
        enum ViewType {
            case none
            case file
            case imagePreview
        }
        
    }    

}

class ImageAttachmentPreview: UIImageView {
    
    var isImagePreview: Bool = false {
        didSet {
            if isImagePreview != oldValue {
                if isImagePreview {
                    self.layer.cornerRadius = 10;
                    self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner];
                } else {
                    self.layer.cornerRadius = 0;
                    self.layer.maskedCorners = [];
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FileManager {
    public func fileExtension(forUTI utiString: String) -> String? {
        guard
            let cfFileExtension = UTTypeCopyPreferredTagWithClass(utiString as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() else
        {
            return nil
        }

        return cfFileExtension as String
    }
}

extension UIImage {
    class func icon(forFile url: URL, mimeType: String?) -> UIImage? {
        let controller = UIDocumentInteractionController(url: url);
        if mimeType != nil, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType! as CFString, nil)?.takeRetainedValue() as String? {
            controller.uti = uti;
        }
        if controller.icons.count == 0 {
            controller.uti = "public.data";
        }
        let icons = controller.icons;
        print("got:", icons.last as Any, "for:", url.absoluteString);
        return icons.last;
    }

    class func icon(forUTI utiString: String) -> UIImage? {
        let controller = UIDocumentInteractionController(url: URL(fileURLWithPath: "temp.file"));
        controller.uti = utiString;
        if controller.icons.count == 0 {
            controller.uti = "public.data";
        }
        let icons = controller.icons;
        print("got:", icons.last as Any, "for:", utiString);
        return icons.last;
    }
    
}*/










import UIKit
import MobileCoreServices
import LinkPresentation
import TigaseSwift
import AVFoundation

class AttachmentChatTableViewCell: BaseChatTableViewCell, UIContextMenuInteractionDelegate {
    
    @IBOutlet var customView: UIView!;
    
<<<<<<< HEAD
    @IBOutlet var imgViewOfAttachment: UIImageView!
    
    
    @IBOutlet var lblTime: UILabel!
=======
>>>>>>> NewStable
    override var backgroundColor: UIColor? {
        didSet {
            customView?.backgroundColor = backgroundColor;
        }
    }
    
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer?;
    
    private var item: ConversationEntry?;
    
<<<<<<< HEAD
    /*private var linkView: UIView? {
=======
    private var linkView: UIView? {
>>>>>>> NewStable
        didSet {
            if let old = oldValue, let new = linkView {
                guard old != new else {
                    return;
                }
            }
            if let view = oldValue {
                view.removeFromSuperview();
            }
            if let view = linkView {
                self.customView.addSubview(view);
                if #available(iOS 13.0, *) {
                    view.addInteraction(UIContextMenuInteraction(delegate: self));
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureDidFire));
        tapGestureRecognizer?.cancelsTouchesInView = false;
        tapGestureRecognizer?.numberOfTapsRequired = 2;
        customView.addGestureRecognizer(tapGestureRecognizer!);
        
        customView.addInteraction(UIContextMenuInteraction(delegate: self));
    }
        
    func set(item: ConversationEntry, url: String, appendix: ChatAttachmentAppendix) {
        self.item = item;
        super.set(item: item);
        
        self.customView?.isOpaque = true;
<<<<<<< HEAD
        self.imgViewOfAttachment = UIImageView()
        self.customView = UIView()
       
=======
//        self.customView?.backgroundColor = self.backgroundColor;
>>>>>>> NewStable
        
         let fileUrl = DownloadStore.instance.url(for: "\(item.id)")
        print(fileUrl)
        do {
            if fileUrl != nil {
                let asset = AVURLAsset(url: fileUrl!, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                self.imgViewOfAttachment.image = UIImage(cgImage: cgImage)
            }
            
        } catch {
            print("ERROR")
        }
<<<<<<< HEAD

           
        
       /*   if let fileUrl = DownloadStore.instance.url(for: "\(item.id)") {

              let imageData:NSData = NSData(contentsOf: fileUrl)!

              let image = UIImage(data: imageData as Data)

              self.imgViewOfAttachment.image = image
                   if let imageProvider = MetadataCache.instance.metadata(for: "\(item.id)")?.imageProvider {
                       self.imgViewOfAttachment.image = UIImage.icon(forFile: fileUrl, mimeType: nil);
                       imageProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { (data, error) in
                           guard let data = data, error == nil else {
                               return;
                           }
                           DispatchQueue.main.async {
//                               guard self.id == item.id else {
//                                   return;
//                               }
                               switch data {
                               case let image as UIImage:
                                   self.imgViewOfAttachment.image = image;
                               case let data as Data:
                                   self.imgViewOfAttachment.image = UIImage(data: data);
                               default:
                                   break;
                               }
                           }
                       });
                   } else if let image = UIImage(contentsOfFile: fileUrl.path) {
                       self.imgViewOfAttachment.image = image;
                   } else {
                       print(fileUrl)
                       if drawPDFfromURL(url: fileUrl) != nil{
                           self.imgViewOfAttachment.image = drawPDFfromURL(url: fileUrl)
                       } else if let thumbnailImage = getThumbnailImage(forUrl: fileUrl) {
                           self.imgViewOfAttachment.image = thumbnailImage
                       }
                       //self.imageField.image = UIImage.icon(forFile: fileUrl, mimeType: nil);
                   }
               } else {
                   if case .attachment(_, let appendix) = item.payload, let mimetype = appendix.mimetype, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimetype as CFString, nil)?.takeRetainedValue() as String? {
                       self.imgViewOfAttachment.image = UIImage.icon(forUTI: uti);
                       
                   } else {
                       self.imgViewOfAttachment.image = UIImage.icon(forUTI: "public.content")
                   }
               }*/
        self.customView.addSubview(self.imgViewOfAttachment)
        NSLayoutConstraint.activate([
            imgViewOfAttachment.topAnchor.constraint(equalTo: self.customView.topAnchor, constant: 0),
            imgViewOfAttachment.bottomAnchor.constraint(equalTo: self.customView.bottomAnchor, constant: 0),
            imgViewOfAttachment.leadingAnchor.constraint(equalTo: self.customView.leadingAnchor, constant: 0),
            imgViewOfAttachment.trailingAnchor.constraint(equalTo: self.customView.trailingAnchor, constant: 0),
            imgViewOfAttachment.heightAnchor.constraint(equalToConstant: 150)
        ]);
        self.contentView.addSubview(self.customView)
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            customView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 30),
            customView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0),
            customView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
            customView.heightAnchor.constraint(equalToConstant: 150)
        ]);
        
        
        
        
      /*  if !(appendix.mimetype?.starts(with: "audio/") ?? false), let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
            print(localUrl)
            let imageview = UIImageView()
            let data = try? Data(contentsOf: localUrl)
            imageView!.image = UIImage(data: data!)
        // let linkView = imageview
            imageview.setContentHuggingPriority(.defaultHigh, for: .vertical);
            imageview.setContentCompressionResistancePriority(.defaultHigh, for: .vertical);
            imageview.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            imageview.translatesAutoresizingMaskIntoConstraints = false;
            imageview.isUserInteractionEnabled = false;
           // self.linkView = linkView
            self.customView.addSubview(imageview)
          
            NSLayoutConstraint.activate([
                imageview.topAnchor.constraint(equalTo: self.customView.topAnchor, constant: 0),
                imageview.bottomAnchor.constraint(equalTo: self.customView.bottomAnchor, constant: 0),
                imageview.leadingAnchor.constraint(equalTo: self.customView.leadingAnchor, constant: 0),
                imageview.trailingAnchor.constraint(equalTo: self.customView.trailingAnchor, constant: 0),
                imageview.heightAnchor.constraint(equalToConstant: 150)
            ]);
            NSLayoutConstraint.activate([
                customView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
                customView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 30),
                customView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0),
                customView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
                customView.heightAnchor.constraint(equalToConstant: 200)
            ]);
          
         //   self.customView.backgroundColor = .red
          //  self.linkView?.backgroundColor = .red
            
            /*documentController = UIDocumentInteractionController(url: localUrl)
=======
        
        if !(appendix.mimetype?.starts(with: "audio/") ?? false), let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
            documentController = UIDocumentInteractionController(url: localUrl);
>>>>>>> NewStable
            var metadata = MetadataCache.instance.metadata(for: "\(item.id)");
            let isNew = metadata == nil;
            if metadata == nil {
                metadata = LPLinkMetadata();
                metadata!.originalURL = localUrl;
            } else {
                metadata!.originalURL = nil;
                //metadata!.url = nil;
                //metadata!.title = "";
                //metadata!.originalURL = localUrl;
                metadata!.url = localUrl;
            }
                
            let linkView = /*(self.linkView as? LPLinkView) ??*/ LPLinkView(metadata: metadata!);
            linkView.setContentHuggingPriority(.defaultHigh, for: .vertical);
            linkView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical);
            linkView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            linkView.translatesAutoresizingMaskIntoConstraints = false;
            linkView.isUserInteractionEnabled = false;

            self.linkView = linkView;
            
            NSLayoutConstraint.activate([
                linkView.topAnchor.constraint(equalTo: self.customView.topAnchor, constant: 0),
                linkView.bottomAnchor.constraint(equalTo: self.customView.bottomAnchor, constant: 0),
                linkView.leadingAnchor.constraint(equalTo: self.customView.leadingAnchor, constant: 0),
                linkView.trailingAnchor.constraint(equalTo: self.customView.trailingAnchor, constant: 0),
                linkView.heightAnchor.constraint(lessThanOrEqualToConstant: 350)
            ]);
                
            if isNew {
                MetadataCache.instance.generateMetadata(for: localUrl, withId: "\(item.id)", completionHandler: { [weak self] meta1 in
                    DispatchQueue.main.async {
                        guard let that = self, meta1 != nil, that.item?.id == item.id else {
                            return;
                        }
                        NotificationCenter.default.post(name: ConversationLogController.REFRESH_CELL, object: that);
                    }
                })
            }
        } else {
            documentController = nil;

<<<<<<< HEAD
            let attachmentInfo =  (self.customView as? AttachmentInfoView) ?? AttachmentInfoView(frame: .zero);//AttachmentInfoView()//
            attachmentInfo.setContentHuggingPriority(.defaultHigh, for: .vertical);
            attachmentInfo.setContentCompressionResistancePriority(.defaultHigh, for: .vertical);
            attachmentInfo.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            attachmentInfo.translatesAutoresizingMaskIntoConstraints = false;
            attachmentInfo.isUserInteractionEnabled = false;
            attachmentInfo.backgroundColor = .green
            self.customView.backgroundColor = .black
            self.customView.addSubview(attachmentInfo)
          //  self.linkView = attachmentInfo;
            NSLayoutConstraint.activate([
                attachmentInfo.topAnchor.constraint(equalTo: self.customView.topAnchor, constant: 0),
                attachmentInfo.bottomAnchor.constraint(equalTo: self.customView.bottomAnchor, constant: 0),
                attachmentInfo.leadingAnchor.constraint(equalTo: self.customView.leadingAnchor, constant: 0),
                attachmentInfo.trailingAnchor.constraint(equalTo: self.customView.trailingAnchor, constant: 0),
                attachmentInfo.heightAnchor.constraint(equalToConstant: 100)
            ]);
            NSLayoutConstraint.activate([
                self.customView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
                self.customView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 30),
                self.customView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0),
                self.customView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
                self.customView.heightAnchor.constraint(equalToConstant: 150)
            ]);
            
            
            
            
            
            
            
            
            
            
           /* NSLayoutConstraint.activate([
                self.customView!.leadingAnchor.constraint(equalTo: attachmentInfo.leadingAnchor),
                self.customView!.trailingAnchor.constraint(greaterThanOrEqualTo: attachmentInfo.trailingAnchor),
                self.customView!.topAnchor.constraint(equalTo: attachmentInfo.topAnchor),
                self.customView!.bottomAnchor.constraint(equalTo: attachmentInfo.bottomAnchor)
            ])*/
//            NSLayoutConstraint.activate([
//                customView.leadingAnchor.constraint(equalTo: attachmentInfo.leadingAnchor),
//                customView.trailingAnchor.constraint(greaterThanOrEqualTo: attachmentInfo.trailingAnchor),
//                customView.topAnchor.constraint(equalTo: attachmentInfo.topAnchor),
//                customView.bottomAnchor.constraint(equalTo: attachmentInfo.bottomAnchor)
//            ])
=======
            let attachmentInfo = (self.linkView as? AttachmentInfoView) ?? AttachmentInfoView(frame: .zero);
            //attachmentInfo.backgroundColor = self.backgroundColor;
            //attachmentInfo.isOpaque = true;

            //attachmentInfo.cellView = self;
            self.linkView = attachmentInfo;
            NSLayoutConstraint.activate([
                customView.leadingAnchor.constraint(equalTo: attachmentInfo.leadingAnchor),
                customView.trailingAnchor.constraint(greaterThanOrEqualTo: attachmentInfo.trailingAnchor),
                customView.topAnchor.constraint(equalTo: attachmentInfo.topAnchor),
                customView.bottomAnchor.constraint(equalTo: attachmentInfo.bottomAnchor)
            ])
>>>>>>> NewStable
            attachmentInfo.set(item: item, url: url, appendix: appendix);

            switch appendix.state {
            case .new:
                if DownloadStore.instance.url(for: "\(item.id)") == nil {
                    let sizeLimit = Settings.fileDownloadSizeLimit;
                    if sizeLimit > 0 {
                        if (DBRosterStore.instance.item(for: item.conversation.account, jid: JID(item.conversation.jid))?.subscription ?? .none).isFrom || (DBChatStore.instance.conversation(for: item.conversation.account, with: item.conversation.jid) as? Room != nil) {
                            _ = DownloadManager.instance.download(item: item, url: url, maxSize: sizeLimit >= Int.max ? Int64.max : Int64(sizeLimit * 1024 * 1024));
                            attachmentInfo.progress(show: true);
                            return;
                        }
                    }
                    attachmentInfo.progress(show: DownloadManager.instance.downloadInProgress(for: item));
                }
            default:
                attachmentInfo.progress(show: DownloadManager.instance.downloadInProgress(for: item));
            }
        }*/
    }
    
    //Thumbnail image of pdf
     func drawPDFfromURL(url: URL) -> UIImage? {
         guard let document = CGPDFDocument(url as CFURL) else { return nil }
         guard let page = document.page(at: 1) else { return nil }

         let pageRect = page.getBoxRect(.mediaBox)
         let renderer = UIGraphicsImageRenderer(size: pageRect.size)
         let img = renderer.image { ctx in
             UIColor.white.set()
             ctx.fill(pageRect)

             ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
             ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

             ctx.cgContext.drawPDFPage(page)
         }

         return img
     }
     
     //Thumbnail image of video
     func getThumbnailImage(forUrl url: URL) -> UIImage? {
         let asset: AVAsset = AVAsset(url: url)
         let imageGenerator = AVAssetImageGenerator(asset: asset)

         do {
             let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
             return UIImage(cgImage: thumbnailImage)
             //return UIImage(systemName: thumbnailImage as! String)
         } catch let error {
             print(error)
         }

         return nil
     }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            return self.prepareContextMenu();
        };
    }
    
    func prepareContextMenu() -> UIMenu {
        guard let item = self.item, case .attachment(let url, _) = item.payload else {
            return UIMenu(title: "");
        }
        
        if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
            let items = [
                UIAction(title: NSLocalizedString("Preview", comment: "attachment cell context action"), image: UIImage(systemName: "eye.fill"), handler: { action in
                    self.open(url: localUrl, preview: true);
                }),
                UIAction(title: NSLocalizedString("Copy", comment: "attachment cell context action"), image: UIImage(systemName: "doc.on.doc"), handler: { action in
                    UIPasteboard.general.strings = [url];
                    UIPasteboard.general.string = url;
                }),
                UIAction(title: NSLocalizedString("Share..", comment: "attachment cell context action"), image: UIImage(systemName: "square.and.arrow.up"), handler: { action in
                    self.open(url: localUrl, preview: false);
                }),
                UIAction(title: NSLocalizedString("Delete", comment: "attachment cell context action"), image: UIImage(systemName: "trash"), attributes: [.destructive], handler: { action in
                    DownloadStore.instance.deleteFile(for: "\(item.id)");
                    DBChatHistoryStore.instance.updateItem(for: item.conversation, id: item.id, updateAppendix: { appendix in
                        appendix.state = .removed;
                    })
                }),
                UIAction(title: NSLocalizedString("More..", comment: "attachment cell context action"), image: UIImage(systemName: "ellipsis"), handler: { action in
                    NotificationCenter.default.post(name: Notification.Name("tableViewCellShowEditToolbar"), object: self);
                })
            ];
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items);
        } else {
            let items = [
                UIAction(title: NSLocalizedString("Copy", comment: "attachment cell context action"), image: UIImage(systemName: "doc.on.doc"), handler: { action in
                    UIPasteboard.general.strings = [url];
                    UIPasteboard.general.string = url;
                }),
                UIAction(title: NSLocalizedString("Download", comment: "attachment cell context action"), image: UIImage(systemName: "square.and.arrow.down"), handler: { action in
                    self.download(for: item);
                }),
                UIAction(title: NSLocalizedString("More..", comment: "attachment cell context action"), image: UIImage(systemName: "ellipsis"), handler: { action in
                    NotificationCenter.default.post(name: Notification.Name("tableViewCellShowEditToolbar"), object: self);
                })
            ];
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items);
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse();
        (self.linkView as? AttachmentInfoView)?.prepareForReuse();
    }
        
    @objc func tapGestureDidFire(_ recognizer: UITapGestureRecognizer) {
        downloadOrOpen();
    }
    
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
        }
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        let rootViewController = ((UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController)!;
        if let viewController = rootViewController.presentingViewController {
            return viewController;
        }
        return rootViewController;
    }
    
    func open(url: URL, preview: Bool) {
        let documentController = UIDocumentInteractionController(url: url);
        documentController.delegate = self;
        if preview && documentController.presentPreview(animated: true) {
            self.documentController = documentController;
        } else if documentController.presentOptionsMenu(from: self.superview?.convert(self.frame, to: self.superview?.superview) ?? CGRect.zero, in: self.self, animated: true) {
            self.documentController = documentController;
        }
    }
    
    func download(for item: ConversationEntry) {
        guard let item = self.item, case .attachment(let url, _) = item.payload else {
            return;
        }
        _ = DownloadManager.instance.download(item: item, url: url, maxSize: Int64.max);
        (self.linkView as? AttachmentInfoView)?.progress(show: true);
    }
    
    private func downloadOrOpen() {
        guard let item = self.item else {
            return;
        }
        if let localUrl = DownloadStore.instance.url(for: "\(item.id)") {
//            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent(localUrl.lastPathComponent);
//            try? FileManager.default.copyItem(at: localUrl, to: tmpUrl);
            open(url: localUrl, preview: true);
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Download", comment: "confirmation dialog title"), message: NSLocalizedString("File is not available locally. Should it be downloaded?", comment: "confirmation dialog body"), preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "button label"), style: .default, handler: { (action) in
                self.download(for: item);
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "button label"), style: .cancel, handler: nil));
            if let controller = (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController {
                controller.present(alert, animated: true, completion: nil);
            }
        }
    }
        
    class AttachmentInfoView: UIView, AVAudioPlayerDelegate {
        
        let iconView: ImageAttachmentPreview;
        let filename: UILabel;
        let details: UILabel;
        let actionButton: UIButton;
        
        private var viewType: ViewType = .none {
            didSet {
                guard viewType != oldValue else {
                    return;
                }
                switch oldValue {
                case .none:
                    break;
                case .audioFile:
                    NSLayoutConstraint.deactivate(audioFileViewConstraints);
                case .file:
                    NSLayoutConstraint.deactivate(fileViewConstraints);
                case .imagePreview:
                    NSLayoutConstraint.deactivate(imagePreviewConstraints);
                }
                switch viewType {
                case .none:
                    break;
                case .audioFile:
                    NSLayoutConstraint.activate(audioFileViewConstraints);
                case .file:
                    NSLayoutConstraint.activate(fileViewConstraints);
                case .imagePreview:
                    NSLayoutConstraint.activate(imagePreviewConstraints);
                }
                iconView.contentMode = viewType == .imagePreview ? .scaleAspectFill : .scaleAspectFit;
                iconView.isImagePreview = viewType == .imagePreview;
            }
        }
        
        private var fileViewConstraints: [NSLayoutConstraint] = [];
        private var imagePreviewConstraints: [NSLayoutConstraint] = [];
        private var audioFileViewConstraints: [NSLayoutConstraint] = [];
        
        private static var labelFont: UIFont {
            let font = UIFont.preferredFont(forTextStyle: .headline);
            return font.withSize(font.pointSize - 2);
        }
        
        private static var detailsFont: UIFont {
            let font = UIFont.preferredFont(forTextStyle: .subheadline);
            return font.withSize(font.pointSize - 2);
        }
        
        private var fileUrl: URL?;

        override init(frame: CGRect) {
            iconView = ImageAttachmentPreview(frame: .zero);
            iconView.clipsToBounds = true
            iconView.image = UIImage(named: "defaultAvatar")!;
            iconView.translatesAutoresizingMaskIntoConstraints = false;
            iconView.setContentHuggingPriority(.defaultHigh, for: .vertical);
            iconView.setContentHuggingPriority(.defaultHigh, for: .horizontal);
            iconView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical);
            iconView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);

            filename = UILabel(frame: .zero);
            filename.numberOfLines = 0
            filename.font = AttachmentInfoView.labelFont//.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .semibold);
//            filename.adjustsFontForContentSizeCategory = true;
            filename.translatesAutoresizingMaskIntoConstraints = false;
            filename.setContentHuggingPriority(.defaultHigh, for: .horizontal);
            filename.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            filename.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            
            details = UILabel(frame: .zero);
            details.font = AttachmentInfoView.detailsFont// UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .regular);
//            details.adjustsFontForContentSizeCategory = true;
            details.textColor = UIColor.secondaryLabel;
            details.translatesAutoresizingMaskIntoConstraints = false;
            details.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            details.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal);
            details.numberOfLines = 0;

            actionButton = UIButton.systemButton(with: UIImage(systemName: "play.circle.fill")!, target: nil, action: nil);
            actionButton.translatesAutoresizingMaskIntoConstraints = false;
            actionButton.tintColor = UIColor(named: "tintColor");
            
            super.init(frame: frame);
            self.clipsToBounds = true
            self.translatesAutoresizingMaskIntoConstraints = false;
            self.isOpaque = false;
            
            addSubview(iconView);
            addSubview(filename);
            addSubview(details);
            addSubview(actionButton);
            
            fileViewConstraints = [
                iconView.heightAnchor.constraint(equalToConstant: 30),
                iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
                
                iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
                iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                iconView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8),
//                iconView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8),
                
                filename.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
                filename.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
                filename.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -10),
                
                details.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
                details.topAnchor.constraint(equalTo: filename.bottomAnchor, constant: 4),
                details.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                // -- this is causing issue with progress indicatior!!
                details.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -10),
                details.heightAnchor.constraint(equalTo: filename.heightAnchor),
                
                actionButton.heightAnchor.constraint(equalToConstant: 0),
                actionButton.widthAnchor.constraint(equalToConstant: 0),
                actionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
                actionButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ];
            
            audioFileViewConstraints = [
                iconView.heightAnchor.constraint(equalToConstant: 30),
                iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
                
                iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
                iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                iconView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8),
//                iconView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8),
                
                filename.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
                filename.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
                filename.trailingAnchor.constraint(lessThanOrEqualTo: self.actionButton.leadingAnchor, constant: -10),
                
                details.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
                details.topAnchor.constraint(equalTo: filename.bottomAnchor, constant: 4),
                details.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                // -- this is causing issue with progress indicatior!!
                details.trailingAnchor.constraint(lessThanOrEqualTo: self.actionButton.leadingAnchor, constant: -10),
                
                actionButton.heightAnchor.constraint(equalToConstant: 30),
                actionButton.widthAnchor.constraint(equalTo: actionButton.heightAnchor),
                actionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
                actionButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                actionButton.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8)
            ];
            
            imagePreviewConstraints = [
                iconView.widthAnchor.constraint(lessThanOrEqualToConstant: 350),
                iconView.heightAnchor.constraint(lessThanOrEqualToConstant: 350),
                iconView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                iconView.heightAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                
                iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                iconView.topAnchor.constraint(equalTo: self.topAnchor),
                iconView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                
                filename.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                filename.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
                filename.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16),
                
                details.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                details.topAnchor.constraint(equalTo: filename.bottomAnchor, constant: 4),
                details.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
                details.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16),
                details.heightAnchor.constraint(equalTo: filename.heightAnchor),
                
                actionButton.heightAnchor.constraint(equalToConstant: 0),
                actionButton.widthAnchor.constraint(equalToConstant: 0),
                actionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
                actionButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ];
            
            actionButton.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside);
        }
        
        required init?(coder: NSCoder) {
            return nil;
        }

        func prepareForReuse() {
            self.stopPlayingAudio();
        }
        
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 10);
            path.addClip();
            UIColor.secondarySystemFill.setFill();
            path.fill();
            
            super.draw(rect);
        }
        
        static let timeFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter();
            formatter.unitsStyle = .abbreviated;
            formatter.zeroFormattingBehavior = .dropAll;
            formatter.allowedUnits = [.minute,.second]
            return formatter;
        }();
        
        func set(item: ConversationEntry, url: String, appendix: ChatAttachmentAppendix) {
            self.fileUrl = DownloadStore.instance.url(for: "\(item.id)");
            if let fileUrl = self.fileUrl {
                filename.text = fileUrl.lastPathComponent;
                let fileSize = fileSizeToString(try! FileManager.default.attributesOfItem(atPath: fileUrl.path)[.size] as? UInt64);
                if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileUrl.pathExtension as CFString, nil)?.takeRetainedValue(), let typeName = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
                    details.text = "\(typeName) - \(fileSize)";
                    if UTTypeConformsTo(uti, kUTTypeImage) {
                        self.viewType = .imagePreview;
                        iconView.image = UIImage(contentsOfFile: fileUrl.path)!;
                    } else if UTTypeConformsTo(uti, kUTTypeAudio) {
                        self.viewType = .audioFile;
                        let asset = AVURLAsset(url: fileUrl);
                        asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                            DispatchQueue.main.async {
                                guard self.fileUrl == fileUrl else {
                                    return;
                                }
                                if asset.duration != .invalid && asset.duration != .zero {
                                    let length = CMTimeGetSeconds(asset.duration);
                                    if let lengthStr = AttachmentInfoView.timeFormatter.string(from: length) {
                                        self.details.text = "\(typeName) - \(fileSize) - \(lengthStr)";
                                    }
                                }
                            }
                        });
                        iconView.image = UIImage.icon(forUTI: uti as String) ?? UIImage.icon(forFile: fileUrl, mimeType: appendix.mimetype);
                    } else {
                        self.viewType = .file;
                        iconView.image = UIImage.icon(forFile: fileUrl, mimeType: appendix.mimetype);
                    }
                } else if let mimetype = appendix.mimetype, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimetype as CFString, nil)?.takeRetainedValue(), let typeName = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
                    details.text = "\(typeName) - \(fileSize)";
                    iconView.image = UIImage.icon(forUTI: uti as String) ?? UIImage.icon(forFile: fileUrl, mimeType: appendix.mimetype);
                    self.viewType = .file;
                } else {
                    details.text = String.localizedStringWithFormat(NSLocalizedString("File - %@", comment: "file size label"), fileSize);
                    iconView.image = UIImage.icon(forFile: fileUrl, mimeType: appendix.mimetype);
                    self.viewType = .file;
                }
            } else {
                let filename = appendix.filename ?? URL(string: url)?.lastPathComponent ?? "";
                if filename.isEmpty {
                    self.filename.text = NSLocalizedString("Unknown file", comment: "unknown file label");
                } else {
                    self.filename.text = filename;
                }
                if let size = appendix.filesize {
                    if let mimetype = appendix.mimetype, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimetype as CFString, nil)?.takeRetainedValue(), let typeName = UTTypeCopyDescription(uti)?.takeRetainedValue() as String? {
                        let fileSize = size >= 0 ? fileSizeToString(UInt64(size)) : "";
                        details.text = "\(typeName) - \(fileSize)";
                        iconView.image = UIImage.icon(forUTI: uti as String);
                    } else {
                        details.text = String.localizedStringWithFormat(NSLocalizedString("File - %@", comment: "file size label"),fileSizeToString(UInt64(size)));
                        iconView.image = UIImage.icon(forUTI: "public.content");
                    }
                } else {
                    details.text = "--";
                    iconView.image = UIImage.icon(forUTI: "public.content");
                }
                self.viewType = .file;
            }
        }
        
        var progressView: UIActivityIndicatorView?;
        
        func progress(show: Bool) {
            print(show)
            guard show != (progressView != nil) else {
                return;
            }
            
            if show {
                let view = UIActivityIndicatorView(style: .medium);
                view.translatesAutoresizingMaskIntoConstraints = false;
                self.addSubview(view);
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: filename.trailingAnchor, constant: 8),
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: details.trailingAnchor, constant: 8),
                    view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
                    view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    view.topAnchor.constraint(lessThanOrEqualTo: self.topAnchor)
                ])
                self.progressView = view;
                view.startAnimating();
            } else if let view = progressView {
                view.stopAnimating();
                self.progressView = nil;
                view.removeFromSuperview();
            }
        }

        
        func fileSizeToString(_ sizeIn: UInt64?) -> String {
            guard let size = sizeIn else {
                return "";
            }
            let formatter = ByteCountFormatter();
            formatter.countStyle = .file;
            return formatter.string(fromByteCount: Int64(size));
        }
        
        enum ViewType {
            case none
            case file
            case imagePreview
            case audioFile
        }
        
        private var audioPlayer: AVAudioPlayer?;
        
        private func startPlayingAudio() {
            stopPlayingAudio();
            guard let fileUrl = self.fileUrl else {
                return;
            }
            do {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default);
                try? AVAudioSession.sharedInstance().setActive(true);
                audioPlayer = try AVAudioPlayer(contentsOf: fileUrl);
                audioPlayer?.delegate = self;
                audioPlayer?.volume = 1.0;
                audioPlayer?.play();
                self.actionButton.setImage(UIImage(systemName: "pause.circle.fill")!, for: .normal);
            } catch {
                self.stopPlayingAudio();
            }
        }
        
        private func stopPlayingAudio() {
            audioPlayer?.stop();
            audioPlayer = nil;
            self.actionButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal);
        }
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            audioPlayer?.stop();
            audioPlayer = nil;
            self.actionButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal);
        }
        
        @objc func actionTapped(_ sender: Any) {
            if audioPlayer == nil {
                self.startPlayingAudio();
            } else {
                self.stopPlayingAudio();
            }
        }
    }
}

class ImageAttachmentPreview: UIImageView {
    
    var isImagePreview: Bool = false {
        didSet {
            if isImagePreview != oldValue {
                if isImagePreview {
                    self.layer.cornerRadius = 10;
                    self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner];
                } else {
                    self.layer.cornerRadius = 0;
                    self.layer.maskedCorners = [];
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FileManager {
    public func fileExtension(forUTI utiString: String) -> String? {
        guard
            let cfFileExtension = UTTypeCopyPreferredTagWithClass(utiString as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() else
        {
            return nil
        }

        return cfFileExtension as String
    }
}

extension UIImage {
    class func icon(forFile url: URL, mimeType: String?) -> UIImage? {
        let controller = UIDocumentInteractionController(url: url);
        if mimeType != nil, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType! as CFString, nil)?.takeRetainedValue() as String? {
            controller.uti = uti;
        }
        if controller.icons.count == 0 {
            controller.uti = "public.data";
        }
        let icons = controller.icons;
        return icons.last;
    }

    class func icon(forUTI utiString: String) -> UIImage? {
        let controller = UIDocumentInteractionController(url: URL(fileURLWithPath: "temp.file"));
        controller.uti = utiString;
        if controller.icons.count == 0 {
            controller.uti = "public.data";
        }
        let icons = controller.icons;
        return icons.last;
    }
    
}


