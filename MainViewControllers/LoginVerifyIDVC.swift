//
//  LoginIdVerifyVC.swift
//  ChatSecureCore
//
//  Created by apple on 26/05/21.
//  Copyright © 2021 Chris Ballinger. All rights reserved.
//

import UIKit
import TransitionButton

import CryptoKit
import CryptoSwift
let inactiveFieldBorderColor = UIColor(white: 1, alpha: 0.3)
let textBackgroundColor = UIColor(white: 1, alpha: 0.5)

class LoginIdVerifyVC: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var firstField: UITextField!
    
    @IBOutlet weak var NinthField: UITextField!
    @IBOutlet weak var sixthfield: UITextField!
    @IBOutlet weak var fifthfield: UITextField!
 
    @IBOutlet weak var eigthFiled: UITextField!
   
    @IBOutlet weak var sevenfield: UITextField!
    @IBOutlet weak var fourthField: UITextField!
    
    @IBOutlet weak var thirdField: UITextField!
    @IBOutlet weak var secondField: UITextField!
    
    @IBOutlet weak var OTPInputView: UIView!
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    
    var VerificationString: String?
    var DeviceID:String?
    var username:String?
    var Password:String?
    var JWSToken:String?
    var NonceSalt:String?
    var errorStatus:String?
    let button = TransitionButton(frame: CGRect(x: (UIScreen.main.bounds.size.width / 2 ) - 50, y: 350, width: 100, height: 40))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        self.OTPInputView.fieldsCount = 9
