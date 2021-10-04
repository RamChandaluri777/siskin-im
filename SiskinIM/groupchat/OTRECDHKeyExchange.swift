//
//  OTRECDHKeyExchange.swift
//  Siskin IM
//
//  Created by mohanchandaluri on 28/09/21.
//  Copyright © 2021 Tigase, Inc. All rights reserved.
//

import Foundation
import Foundation
import CommonCrypto
import Security
import UIKit
import CryptoSwift




@objc open class OTRECDHKeyExchange:NSObject{
  let aesGcmBlockLength = 16
   // let delegate:OTRECDHProtocol?
   let ivData = Data(bytes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    var jsonbodystring:NSString?
    var publickeybase64encoded:String = ""
   var publicKeySec, privateKeySec,publicKeySecretreive: SecKey?
    var publicKey, privateKey: SecKey?
    var botpublickey:SecKey?
    
    let tagPrivate = "myPrivate"
    let tagPublic  = "myPublic"
    let tagSymmetricData = "sessionkey"
    let tagBotPublic = "BOTPUBLICKEY"
    var keySourceStr = ""
           let keyattribute = [
               kSecAttrKeyType as String: kSecAttrKeyTypeEC,
               kSecAttrKeySizeInBits as String : 256
               ] as CFDictionary
          

    var error: Unmanaged<CFError>?
  let attributesECPub: [String:Any] = [
         kSecAttrKeyType as String: kSecAttrKeyTypeEC,
         kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
         kSecAttrKeySizeInBits as String: 256,
         kSecAttrIsPermanent as String: false
     ]

    @objc open func decodekey(PublicString:String){
        let json = PublicString.data(using: .utf8)!
        let datasave: Datasave = try! JSONDecoder().decode(Datasave.self, from: json)
    
        let Receivedpublickey = datasave.body!.data!

       
        print(Receivedpublickey)
        let pubKeyECData = Data(base64Encoded: Receivedpublickey, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)
      
        let pubKeyECStriped = pubKeyECData![(pubKeyECData?.count)!-65..<(pubKeyECData?.count)!]
        publicKeySecretreive = SecKeyCreateWithData(pubKeyECStriped as! CFData,attributesECPub as CFDictionary, &error)
        print(publicKeySecretreive)
        if (publicKeySecretreive != nil){
            
            self.StoreInKeychain(tag: tagBotPublic, key: publicKeySecretreive!)
          
            var botpublicKeyretreive: SecKey?
           
             botpublicKeyretreive = GetKeyTypeInKeyChain(tag: tagBotPublic)
            
            if (botpublicKeyretreive != nil ){
                self.retreivekeys { (keyData, error) in
                    if (error != nil) {
                      let key = ""
                    }else{
                        let sessionkey = keyData
                    }
                }

            }
        }
       
        
        
//        print(sessionkey)
    }
    
//   @objc open func ivdata() -> NSData {
//
//    let iv: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
//    return iv as NSData
//    }
    
    @objc open func decryptMissedRoomMessage(message:String)->String{
    
                                             let groupdata = message.data(using: .utf8)
                                          let savemessage: MessageSave = try! JSONDecoder().decode(MessageSave.self, from: groupdata!)
                                        
        let encryteddata: NSData = NSData(base64Encoded: (savemessage.body?.data!)!, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
                let encrypted = encryteddata as Data
        //        let encrypted = Data(Encrypteddata.utf8)
                let iv: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
                  let key = UserDefaults.standard.object(forKey: tagSymmetricData) as! Data
                let keyarray = key.withUnsafeBytes {
                    [UInt8](UnsafeBufferPointer(start: $0, count: key.count))
                }
                let messagedataArray = encrypted.withUnsafeBytes {
                                                      [UInt8](UnsafeBufferPointer(start: $0, count: encrypted.count))
                                                  }
                do {
                    // In combined mode, the authentication tag is appended to the encrypted message. This is usually what you want.
                    let gcm = GCM(iv: iv, mode: .combined)
                    let aes = try AES(key: keyarray, blockMode: gcm, padding: .noPadding)
                    let decrypted = try aes.decrypt(messagedataArray)
        //            let decrypted = try AES(key: keyarray, blockMode: CBC(iv: iv), padding: .zeroPadding).decrypt(messagedataArray)
                    let decrypteddata = NSData(bytes: decrypted, length: decrypted.count)
                    let data = decrypteddata as Data
                    let roomMessage = String(data: data, encoding: String.Encoding.utf8)
                    return roomMessage!
                } catch {
                    print(error)
                   return "error"
                }
                return ""
   
    }
//    @objc open func MarkallMessagesasRead(message:OTROutgoingMessage)->OTROutgoingMessage{
//        if let messagecopied = message as? OTROutgoingMessage {
//            messagecopied.isRead = true
//         return messagecopied
//        }
//        return message
//    }
//    @objc open func NewDuplicateMessage(message:OTRMessageProtocol)->OTRXMPPRoomMessage{
//                                       if let messagecopied = message as? OTRXMPPRoomMessage {
//                                             messagecopied.state = .sent
//                                       // messagecopied.isOutgoingMessageRead = false
//                                       // messagecopied.isMessageDelivered = true
//                                          return messagecopied
//                                         }
//                                        let roomMessage = OTRXMPPRoomMessage()
//                                         return roomMessage!
//                                         //
//          }
//
//    @objc open func SendMediaurl(RoomMessage:OTRXMPPRoomMessage){
//
//
//
//    }
  
    
    @objc open func keygeneration() -> String {
  
        var privateencoded:String?
        deleteAllKeysInKeyChain()
     SecKeyGeneratePair(keyattribute, &publicKeySec, &privateKeySec)
        print(privateKeySec as Any)
      
        if let cfprivatedata = SecKeyCopyExternalRepresentation(privateKeySec!, &error) {
           let privatedata:Data = cfprivatedata as Data
            print(privatedata.base64EncodedString())
            privateencoded = privatedata.base64EncodedString()
        }
        print(privateencoded)
        self.StoreInKeychain(tag: tagPrivate, key: privateKeySec!)
        self.StoreInKeychain(tag: tagPublic, key: publicKeySec!)
         
        let PKExport = self.PublicKeyExportFormat(Pk: publicKeySec!)
        return PKExport
     
    }
    
    @objc open func PublicKeyExportFormat(Pk:SecKey)->(String){
        if let cfdata = SecKeyCopyExternalRepresentation(Pk, &error) {
              let data:Data = cfdata as Data
           print(data)
              let b64Key2 = data.base64EncodedString()
               print("iOS Default: " + b64Key2)
               let exportImportManager = CryptoExportImportManager()
           
           if let exportableDERKey = exportImportManager.exportPublicKeyToDER(data, keyType: kSecAttrKeyTypeEC as String, keySize: 256, privatekey: false) {
               print("Converted: " + exportableDERKey.base64EncodedString())
                   publickeybase64encoded = exportableDERKey.base64EncodedString()
               } else {
                   return "error"
               }

           }


        let botdata: [String: Any] = ["body":[ "type":"TYPE_PUBLIC_KEY" , "data":publickeybase64encoded]]
        let salt = "abc123"

        let jsonData = try! JSONSerialization.data(withJSONObject: botdata, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String

        let checksumderive = jsonString + salt
        print(checksumderive)
        let checksumdata = sha256(string: checksumderive)
   
        var checksum = ""
        for index in 0..<Int(CC_SHA256_DIGEST_LENGTH) {
            checksum += String(format: "%02x", checksumdata![index])
        }
       let bodydata:[String:Any] = ["body":["type":"TYPE_PUBLIC_KEY","data":publickeybase64encoded],"checksum":checksum]
       let jsonbodydata = try! JSONSerialization.data(withJSONObject: bodydata, options: JSONSerialization.WritingOptions.prettyPrinted)
       let jsonbodystring = NSString(data: jsonbodydata, encoding: String.Encoding.utf8.rawValue)! as String
       print(jsonbodystring)
   
        return jsonbodystring
    }
    
    @objc open func publickey_request(Threadname:String,account:String)->(String){
        let salt = "abc123"
        let requestdata:[String:Any] = ["body":["from":account,"to":Threadname,"type":"TYPE_PUBLIC_KEY_REQUEST"]];
        let requestjson = try! JSONSerialization.data(withJSONObject: requestdata, options: JSONSerialization.WritingOptions.prettyPrinted)
         let requeststring = NSString(data: requestjson, encoding: String.Encoding.utf8.rawValue)! as String
        let checksumderived = requeststring + salt
         let checksumdata = sha256(string: checksumderived)
        var checksum = ""
                 for index in 0..<Int(CC_SHA256_DIGEST_LENGTH) {
                  checksum += String(format: "%02x", checksumdata![index])
                 }
        let bodydata:[String:Any] = ["body":["from":account,"to":Threadname,"type":"TYPE_PUBLIC_KEY_REQUEST"],"checksum":checksum];
         let jsonbodydata = try! JSONSerialization.data(withJSONObject: bodydata, options: JSONSerialization.WritingOptions.prettyPrinted)
         let jsonbodystring = NSString(data: jsonbodydata, encoding: String.Encoding.utf8.rawValue)! as String
       return (jsonbodystring) as  String
    }

    func MD5(messageData: Data) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
       // let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }


 @objc open func sha256(string: String) -> Data? {
            let len = Int(CC_SHA256_DIGEST_LENGTH)
              let data = string.data(using:.utf8)!
              var hash = Data(count:len)

              let _ = hash.withUnsafeMutableBytes {hashBytes in
                  data.withUnsafeBytes {dataBytes in
                      CC_SHA256(dataBytes, CC_LONG(data.count), hashBytes)
                  }
              }
              return hash
      
  }
    @objc open func Encryptdatabase(password:String,database:Data,EncryptionKey:String)-> (Data){
        let Password: Array<UInt8> = password.bytes
        let saltGen = "cNwnWH8BJPcyFvWNl6y1"
        let salt: [UInt8] = Array(saltGen.utf8)
        do{
         /* Generate a key from a `password`. Optional if you already have a key */
            let key = try PKCS5.PBKDF2(
                password: Password,
                salt: salt,
                iterations: 4096,
                keyLength: 32, /* AES-256 */
                variant: .sha256
            ).calculate()
            
            let iv: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]

            /* AES cryptor instance */
            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)

            /* Encrypt Data */
         
            let encryptedBytes = try aes.encrypt(database.bytes)
            let encryptedData = Data(encryptedBytes)
            return encryptedData
        }catch{
            print(error)
        }
      
      
        return Data()
    }
    
    @objc open func aesEncrypt(messageData: NSData) -> String? {
    // let Session_key = self.retreivekeys()
        var cipherData:Data?
                do {
                    
                    let iv: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
                   // self.retreivekeys()
                    var key:Data?
//                    do {
//                        key = try readKeychainItem(key: tagSymmetricData)
//                        print(key)
//                    } catch let error {
//                        return error.localizedDescription
//                        }
                    key = UserDefaults.standard.object(forKey: tagSymmetricData) as? Data
                    if (key == nil){
                        var botpublicKeyretreive: SecKey?
                       
                        
                         botpublicKeyretreive = GetKeyTypeInKeyChain(tag: tagBotPublic)
                        if botpublicKeyretreive != nil{
                            self.retreivekeys { (keyData, error) in
                                if (error != nil) {
                                   key = nil
                                }else{
                                   key = keyData
                                }
                            }
                        }
                      
                    }
                    if key == nil{
                        return "Unable to fetch the Encryption Keys"
                    }
                    let keybytes = [UInt8](key!)
                    let keyarray = key!.withUnsafeBytes {
                        [UInt8](UnsafeBufferPointer(start: $0, count: key!.count))
                    }
                    let messagedata = messageData as Data
                    let messagedataArray = messagedata.withUnsafeBytes {
                                       [UInt8](UnsafeBufferPointer(start: $0, count: messageData.count))
                                   }
                    let messageBytes = [UInt8] (messageData as Data)
                    do {
                    
                    let gcm = GCM(iv: iv, mode: .combined)
                    let aes = try AES(key: keyarray, blockMode: gcm, padding: .noPadding)
                        let encrypted = try aes.encrypt(messagedataArray)
                        let dataencrypted = NSData(bytes: encrypted, length: encrypted.count)
                            cipherData = dataencrypted as Data
                    
                    } catch {
                        print(error)
                    }
                    
                  let base64cryptString = cipherData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                   // let base64cryptString = cipherData!.base64EncodedString()
                    //let base64String = base64cryptString.replacingOccurrences(of: "\n", with: "")
                   // NSString *outString = [inString stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
                    //let roomMessage = self.decryptmessage(Encrypteddata: base64cryptString!)
                    let botdata: [String: Any] = ["body":["type":"TYPE_DH_ENCRYPTED","data":base64cryptString]]
                              let salt = "abc123"

                              let jsonData = try! JSONSerialization.data(withJSONObject: botdata, options: JSONSerialization.WritingOptions.prettyPrinted)
                              let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String

                            let checksumderive = jsonString + salt
                              print(checksumderive)
                          let checksumdata = sha256(string: checksumderive)
                          
                            var checksum = ""
                            for index in 0..<Int(CC_SHA256_DIGEST_LENGTH) {
                             checksum += String(format: "%02x", checksumdata![index])
                            }
                    
                              let bodydata:[String:Any] = ["checksum":checksum,"body":["type":"TYPE_DH_ENCRYPTED","data":base64cryptString]]
                              let jsonbodydata = try! JSONSerialization.data(withJSONObject: bodydata, options: [])
                              let jsonbodystring = NSString(data: jsonbodydata, encoding: String.Encoding.utf8.rawValue)! as String
                              print(jsonbodystring)
                          
                          return (jsonbodystring) as  String

                }catch let error {
                 
                                    return "error"
                                }
                          return ""
                }
    
    
    
   
    
    @objc open func decryptmessage(Encrypteddata:String)->String{
        
        let encryteddata: NSData = NSData(base64Encoded: Encrypteddata, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        let encrypted = encryteddata as Data
//        let encrypted = Data(Encrypteddata.utf8)
        let iv: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
        var key:Data?
//        do {
//                               key = try readKeychainItem(key: tagSymmetricData)
//                           } catch let error {
//                               return error.localizedDescription
//                                                    }
        key = UserDefaults.standard.object(forKey: tagSymmetricData) as? Data
        if (key == nil){
            
              var botpublicKeyretreive: SecKey?
             
               botpublicKeyretreive = GetKeyTypeInKeyChain(tag: tagBotPublic)
              
              if (botpublicKeyretreive != nil ){
            self.retreivekeys { (keyData, error) in
                if (error != nil) {
                   key = nil
                }else{
                   key = keyData
                }
            }
        }
        }
        if key == nil{
            return "Unable to fetch the Encryption Keys"
        }
        let keyarray = key!.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: key!.count))
        }
      
