//
// AddAccountController.swift
//
// Siskin IM
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
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
import Combine
import Shared
import CryptoSwift
class AddAccountController: UITableViewController, UITextFieldDelegate {
    
    var account:String?;
   
    @IBOutlet var jidTextField: UITextField!
    
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var cancelButton: UIBarButtonItem!;
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    
    @objc open var Username:String?
    @objc open var AuthenicationCode:String?
    @objc open var jwsToken:String?
    @objc open var NonceSalt:String?
    @objc open var DeviceID:String?
    var errorStatus:String?
    var activityInditcator: UIActivityIndicatorView?;
    
    var xmppClient: XMPPClient?;
    
    var accountValidatorTask: AccountValidatorTask?;
    
//    var onAccountAdded: (() -> Void)?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        if account != nil {
            jidTextField.text = account;
            passwordTextField.text = AccountManager.getAccountPassword(for: BareJID(account)!);
            jidTextField.isEnabled = false;
        } else {
            navigationController?.navigationItem.leftBarButtonItem = nil;
        }

        saveButton.title = "Save";
        jidTextField.delegate = self;
        passwordTextField.delegate = self;

        jidTextField.keyboardType = .emailAddress;
        if #available(iOS 11.0, *) {
            jidTextField.textContentType = .username;
            passwordTextField.textContentType = .password;
        };
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        updateSaveButtonState();
        self.jidTextField.text = self.Username! + "@ej.gigsp.co"
        let AuthenticationSalt = String(self.AuthenicationCode!.suffix(6))
       // let Authendata = self.AuthenicationCode! + AuthenticationSalt
        let AuthenticationData: Array<UInt8> = Array(self.AuthenicationCode!.utf8)
        let Payloadsalt: Array<UInt8> = Array(AuthenticationSalt.utf8)
        let result = try! HMAC(key: Payloadsalt, variant: .sha256).authenticate(AuthenticationData)
        let hashdata = Data(result)
        var hmacHash = hexStringFromData(input: hashdata as NSData)
            hmacHash = hmacHash.lowercased()
        self.passwordTextField.text = hmacHash
           var uuid = NSUUID().uuidString.lowercased()
            uuid = uuid.replacingOccurrences(of: "-", with: "", options: NSString.CompareOptions.literal, range: nil)
            self.SendUserPresence(userName: self.Username!, Nonce: uuid) { (status) in
                if (status == true){
                    self.validateAccount()
                }else{
                    
                        if (self.errorStatus!.contains("0x2001")){
                            self.LoginErrorAlert(Message: "OTP Not Sent")
                           // self.passwordTF?.errorLabel.text = "OTP Not Sent"
                        }else if (self.errorStatus!.contains("0x3112")){
                            self.LoginErrorAlert(Message: "Unauthorized Contact Admin")
                            //self.passwordTF?.errorLabel.text = "Unauthorized"
                        }else if (self.errorStatus!.contains("0x3113")){
                            self.LoginErrorAlert(Message: "Cannot create Session Already Logged In")
                           // self.passwordTF?.errorLabel.text = "Already Logged in"
                        }else if (self.errorStatus!.contains("0x3114")){
                            self.LoginErrorAlert(Message: "WrongOTP")
                          //  self.passwordTF?.errorLabel.text =  "Wrong OTP"
                        }else if (self.errorStatus!.contains("0x3115")){
                            self.LoginErrorAlert(Message: "Account Banned Contact Admin to free Account ")
                           // self.passwordTF?.errorLabel.text = "Account Banned"
                            
                        }else if (self.errorStatus!.contains("0x3116")){
                            self.LoginErrorAlert(Message: "Your IP Address is Blocked")
                           // self.passwordTF?.errorLabel.text = "IP address blocked"
                        }else if (self.errorStatus!.contains("0x3117")){
                            self.LoginErrorAlert(Message: "Account Not found")
                           // self.passwordTF?.errorLabel.text = "Account Not Found"
                        }
                        self.dismiss(animated: true, completion: nil)
                      
                 
                   
                }
            }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        onAccountAdded = nil;
        super.viewWillDisappear(animated);
    }
    
    @IBAction func jidTextFieldChanged(_ sender: UITextField) {
        updateSaveButtonState();
    }
    
    @IBAction func passwordTextFieldChanged(_ sender: AnyObject) {
        updateSaveButtonState();
    }

    func updateSaveButtonState() {
        let disable = (jidTextField.text?.isEmpty ?? true) || (passwordTextField.text?.isEmpty ?? true);
        saveButton.isEnabled = !disable;
    }
    
    @IBAction func saveClicked(_ sender: UIBarButtonItem) {
        //saveAccount();
        validateAccount();
    }
    
    func validateAccount() {
        DispatchQueue.main.async {
            guard let jid = BareJID(self.jidTextField.text), let password = self.passwordTextField.text, !password.isEmpty else {
                return;
            }
            
            self.saveButton.isEnabled = false;
            self.showIndicator();
            
            self.accountValidatorTask = AccountValidatorTask(controller: self);
            self.accountValidatorTask?.check(account: jid, password: password, callback: self.handleResult);
        }
       
    }
    
    func LoginErrorAlert(Message:String){
        let alert = UIAlertController(title: "Warning", message: Message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveAccount(acceptedCertificate: SslCertificateInfo?) {
        print("sign in button clicked");
        guard let jid = BareJID(jidTextField.text) else {
            return;
        }
        var account = AccountManager.getAccount(for: jid) ?? AccountManager.Account(name: jid);
        account.acceptCertificate(acceptedCertificate);
        account.password = passwordTextField.text!;

        var cancellables: Set<AnyCancellable> = [];
        do {
            
            
            
            try AccountManager.save(account: account);
           
            self.dismissView();
            (UIApplication.shared.delegate as? AppDelegate)?.showSetup(value: false);
        } catch {
            self.hideIndicator();
            cancellables.removeAll();
            let alert = UIAlertController(title: "Error", message: "It was not possible to save account details: \(error)", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "OK", style: .default));
            self.present(alert, animated: true, completion: nil);
        }
    }
    
    @IBAction func cancelClicked(_ sender: UIBarButtonItem) {
        dismissView();
    }
    
    func dismissView() {
        
        
        let dismiss = self.view.window?.rootViewController is SetupViewController;
//        onAccountAdded = nil;
        accountValidatorTask?.finish();
        accountValidatorTask = nil;
        
        if dismiss {
            navigationController?.dismiss(animated: true, completion: nil);
        } else {
            let newController = navigationController?.popViewController(animated: true);
            if newController == nil || newController != self {
                
                let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController") as! UINavigationController
                       let controller1 = AccountSettingsViewController.instantiate(fromAppStoryboard: .Account);
                       let accounts = AccountManager.getAccounts();
                       controller1.hidesBottomBarWhenPushed = true;
                       controller1.account = accounts[0];
                       controller.pushViewController(controller1, animated: true)
                       self.showDetailViewController(controller1, sender: self)
                   //    self.present(controller, animated: true, completion: nil);
                
                
                
               /* let emptyDetailController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "emptyDetailViewController");
                self.showDetailViewController(emptyDetailController, sender: self);*/
            }
        }
        
    }
    
    func hexStringFromData(input: NSData) -> String {
           var bytes = [UInt8](repeating: 0, count: input.length)
           input.getBytes(&bytes, length: input.length)
           
           var hexString = ""
           for byte in bytes {
               hexString += String(format:"%02X", UInt8(byte))
           }
           
           return hexString
       }
    
   func getPostString(params:[String:Any]) -> String
       {
           var data = [String]()
           for(key, value) in params
           {
               data.append(key + "=\(value)")
           }
           return data.map { String($0) }.joined(separator: "&")
       }
    
    func SendUserPresence(userName:String,Nonce:String, completion: @escaping (_ success: Bool) -> ()){
     
     var Status:Bool = false
     let Authorization = "Bearer TN5sBit7LEZEICw6ws8NG6NjiCHmzzdc"
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: now)
     var deviceId = UIDevice.current.identifierForVendor!.uuidString
     deviceId = deviceId.replacingOccurrences(of: "-", with: "", options: NSString.CompareOptions.literal, range: nil)
        let token = userName + deviceId + Nonce + dateString + self.NonceSalt!
     let PayloadData: Array<UInt8> = Array(token.utf8)
        let Payloadsalt: Array<UInt8> = Array(self.NonceSalt!.utf8)
     do {
         let result = try! HMAC(key: Payloadsalt, variant: .sha256).authenticate(PayloadData)
         let hashdata = Data(result)
         var hmacHash = hexStringFromData(input: hashdata as NSData)
         hmacHash = hmacHash.lowercased()
        let userdata : Data = "username=\(userName)&deviceid=\(deviceId)&nonce=\(Nonce)&token=\(hmacHash)".data(using: .utf8)!
        let apidata: [String: Any] = ["username":userName,"deviceid":deviceId,"nonce":Nonce,"timestamp":dateString,"token":hmacHash]
        let jsonData = try? JSONSerialization.data(withJSONObject: apidata)
         let urlstring = URL(string: "https://ej.gigsp.co:5222/sendpresence")

            var urlrequest = URLRequest(url: urlstring!)
                        urlrequest.httpMethod = "POST"
         urlrequest.httpBody = jsonData
         urlrequest.setValue(Authorization, forHTTPHeaderField: "Authorization")
       //  urlrequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        let session = URLSession.shared
                        let task = session.dataTask(with: urlrequest, completionHandler: { data, response, error in

                            guard let data = data, error == nil else {
                                print("error=\(error)")
                               Status = false
                                print(Status)

                                return
                            }
                            if let response = response {
                                let nsHTTPResponse = response as! HTTPURLResponse
                                let statusCode = nsHTTPResponse.statusCode
                                if statusCode == 200 {
                                Status = true

                                   //return true
                                }else{
                                 Status = false
                                   
                                }
                            }

                          do {
                            let json = try JSONSerialization.jsonObject(with: data,options:[]) as? [String:Any]
                                print(json)
                             let status = json?["status"] as? String
    //
                            print(status)
                             if (status!.contains("SUCCESS")){
                                 Status = true
                            }else if (status!.contains("ERROR:")){
                             Status = false
                                self.errorStatus = status
                            }}
                    catch {
                        print("cant parse json \(error)")
                        Status = false
                        }

                            completion(Status)
                        }).resume()
     } catch {
         print(error.localizedDescription)
     }
     }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 && indexPath.row == 0 && !jidTextField.isEnabled {
            return nil;
        }
        return indexPath;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == jidTextField {
            passwordTextField.becomeFirstResponder();
        } else {
            DispatchQueue.main.async {
                self.validateAccount();
            }
        }
        textField.resignFirstResponder();
        return false;
    }
    
    func handleResult(result: Result<Void,ErrorCondition>) {
        let acceptedCertificate = accountValidatorTask?.acceptedCertificate;
        self.accountValidatorTask = nil;
        switch result {
        case .failure(let errorCondition):
            self.hideIndicator();
            self.saveButton.isEnabled = true;
            var error = "";
            switch errorCondition {
            case .not_authorized:
                error = "Login and password do not match.";
            default:
                error = "It was not possible to contact XMPP server and sign in.";
            }
            let alert = UIAlertController(title: "Error", message:  error, preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil));
            self.present(alert, animated: true, completion: nil);
        case .success(_):
            self.saveAccount(acceptedCertificate: acceptedCertificate);
            //self.AddBotRoaster()
            
//            let account =
        }
    }
    
    func AddBotRoaster() {
        
        let jid = JID("enhanced-apk@ej.gigsp.co");
        let account = BareJID(jidTextField.text)!;
        if let account = AccountManager.getActiveAccounts().first?.name {
            guard let client = XmppService.instance.getClient(for: account) else {
                        return;
                    }
                   
                    
                    let resultHandler = { (result: Result<Iq, XMPPError>) in
                        switch result {
                        case .success(_):
                           
                            DispatchQueue.main.async {
                               // self.dismissView();
                            }
                        case .failure(let error):
                            DispatchQueue.main.async {
                                let alert = UIAlertController.init(title: "Failure", message: "Server returned error: \(error)", preferredStyle: .alert);
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil));
                                self.present(alert, animated: true, completion: nil);
                            }
                        }
                    };
                    
            if let rosterItem = DBRosterStore.instance.item(for: client, jid: jid) {
                        if rosterItem.name == "Bot" {
                          //  updateSubscriptions(client: client);
                           // self.dismissView();
                        } else {
                            client.module(.roster).updateItem(jid: jid, name: "Bot", groups: rosterItem.groups, completionHandler: resultHandler);
                        }
                    } else {
                        client.module(.roster).addItem(jid: jid, name: "Bot", groups: [], completionHandler: resultHandler);
                    }
        }
       

    }
    
    func showIndicator() {
        if activityInditcator != nil {
            hideIndicator();
        }
        activityInditcator = UIActivityIndicatorView(style: .medium);
        activityInditcator?.center = CGPoint(x: view.frame.width/2, y: view.frame.height/2);
        activityInditcator!.isHidden = false;
        activityInditcator!.startAnimating();
        view.addSubview(activityInditcator!);
        view.bringSubviewToFront(activityInditcator!);
    }
    
    func hideIndicator() {
        activityInditcator?.stopAnimating();
        activityInditcator?.removeFromSuperview();
        activityInditcator = nil;
    }
    
    class AccountValidatorTask: EventHandler {
        
        private var cancellables: Set<AnyCancellable> = [];
        var client: XMPPClient? {
            willSet {
                if newValue != nil {
                    newValue?.eventBus.register(handler: self, for: SaslModule.SaslAuthSuccessEvent.TYPE, SaslModule.SaslAuthFailedEvent.TYPE);
                }
            }
            didSet {
                cancellables.removeAll();
                if oldValue != nil {
                    _ = oldValue?.disconnect(true);
                    oldValue?.eventBus.unregister(handler: self, for: SaslModule.SaslAuthSuccessEvent.TYPE, SaslModule.SaslAuthFailedEvent.TYPE);
                }
                client?.$state.sink(receiveValue: { [weak self] state in self?.changedState(state) }).store(in: &cancellables);
            }
        }
        
        var callback: ((Result<Void,ErrorCondition>)->Void)? = nil;
        weak var controller: UIViewController?;
        var dispatchQueue = DispatchQueue(label: "accountValidatorSync");
        
        var acceptedCertificate: SslCertificateInfo? = nil;
        
        init(controller: UIViewController) {
            self.controller = controller;
            initClient();
        }
        
        fileprivate func initClient() {
            self.client = XMPPClient();
            _ = client?.modulesManager.register(StreamFeaturesModule());
            _ = client?.modulesManager.register(SaslModule());
            _ = client?.modulesManager.register(AuthModule());
        }
        
        public func check(account: BareJID, password: String, callback: @escaping (Result<Void,ErrorCondition>)->Void) {
            self.callback = callback;
            client?.connectionConfiguration.userJid = account;
            client?.connectionConfiguration.credentials = .password(password: password, authenticationName: nil, cache: nil);
            client?.login();
        }
        
        public func handle(event: Event) {
            dispatchQueue.sync {
                guard let callback = self.callback else {
                    return;
                }
                var param: ErrorCondition? = nil;
                switch event {
                case is SaslModule.SaslAuthSuccessEvent:
                    param = nil;
                case is SaslModule.SaslAuthFailedEvent:
                    param = ErrorCondition.not_authorized;
                default:
                    param = ErrorCondition.service_unavailable;
                }
                
                DispatchQueue.main.async {
                    if let error = param {
                        callback(.failure(error));
                    } else {
                        callback(.success(Void()));
                    }
                }
                self.finish();
            }
        }
        
        func changedState(_ state: XMPPClient.State) {
            dispatchQueue.sync {
                guard let callback = self.callback else {
                    return;
                }
                
                switch state {
                case .disconnected(let reason):
                    switch reason {
                    case .sslCertError(let trust):
                        self.callback = nil;
                        let certData = SslCertificateInfo(trust: trust);
                        let alert = CertificateErrorAlert.create(domain: self.client!.sessionObject.userBareJid!.domain, certData: certData, onAccept: {
                            self.acceptedCertificate = certData;
                            self.client?.connectionConfiguration.modifyConnectorOptions(type: SocketConnectorNetwork.Options.self, { options in
                                options.networkProcessorProviders.append(SSLProcessorProvider());
                                options.sslCertificateValidation = .fingerprint(certData.details.fingerprintSha1);
                            });
                            self.callback = callback;
                            self.client?.login();
                        }, onDeny: {
                            self.finish();
                            callback(.failure(ErrorCondition.service_unavailable));
                        })
                        DispatchQueue.main.async {
                            self.controller?.present(alert, animated: true, completion: nil);
                        }
                        return;
                    default:
                        break;
                    }
                    DispatchQueue.main.async {
                        callback(.failure(.service_unavailable));
                    }
                    self.finish();
                default:
                    break;
                }
            }
        }
        
        public func finish() {
            self.callback = nil;
            self.client = nil;
            self.controller = nil;
        }
    }
}