//                self.OTPInputView.fieldBorderWidth = 2
//                self.OTPInputView.defaultBorderColor = UIColor.white
//        self.OTPInputView.filledBorderColor = AppColors.lightGreen
//                self.OTPInputView.cursorColor = UIColor.red
//        self.OTPInputView.backgroundColor = UIColor.lightGray
//        self.OTPInputView.layer.cornerRadius = 10
//                self.OTPInputView.displayType = .roundedCorner
//                self.OTPInputView.fieldSize = 40
//                self.OTPInputView.separatorSpace = 8
//                self.OTPInputView.shouldAllowIntermediateEditing = false
//                self.OTPInputView.delegate = self
//                self.OTPInputView.initializeUI()
       // self.OTPInputView.layer.borderColor = AppColors.lightGreen.cgColor
       // self.OTPInputView.layer.cornerRadius = 10
        self.OTPInputView.backgroundColor = AppColors.lightGreen
        
        
        self.view.backgroundColor = AppColors.lightGreen
        self.setupTextField(firstField)
        self.setupTextField(secondField)
        self.setupTextField(thirdField)
        self.setupTextField(fourthField)
        self.setupTextField(fifthfield)
        self.setupTextField(sixthfield)
        self.setupTextField(sevenfield)
        self.setupTextField(eigthFiled)
        self.setupTextField(NinthField)
        
        
                self.view.addSubview(button)
                
                button.backgroundColor = UIColor.white
                button.setTitle("Submit", for: .normal)
                button.setTitleColor(AppColors.lightGreen, for: .normal)
                button.cornerRadius = 20
                button.spinnerColor = .white
              //  button.isUserInteractionEnabled = false
                button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
       
        
        if (self.VerificationString != nil){
            let characters = self.VerificationString!.map { String($0)}
            self.firstField.text = characters[0]
            self.secondField.text = characters[1]
            self.thirdField.text = characters[2]
            self.fourthField.text = characters[3]
            self.fifthfield.text = characters[4]
            self.sixthfield.text = characters[5]
            self.sevenfield.text = characters[6]
            self.eigthFiled.text = characters[7]
            self.NinthField.text = characters[8]
            self.NinthField.resignFirstResponder()
           // button.isUserInteractionEnabled = true
        }else{
            self.firstField.becomeFirstResponder()
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func viewWillAppear(_ animated: Bool) {
       // let accounts = OTRAccountsManager.allAccounts()
//        if accounts.count > 0{
//            self.dismiss(animated: true, completion: nil)
//        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
//    @IBAction func BackButton(_ button:UIButton){
//        self.dismiss(animated: true, completion: nil)
//    }
    private final func setupTextField(_ textField: UITextField){
        textField.delegate = self
       // textField.widthAnchor.constraint(equalToConstant: 40).isActive = true
        textField.backgroundColor = textBackgroundColor
        textField.textAlignment = .center
        textField.adjustsFontSizeToFitWidth = false
        textField.font = UIFont(name: "Kefa", size: 40)
        textField.textColor = .white
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 2
        textField.layer.borderColor = inactiveFieldBorderColor.cgColor
        textField.keyboardType = .numberPad
        textField.autocorrectionType = .yes
        textField.textContentType = .oneTimeCode
    }
    
    
    @IBAction func actnBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonAction(_ button: TransitionButton) {
          // 2: Then start the animation when the user tap the button
        
        
        
      
       
     if (self.firstField.text?.count == 0 || self.secondField.text?.count == 0 || self.thirdField.text?.count == 0 || self.fourthField.text?.count == 0 || self.fifthfield.text?.count == 0 || self.sixthfield.text?.count == 0 || self.sevenfield.text?.count == 0 || self.eigthFiled.text?.count == 0 || self.NinthField.text?.count == 0){
            self.LoginErrorAlert(Message: "Please enter the Authentication Code Properly")
            DispatchQueue.main.async {
                button.stopAnimation(animationStyle: .shake, completion: {

                })
            }
            return
        }
        
        var OTPString = self.firstField.text
        OTPString = OTPString! + self.secondField.text!
        OTPString = OTPString! + self.thirdField.text!
        OTPString = OTPString! + self.fourthField.text!
        OTPString = OTPString! + self.fifthfield.text!
        OTPString = OTPString! + self.sixthfield.text!
        OTPString = OTPString! + self.sevenfield.text!
        OTPString = OTPString! + self.eigthFiled.text!
        OTPString = OTPString! + self.NinthField.text!
        
           let qualityOfServiceClass = DispatchQoS.QoSClass.background
           let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
           backgroundQueue.async(execute: {
               
              // sleep(3) // 3: Do your networking task or background work here.
        
            self.OTPAuthentication(OTP: OTPString!) { (status) in
                if (status == true){
                    DispatchQueue.main.async(execute: { () -> Void in
                     
                        
                        
                     
                        button.stopAnimation(animationStyle: .expand, completion: {
                            let addAccountController = AddAccountController.instantiate(fromAppStoryboard: .Account);
                            addAccountController.hidesBottomBarWhenPushed = true;
                            let navigationController = UINavigationController(rootViewController: addAccountController);
//                            addAccountController.jidTextField.text = self.username! + "@chat.securesignal.in"
//                            addAccountController.passwordTextField.text = self.Password
                            addAccountController.Username = self.username
                            addAccountController.jwsToken = self.JWSToken
                            addAccountController.AuthenicationCode = self.Password
                            addAccountController.NonceSalt = self.NonceSalt
                            self.showDetailViewController(navigationController, sender: self);
                            
                            
                            
                            
                            
    //
//                            let storyboard = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle)
//                            let ProfileVC : AddProfileVC = storyboard.instantiateViewController(withIdentifier: "AddProfileVC") as! AddProfileVC
//                            ProfileVC.Username = self.username
//                            ProfileVC.jwsToken = self.JWSToken
//                            ProfileVC.AuthenicationCode = self.Password
//                            ProfileVC.NonceSalt = self.NonceSalt
//                           // ProfileVC.account = self.account
//                           // ProfileVC.nicknametext = self.account!.displayName
//                            let ProfileNav = UINavigationController.init(rootViewController: ProfileVC)
//                            self.present(ProfileNav, animated: true, completion: nil)
                        })
                    })

                }else{
                    DispatchQueue.main.async(execute: { () -> Void in
                        button.stopAnimation(animationStyle: .shake, completion: {
    //
                           
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
                              
                          
                           
                        })
                    })
                }
            }
               
           })
       }
    
    func LoginErrorAlert(Message:String){
        let alert = UIAlertController(title: "Warning", message: Message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
           
        }))
        self.present(alert, animated: true, completion: nil)
    }
  
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

           
           if string.count == 1{
               //SubmitButton.isHidden = false
               switch textField{
               case firstField:
                   secondField.becomeFirstResponder()
                   break
               case secondField:
                   thirdField.becomeFirstResponder()
                   break
               case thirdField:
                   fourthField.becomeFirstResponder()
                   break
               case fourthField:
                   fifthfield.becomeFirstResponder()
                   break
               case fifthfield:
                   sixthfield.becomeFirstResponder()
                   break
               case sixthfield:
                   sevenfield.becomeFirstResponder()
                   break
               case sevenfield:
                   eigthFiled.becomeFirstResponder()
                   break
               case eigthFiled:
                   NinthField.becomeFirstResponder()
                   break
               case NinthField:
                   NinthField.resignFirstResponder()
                   break
               default:
                   break
               }
               textField.text? = string
               return false
           }else{
              // SubmitButton.isHidden = false
               switch textField{
               case firstField:
                   firstField.becomeFirstResponder()
                   break
               case secondField:
                   firstField.becomeFirstResponder()
                   break
               case thirdField:
                   secondField.becomeFirstResponder()
                   break
               case fourthField:
                   thirdField.becomeFirstResponder()
                   break
               case fifthfield:
                   fourthField.becomeFirstResponder()
                   break
               case sixthfield:
                   fifthfield.becomeFirstResponder()
                   break
               case sevenfield:
                   sixthfield.becomeFirstResponder()
                   break
               case eigthFiled:
                   sevenfield.becomeFirstResponder()
                   break
               case NinthField:
                   eigthFiled.becomeFirstResponder()
                   break
               default:
                   break
               }
               textField.text? = string
               return false
           }
           
          }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    
    func OTPAuthentication(OTP:String, completion: @escaping (_ success: Bool) -> ()){
     
        var Status:Bool = false
        let Authorization = "Bearer TN5sBit7LEZEICw6ws8NG6NjiCHmzzdc"
        let salt = "3vGX1PaaC5RhYxTZqNtCMlQGgh0wPlRD"
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: now)
        var deviceId = UIDevice.current.identifierForVendor!.uuidString
        deviceId = deviceId.replacingOccurrences(of: "-", with: "", options: NSString.CompareOptions.literal, range: nil)
        let token = self.username! + OTP + dateString + salt

 
        let PayloadData: Array<UInt8> = Array(token.utf8)
        let Payloadsalt: Array<UInt8> = Array(salt.utf8)

   

     do {
         let result = try! HMAC(key: Payloadsalt, variant: .sha256).authenticate(PayloadData)
         let hashdata = Data(result)
         var hmacHash = hexStringFromData(input: hashdata as NSData)
         hmacHash = hmacHash.lowercased()
       // let userdata : Data = "username=\(self.username!)&otp=\(OTP)&token=\(hmacHash)".data(using: .utf8)!
        let apidata: [String: Any] = ["username":self.username!,"otp":OTP,"timestamp":dateString,"deviceid":deviceId,"jws":self.JWSToken,"token":hmacHash]
         let jsonData = try? JSONSerialization.data(withJSONObject: apidata)
         let urlstring = URL(string: "https://ej.gigsp.co:5222/verifycode")

            var urlrequest = URLRequest(url: urlstring!)
                        urlrequest.httpMethod = "POST"
         urlrequest.httpBody = jsonData
         urlrequest.setValue(Authorization, forHTTPHeaderField: "Authorization")
         //urlrequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
                                    // return self.status!
                                }
                            }

                          do {
                            let json = try JSONSerialization.jsonObject(with: data,options:[]) as? [String:Any]
                                print(json)
                             let status = json?["status"] as? String
    //
                            print(status)
                             if (status!.contains("SUCCESS")){
                               
                                self.Password = json?["newpass"] as? String
                                self.NonceSalt = json?["salt"] as? String
                                
                                 Status = true
                               // self.invokeAudioVideoCall(buddyjid: to, finalJWT: roomname)
                               //  return self.status!
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

}