        let messagedataArray = encrypted.withUnsafeBytes {
                                              [UInt8](UnsafeBufferPointer(start: $0, count: encrypted.count))
                                          }
        do {
            // In combined mode, the authentication tag is appended to the encrypted message. This is usually what you want.
            let gcm = GCM(iv: iv, mode: .combined)
            let aes = try AES(key: keyarray, blockMode: gcm, padding: .noPadding)
            //
            let decrypted = try aes.decrypt(messagedataArray)
//          let decrypted = try AES(key: keyarray, blockMode: CBC(iv: iv), padding: .zeroPadding).decrypt(messagedataArray)
            let decrypteddata = NSData(bytes: decrypted, length: decrypted.count)
            let data = decrypteddata as Data
            let roomMessage = String(data: data, encoding: String.Encoding.utf8)
            
            return roomMessage!
        } catch {
            print(error)
           return "error Decrypt"
        }
        return ""
    }
//

 @objc open func deleteAllKeysInKeyChain() {
           
           let query : [String: AnyObject] = [
               String(kSecClass)             : kSecClassKey
           ]
        let status = SecItemDelete(query as CFDictionary)
           
           switch status {
               case errSecItemNotFound:
                   print("No key in keychain")
               case noErr:
                   print("All Keys Deleted!")
               default:
                   print("SecItemDelete error! \(status.description)")
           }
       }
    //
    //
    
    func UpdateKeychain(tag:String,key:SecKey) -> Bool{
        let addParams: [String: Any] = [
            kSecValueRef as String: key,
            kSecReturnData as String: true,
            kSecClass as String: kSecClassKey,
            kSecAttrAccessible as String   : kSecAttrAccessibleAlwaysThisDeviceOnly,
            kSecAttrApplicationTag as String: tag
                  ]
        let fields: [String: Any] = [
            kSecValueRef as String: key,
            kSecAttrApplicationTag as String: tag
           ]
        
           let status = SecItemUpdate(addParams as CFDictionary, fields as CFDictionary)
           guard status == errSecSuccess else {
            return (status != 0)
           }
           print("Updated Keychain")
        return (status != 0)
    }
   
    func StoreInKeychain(tag: String, key: SecKey) {
     
          let storeattribute = [
                  String(kSecClass)              : kSecClassKey,
                  String(kSecAttrKeyType)        : kSecAttrKeyTypeEC,
                  String(kSecValueRef)           : key,
                  String(kSecReturnPersistentRef): true
            ] as [String : Any]

//: [CFString: Any]
       
        let addParams: [String: Any] = [
            kSecValueRef as String: key,
            kSecReturnData as String: true,
            kSecClass as String: kSecClassKey,
            kSecAttrAccessible as String   : kSecAttrAccessibleAlwaysThisDeviceOnly,
            kSecAttrApplicationTag as String: tag
                  ]



        let status = SecItemAdd(addParams as CFDictionary, nil)

        if status != noErr {
            print("SecItemAdd Error!\(status)")
            return
        }else{
            print("key saved successfully")
        }
        
   
    }
    

   func GetMyPrivateandPublickey()->Bool{
         privateKey = GetKeyTypeInKeyChain(tag:tagPrivate)
        publicKey = GetKeyTypeInKeyChain(tag:tagPublic)
        if ((privateKey != nil)&&(publicKey != nil)){
            return true
        }else{
            
        }
        
        return false
    }
    
    
   func GetBotpublickey()->Bool{
            botpublickey = GetKeyTypeInKeyChain(tag:tagBotPublic)
        
           if (botpublickey == nil){
               return false
           }
    
          return true
       }
    
    @objc open func GetKeysFromKeychain() {
        privateKey = GetKeyTypeInKeyChain(tag:tagPrivate)
        publicKey = GetKeyTypeInKeyChain(tag:tagPublic)
        
        if (((privateKey != nil)&&(publicKey != nil)) == true){
            do{
                try sharedsecret(Privatekey: privateKey!, publickey: publicKey!)
            } catch let error {
                print("Error: \(error)")
            }
        }
        
        
       }
    
    @objc open  func retreivekeys(completionBlock: @escaping (Data, NSError?) -> Void) -> Void{
        var mypublicKey, myprivateKey,botpublicKeyretreive: SecKey?
        var keydata:Data?
        myprivateKey = GetKeyTypeInKeyChain(tag:tagPrivate)
        mypublicKey = GetKeyTypeInKeyChain(tag:tagPublic)
        botpublicKeyretreive = GetKeyTypeInKeyChain(tag: tagBotPublic)
  //if (myprivateKey != nil && mypublicKey != nil && botpublicKeyretreive != nil){
         do {
            keydata = try sharedsecret(Privatekey: myprivateKey!, publickey: botpublicKeyretreive!)
            completionBlock(keydata!, nil)
                 
             } catch let error {
                completionBlock(keydata ?? Data(),error as NSError)
                      // return error as Error as! Data
            }
    
  //}
     }
  
 
   
    @objc open func addKeychainItem(key: String, data: Data) {
        let err = SecItemAdd([
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    "my_service",
            kSecAttrAccount:    key,
            kSecAttrAccessible: kSecAttrAccessibleAlwaysThisDeviceOnly,
            kSecValueData:      data
        ] as NSDictionary, nil)
        switch err {
            case errSecSuccess, errSecDuplicateItem:
                break
            default:
                fatalError()
        }
    }

     open func readKeychainItem(key: String)  throws ->Data? {
        var result: CFTypeRef? = nil
        let err = SecItemCopyMatching([
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    "my_service",
            kSecAttrAccount:    key,
            kSecReturnData:     true
        ] as NSDictionary, &result)
        
      //  var dataTypeRef: AnyObject? = nil
//
//        let status: OSStatus = SecItemCopyMatching(err as! CFDictionary, &dataTypeRef)
//
//        if status == noErr {
//            return result as! Data?
//        } else {
//            return nil
//        }
//        do{
//            try sharedsecret(Privatekey: privateKey!, publickey: publicKey!)
//        } catch let error {
//            print("Error: \(error)")
//        }
        guard err == errSecSuccess else {
            throw error!.takeRetainedValue() as Error
        }
//        let password = String(bytes: (result as! Data), encoding: .utf8)!
//        let protectedState = UIApplication.shared.isProtectedDataAvailable ? "Unprotected" : "Protected"
//        return "\(protectedState): '\(password)'"
        return result as? Data
    }

    func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }

  func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    
    @objc open func GetKeyTypeInKeyChain(tag : String) -> SecKey? {
           let query = [
               String(kSecClass)             : kSecClassKey,
               String(kSecAttrKeyType)       : kSecAttrKeyTypeEC,
               kSecAttrApplicationTag as String: tag,
               String(kSecReturnRef)         : true
           ] as [String : Any]
//
           var result : AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &result)
           
           if status == errSecSuccess {
      
               return result as! SecKey?
           }
  
           
           return nil
       }

    
    func sharedsecret(Privatekey:SecKey,publickey:SecKey) throws ->Data {
      
          let exchangeOptions: [String: Any] = [:]
         guard let shared = SecKeyCopyKeyExchangeResult(Privatekey, SecKeyAlgorithm.ecdhKeyExchangeCofactor, publickey, exchangeOptions as CFDictionary, &error) else {
                    throw error!.takeRetainedValue() as Error
                }
        UserDefaults.standard.set(shared, forKey: tagSymmetricData)
        
     //   addKeychainItem
      // self.addKeychainItem(key: tagSymmetricData, data: shared as Data)
//
//
       return shared as Data
    }
 
    
  
    
}


    

 
struct Datasave:Codable{
    var checksum:String?
    var body:Publickeydata?
    enum codingkeys:String,CodingKey{
        case checksum = "checksum"
        case body = "body"
    }
}
struct Publickeydata:Codable{
    var data:String?
    var from:String?
    var to:String?
    var type:String?
    enum codingkeys:String,CodingKey{
        case data = "data"
        case from = "from"
        case to = "to"
        case type = "type"
    }
 }




struct members:Codable{
    var members:String?
    var occupants:[OccupantList]?
    enum codingKeys:String,CodingKey{
        case members = "members"
        case occupants = ""
    }

}

struct OccupantList:Codable {
    var hostname:String?
    var Jid:String?
    var affiliation:String?
    var id:String?
    enum codingKeys: String,CodingKey{
        case hostname = "hostName"
        case Jid = "jid"
        case affiliation = "affiliation"
        case id = "id"
    }
}
struct MessageSave:Codable{
    var checksum:String?
    var body:DH_Encrypted?
    enum codingkeys:String,CodingKey{
        case checksum = "checksum"
        case body = "body"
    }
}
struct DH_Encrypted:Codable{
    var data:String?
    var type:String?
    enum codingkeys:String,CodingKey{
        case data = "data"
        case type = "type"
    }
}
