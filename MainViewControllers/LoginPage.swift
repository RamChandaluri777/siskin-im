//
//  LoginPage.swift
//  ios-login
//
//  Created by Vitaliy Paliy on 3/10/20.
//  Copyright © 2020 PALIY. All rights reserved.
//

import UIKit
import CryptoKit
import CommonCrypto
import CryptoSwift
@objc open class LoginPage: UIViewController, UITextFieldDelegate {
    
    var ValidationToken:String?
    var deviceIDentication:String?
    var username:String?
    var mainView: MainView!
    
    private struct Constants {
        static let webViewTag = 123
        static let testLabelTag = 321
    }
  
    
    private var usernameTF: UsernameTF?
    
    private var passwordTF: PasswordTF?
    
    private var loginButton: LoginButton?
    
    private var signUpButton: SignUpButton?
    
    private var continueButton: ContinueButton?
    
    private var slideView: SlideView?
    
    private var gradientView = CAGradientLayer()
    
    private var blobViews: BlobViews?
    
    private var activityLines: ActivityLine?
    
    private var keyboardIsShown = false
        
    private var statusView = true
   private var token = "eyJhbGciOiJSUzI1NiIsIng1YyI6WyJNSUlGbFRDQ0JIMmdBd0lCQWdJUkFMN21zSmtiM1RkN0NBQUFBQUJ4WWg0d0RRWUpLb1pJaHZjTkFRRUxCUUF3UWpFTE1Ba0dBMVVFQmhNQ1ZWTXhIakFjQmdOVkJBb1RGVWR2YjJkc1pTQlVjblZ6ZENCVFpYSjJhV05sY3pFVE1CRUdBMVVFQXhNS1IxUlRJRU5CSURGUE1UQWVGdzB5TVRBMU1qQXdOekl4TkRkYUZ3MHlNVEE0TVRnd056SXhORFphTUd3eEN6QUpCZ05WQkFZVEFsVlRNUk13RVFZRFZRUUlFd3BEWVd4cFptOXlibWxoTVJZd0ZBWURWUVFIRXcxTmIzVnVkR0ZwYmlCV2FXVjNNUk13RVFZRFZRUUtFd3BIYjI5bmJHVWdURXhETVJzd0dRWURWUVFERXhKaGRIUmxjM1F1WVc1a2NtOXBaQzVqYjIwd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUN1bU1uV2p2R0ZuendMdXJ1SnJoTm1za3JEd0p2Tm0ycjBjRDdxeWF0NkFxSVZ3WkJmZGNYMWpCMGxUK2pzK3pHQzNNUzdac3llbXZSaGRxcERhdkhTVmZ4S3hZREc2dHp1eHh4ZE0wOWVKWFNtSkZLTWVSVWZUVkFBc0x5WWVHOWVHMno5WG5oZ3VkK3N3dVJKTWxJZzE3bnBlQ0toRHNlL1lQaTR5YmhrcXRsOC9NLzNrKzlMVTZrbndGMjRJODNNUjdnVGtMN1doU2RPb2tybnZkWnUrR0poYVhQcGJtaEpiUi9xNlhOQWVNR3hSaGhKRHlrOEhaa005cFJyNndaMFJhQ2Qva1FLNWh4T3hkejR3YU5zNDBiYVVNQU5tcG1UMGxFY1VaMnQxUUNmL3dMcldHNjhDa0V5clNVT2pQVURvalJmVG53YTlVdmFGNTZ1eUI0akFnTUJBQUdqZ2dKYU1JSUNWakFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0V3REFZRFZSMFRBUUgvQkFJd0FEQWRCZ05WSFE0RUZnUVVMbFhFSFdWeHZRVEZGM1QvNUQ3NzJpckZMNUV3SHdZRFZSMGpCQmd3Rm9BVW1OSDRiaERyejV2c1lKOFlrQnVnNjMwSi9Tc3daQVlJS3dZQkJRVUhBUUVFV0RCV01DY0dDQ3NHQVFVRkJ6QUJoaHRvZEhSd09pOHZiMk56Y0M1d2Eya3VaMjl2Wnk5bmRITXhiekV3S3dZSUt3WUJCUVVITUFLR0gyaDBkSEE2THk5d2Eya3VaMjl2Wnk5bmMzSXlMMGRVVXpGUE1TNWpjblF3SFFZRFZSMFJCQll3RklJU1lYUjBaWE4wTG1GdVpISnZhV1F1WTI5dE1DRUdBMVVkSUFRYU1CZ3dDQVlHWjRFTUFRSUNNQXdHQ2lzR0FRUUIxbmtDQlFNd0x3WURWUjBmQkNnd0pqQWtvQ0tnSUlZZWFIUjBjRG92TDJOeWJDNXdhMmt1WjI5dlp5OUhWRk14VHpFdVkzSnNNSUlCQmdZS0t3WUJCQUhXZVFJRUFnU0I5d1NCOUFEeUFIY0FmVDd5K0kvL2lGVm9KTUxBeXA1U2lYa3J4UTU0Q1g4dWFwZG9tWDRpOE5jQUFBRjVpTjNTc3dBQUJBTUFTREJHQWlFQW43bFhhSzYxOFFQekJ0RlEwOGlpNWtQblJDK3Vlc1hLQWFwV1B4aldDOFVDSVFEeFRUeVh0TnpNbFBkV3JVeFBLSjEybmlHRm56SFNsa0VlRG9PSVJicnkyUUIzQU83QWxlNk5jbVFQa3VQRHVSdkhFcU5wYWdsN1Myb2FGRGptUjdMTDdjWDVBQUFCZVlqZDBSa0FBQVFEQUVnd1JnSWhBTmJWUnBrZTJYaTZkUy9tcTZCWUVKSFZEYnhuZmxkVklUZC9NTFBEMTRKbEFpRUF3ZU1lbWxiaDNDcS91bUZiYkR5MUlranRxeUJ5TENwbXRvOGY2bGhzRWNJd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFKN2xrZFdudEEyZjBvM3lzODM4ZlAveFFKY2xEUUM3S0p0WGJRRUZIZXdIZkphUytEZi83WGVHeG5uWFRpOCtUaG5vQm13Q0c0alpqYndTT2g2UXIvSWNtOFB1akJkSzU3ZzFsY1RPeFhsN1hUbmlMT3E1b0JweW1FdThuQy9UY2YvQ3cwWVdkMUJhS1luaVlFamw5eUJnTnJ0RENEYm5HblRNNkl6MlhuVFQrQzhDRTNjNGxKeWdxNHh6R0xhSWVUbmtHTGpDYnI4VlQwOEx6Q29WMDQ3Umg0Rm1XZzBLdmlkamRBSlVyeGgzUitkMDV1S3UvK3h5aWRudnUvOEk0VUo0c2RrbjhmQ2hHbzl5cGJRek1aRmEzaFEvaDB0V0g4S1E5eUN5dEhqc2NkeVNSc3c4WDB5ck1hSEdsSjRZYms0VmlLQ2tOWGNqTy93Z2tRam4xdUE9IiwiTUlJRVNqQ0NBektnQXdJQkFnSU5BZU8wbXFHTmlxbUJKV2xRdURBTkJna3Foa2lHOXcwQkFRc0ZBREJNTVNBd0hnWURWUVFMRXhkSGJHOWlZV3hUYVdkdUlGSnZiM1FnUTBFZ0xTQlNNakVUTUJFR0ExVUVDaE1LUjJ4dlltRnNVMmxuYmpFVE1CRUdBMVVFQXhNS1IyeHZZbUZzVTJsbmJqQWVGdzB4TnpBMk1UVXdNREF3TkRKYUZ3MHlNVEV5TVRVd01EQXdOREphTUVJeEN6QUpCZ05WQkFZVEFsVlRNUjR3SEFZRFZRUUtFeFZIYjI5bmJHVWdWSEoxYzNRZ1UyVnlkbWxqWlhNeEV6QVJCZ05WQkFNVENrZFVVeUJEUVNBeFR6RXdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEUUdNOUYxSXZOMDV6a1FPOSt0TjFwSVJ2Snp6eU9USFc1RHpFWmhEMmVQQ252VUEwUWsyOEZnSUNmS3FDOUVrc0M0VDJmV0JZay9qQ2ZDM1IzVlpNZFMvZE40WktDRVBaUnJBekRzaUtVRHpScm1CQko1d3VkZ3puZElNWWNMZS9SR0dGbDV5T0RJS2dqRXYvU0pIL1VMK2RFYWx0TjExQm1zSytlUW1NRisrQWN4R05ocjU5cU0vOWlsNzFJMmROOEZHZmNkZHd1YWVqNGJYaHAwTGNRQmJqeE1jSTdKUDBhTTNUNEkrRHNheG1LRnNianphVE5DOXV6cEZsZ09JZzdyUjI1eG95blV4djh2Tm1rcTd6ZFBHSFhreFdZN29HOWorSmtSeUJBQms3WHJKZm91Y0JaRXFGSkpTUGs3WEEwTEtXMFkzejVvejJEMGMxdEpLd0hBZ01CQUFHamdnRXpNSUlCTHpBT0JnTlZIUThCQWY4RUJBTUNBWVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdFR0NDc0dBUVVGQndNQ01CSUdBMVVkRXdFQi93UUlNQVlCQWY4Q0FRQXdIUVlEVlIwT0JCWUVGSmpSK0c0UTY4K2I3R0NmR0pBYm9PdDlDZjByTUI4R0ExVWRJd1FZTUJhQUZKdmlCMWRuSEI3QWFnYmVXYlNhTGQvY0dZWXVNRFVHQ0NzR0FRVUZCd0VCQkNrd0p6QWxCZ2dyQmdFRkJRY3dBWVlaYUhSMGNEb3ZMMjlqYzNBdWNHdHBMbWR2YjJjdlozTnlNakF5QmdOVkhSOEVLekFwTUNlZ0phQWpoaUZvZEhSd09pOHZZM0pzTG5CcmFTNW5iMjluTDJkemNqSXZaM055TWk1amNtd3dQd1lEVlIwZ0JEZ3dOakEwQmdabmdRd0JBZ0l3S2pBb0JnZ3JCZ0VGQlFjQ0FSWWNhSFIwY0hNNkx5OXdhMmt1WjI5dlp5OXlaWEJ2YzJsMGIzSjVMekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBR29BK05ubjc4eTZwUmpkOVhsUVdOYTdIVGdpWi9yM1JOR2ttVW1ZSFBRcTZTY3RpOVBFYWp2d1JUMmlXVEhRcjAyZmVzcU9xQlkyRVRVd2daUStsbHRvTkZ2aHNPOXR2QkNPSWF6cHN3V0M5YUo5eGp1NHRXRFFIOE5WVTZZWlovWHRlRFNHVTlZekpxUGpZOHEzTUR4cnptcWVwQkNmNW84bXcvd0o0YTJHNnh6VXI2RmI2VDhNY0RPMjJQTFJMNnUzTTRUenMzQTJNMWo2YnlrSllpOHdXSVJkQXZLTFdadS9heEJWYnpZbXFtd2ttNXpMU0RXNW5JQUpiRUxDUUNad01INTZ0MkR2cW9meHM2QkJjQ0ZJWlVTcHh1Nng2dGQwVjdTdkpDQ29zaXJTbUlhdGovOWRTU1ZEUWliZXQ4cS83VUs0djRaVU44MGF0blp6MXlnPT0iXX0.eyJub25jZSI6ImpyMnJhSVJNVm1KaDRDK0txZnVrT1NHVXBFbVVxTXA2VUhKbGMyVnVZMlVnUVhSMFpYTjBZWFJwYjI0eE5qSTFNVEU0T0RZeE1URTAiLCJ0aW1lc3RhbXBNcyI6MTYyNTExODg2NDM5NywiYXBrUGFja2FnZU5hbWUiOiJpbi5zZWN1cmUuc2lnbmFsIiwiYXBrRGlnZXN0U2hhMjU2IjoiZ3kzNHI2ZTMxMkU4N3NDOVd3c25lQ2ZKYS9GbVhYR052V3lLaUJ5Z21Mdz0iLCJjdHNQcm9maWxlTWF0Y2giOnRydWUsImFwa0NlcnRpZmljYXRlRGlnZXN0U2hhMjU2IjpbIm1zS3E0d0VlWFFTbVNKSzI0RTkyWW9zKzVjQmxNd0YrTUt4b05EdnJVNGM9Il0sImJhc2ljSW50ZWdyaXR5Ijp0cnVlLCJldmFsdWF0aW9uVHlwZSI6IkJBU0lDLEhBUkRXQVJFX0JBQ0tFRCJ9.eQscDiBxUhmRK5Py9x8F8QrEcJ9ywWVWrBrE1qBj7mKSbqU1j8jcUXguGagMiZnKcPJDKJ5asikJr8jSaUKwbM9PR-KPsqJk_0E1L6DUxvRjxos9rNdDmhI1nzaDc35xwr1SifL47IsYhgPdDnunS3rEyv4KjfmhbEtKoHRI_l4qd50qDGyeYsvRTDXsw2zC5bd2Wx7Hvi00nhOfBI4mtfKzWm4CxKjUiufZiXeRU5PiMZWUtiwmMfsVe0DojBEphoZ3hF6gw0nua3qApR9gkanx7OC2x_cDOk2rLNPC8lNpQxUWhRUuZz1eMotUaqvjCKq6lR_4V8G-eY9S228Q0w"
  
    
   // let recaptcha = try? ReCaptcha(endpoint: ReCaptcha.Endpoint.default)
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
       
        notificationCenterHandler()
       
    }


    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        let accounts = OTRAccountsManager.allAccounts()
//        if accounts.count > 0{
//            self.dismiss(animated: true, completion: nil)
//        }
    }
  
    
    private func setupInitialUI() {
      
        blobViews = BlobViews(for: self)
        gradientView = setupGradientLayer()
        gradientView.frame = view.frame
        gradientView.locations = [0,0]
        view.layer.insertSublayer(gradientView, at: 0)
        mainView = MainView(for: self)
        slideView = SlideView(for: self)
        activityLines = ActivityLine(for: self)
        
    }
    
    private func setupInitialTFView() {
        usernameTF = UsernameTF(for: self)
        passwordTF = PasswordTF(for: self)
        continueButton = ContinueButton(for: self)
       
        continueButton?.frame.origin.y = passwordTF!.frame.origin.y
    }
    
    func handleSlideUp(with gesture: UIPanGestureRecognizer){
        switch gesture.state {
        case .began , .changed:
            handleMovingState(for: gesture)
        case .ended:
            UIView.animate(withDuration: 0.3) {
                if self.view.safeAreaInsets.bottom*2 == 0 {
                    self.slideView!.center = CGPoint(x: self.slideView!.center.x, y: self.view.frame.maxY - 42)
                }else{
                    self.slideView!.center = CGPoint(x: self.slideView!.center.x, y: self.view.frame.maxY - self.view.safeAreaInsets.bottom*2 - 8)
                }
            }
        default:
            break
        }
    }
    
    private func handleMovingState(for gesture: UIPanGestureRecognizer) {
        
        guard let slideView = slideView else { return }
        let translation = gesture.translation(in: mainView)
        slideView.center = CGPoint(x: slideView.center.x, y: slideView.center.y + translation.y)
        gesture.setTranslation(CGPoint.zero, in: mainView)
        if slideView.frame.intersects(slideView.finishView.frame) {
            slideView.isHidden = true
            slideView.finishView.isHidden = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            handleUserDidSlide()
            gesture.isEnabled = false
        }
        
    }
    
    // MARK: USER DID SLIDE
    
    private func handleUserDidSlide() {
        UIView.animate(withDuration: 0.15) {
            self.curveMainView(by: 300)
            self.mainView.layer.cornerRadius = (self.view.frame.width+25)/2
        }
        UIView.animate(withDuration: 0.35, animations: {
            self.mainView.transform = CGAffineTransform(translationX: 0, y: -200)
            self.mainView.hideParticles()
            self.curveMainView(by: -300)
            self.mainView.layer.cornerRadius = (self.view.frame.width+300)/2
            self.blobViews?.handleSlideFrames()
        }) { (true) in
            self.activityLines?.setupCoordinates()
            self.activityLines?.handleLoginActivityLine()
            self.handleButtonsAnimation()
           // self.mainView.setupLogoView()
            self.mainView.logoView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            UIView.animate(withDuration: 0.3) {
                self.mainView.logoView.transform = .identity
            }
            self.setupInitialTFView()
        }
    }
    
    private func curveMainView(by value: CGFloat) {
        self.mainView.center.x += value/2
        self.mainView.frame.size.width -= value
    }
    
    private func handleButtonsAnimation() {
        handleLoginButton()
       // handleSignUpAnimation()
    }
    
    private func handleLoginButton() {
        loginButton = LoginButton(for: self)
        loginButton?.transform = CGAffineTransform(rotationAngle: (5 * .pi/3))
        loginButton?.center = CGPoint(x: -32, y: mainView.frame.minY + 50)
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.loginButton?.alpha = 1
            self.loginButton?.transform = CGAffineTransform(rotationAngle: (11 * .pi)/5.8)
            self.loginButton?.center = CGPoint(x: self.mainView.center.x/2-30, y: self.mainView.frame.minY)
        })
    }
    
    private func handleSignUpAnimation() {
        signUpButton = SignUpButton(for: self)
        signUpButton?.center = CGPoint(x: mainView.center.x, y: mainView.frame.minY)
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.signUpButton?.transform = CGAffineTransform(rotationAngle: (.pi)/8)
            self.signUpButton?.alpha = 0.3
            self.signUpButton?.center = CGPoint(x: self.mainView.center.x*1.5+32, y: self.mainView.frame.minY)
        })
    }
    
    // MARK: LOGIN BUTTON PRESSED
    @objc func loginButtonPressed() {
        guard loginButton?.alpha != 1 , let activityLines = activityLines else { return }
        activityLines.endSignUpActivityLine()
        handleTFFadeOut()
        let timer = Timer(timeInterval: 0.125, target: activityLines, selector: #selector(activityLines.handleLoginActivityLine), userInfo: nil, repeats: false)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        blobViews?.changeBlobColors(alpha: 0.2)
        UIView.animate(withDuration: 0.25, animations: {
            self.loginButton?.alpha = 1
            self.signUpButton?.alpha = 0.3
            self.mainView.logoView.tintColor = AppColors.lightGreen
        })
        animateGradientView(fromValue: [1,1], toValue: [0,0])
    }
    
    // MARK: SIGN UP BUTTON PRESSED
//    @objc func signUpButtonPressed() {
//        guard signUpButton?.alpha != 1, let activityLines = activityLines else { return }
//        activityLines.endLoginActivityLine()
//        handleTFFadeOut(isSignUp: true)
//        let timer = Timer(timeInterval: 0.125, target: activityLines, selector: #selector(activityLines.handleSignUpActivityLine), userInfo: nil, repeats: false)
//        RunLoop.current.add(timer, forMode: RunLoop.Mode.RunLoop.Mode.default)
//        blobViews?.changeBlobColors(alpha: 0.8)
//        UIView.animate(withDuration: 0.25, animations: {
//            self.signUpButton?.alpha = 1
//            self.loginButton?.alpha = 0.3
//            self.mainView.logoView.tintColor = AppColors.lightRed
//        })
//        animateGradientView(fromValue: [0,0], toValue: [1,1])
//    }
    
    private func animateGradientView(fromValue: [CGFloat], toValue: [CGFloat]) {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = 0.25
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        gradientView.add(animation, forKey: "changeColor")
    }
    
    private func handleTFFadeOut( isSignUp: Bool = false) {
        usernameTF?.fadeOut()
        passwordTF?.fadeOut()
        continueButton?.fadeOut()
        var timer = Timer()
        if isSignUp {
            timer = Timer(timeInterval: 0.3, target: self, selector: #selector(setupRegisterTF), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
            return
        }
        timer = Timer(timeInterval: 0.3, target: self, selector: #selector(setupLoginTF), userInfo: nil, repeats: false)
        RunLoop.current.add(timer, forMode:RunLoop.Mode.default)
    }
    
    @objc private func setupRegisterTF() {
        statusView = false
        usernameTF = UsernameTF(for: self, buttonPressed: true, animTime: 0.4)
        passwordTF = PasswordTF(for: self, isRegister: true, animTime: 0.4)
        continueButton = ContinueButton(for: self, isRegister: true, animTime: 0.4)
    }
    
    @objc private func setupLoginTF() {
        statusView = true
        usernameTF = UsernameTF(for: self, buttonPressed: true, animTime: 0.4)
         passwordTF = PasswordTF(for: self, animTime: 0.4)
         continueButton = ContinueButton(for: self, animTime: 0.4)
    }
    
    private func checkTF() -> String? {
        // setup your login logic here.
        // && passwordTF?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == ""
        if usernameTF?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
            return "Please enter the valid username."
        }
        return nil
    }

    public func sha256(token: String) -> String{
        let data = Data(token.utf8)
        return hexStringFromData(input: digest(input:data as NSData ))
       }
    
       
       private func digest(input : NSData) -> NSData {
           let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
           var hash = [UInt8](repeating: 0, count: digestLength)
           CC_SHA256(input.bytes, UInt32(input.length), &hash)
           return NSData(bytes: hash, length: digestLength)
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
    
   func getPostString(params:[String:Any]) -> String{
           var data = [String]()
           for(key, value) in params
           {
               data.append(key + "=\(value)")
           }
           return data.map { String($0) }.joined(separator: "&")
       }
    
    
    func JWSGeneration(UserName:String, completion: @escaping (_ success: Bool ,_ jwsToken:String?) -> ()){
        
    var Status:Bool = false
    var jwsToken:String?
    let Authorization = "Bearer TN5sBit7LEZEICw6ws8NG6NjiCHmzzdc"
    let salt = "3vGX1PaaC5RhYxTZqNtCMlQGgh0wPlRD"
    var deviceId = UIDevice.current.identifierForVendor!.uuidString
    let now = Date()
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: now)
    deviceId = deviceId.replacingOccurrences(of: "-", with: "", options: NSString.CompareOptions.literal, range: nil)
    let token = UserName + deviceId + dateString + salt
   
    self.deviceIDentication = deviceId
    self.username = UserName
    let PayloadData: Array<UInt8> = Array(token.utf8)
      let Payloadsalt: Array<UInt8> = Array(salt.utf8)
    do {
      
        let result = try! HMAC(key: Payloadsalt, variant: .sha256).authenticate(PayloadData)
        let hashdata = Data(result)
        var hmacHash = hexStringFromData(input: hashdata as NSData)
        hmacHash = hmacHash.lowercased()
//        let userdata : Data = "username=\(UserName)&deviceid=\(deviceId)&token=\(hmacHash)".data(using: .utf8)!
       
        let apidata: [String: Any] = ["username":UserName,"deviceid":deviceId,"timestamp":dateString,"token":hmacHash]
        let jsonData = try? JSONSerialization.data(withJSONObject: apidata)
        let urlstring = URL(string: "https://chat3.securesignal.in:5222/LMiO3U61XjUKsJWGgCPIMdFfKt36hrEh")

                var urlrequest = URLRequest(url: urlstring!)
                urlrequest.httpMethod = "POST"
                urlrequest.httpBody = jsonData
                urlrequest.setValue(Authorization, forHTTPHeaderField: "Authorization")
       // urlrequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
                                Status = true
                               jwsToken = json?["jws"] as? String
                              
                           }else if (status!.contains("ERROR:")){
                            Status = false
                            DispatchQueue.main.async {
                                if (status!.contains("0x2001")){
                                    self.passwordTF?.errorLabel.text = "OTP Not Sent"
                                }else if (status!.contains("0x3112")){
                                    self.passwordTF?.errorLabel.text = "Unauthorized"
                                }else if (status!.contains("0x3113")){
                                    self.passwordTF?.errorLabel.text = "Already Logged in"
                                }else if (status!.contains("0x3114")){
                                    self.passwordTF?.errorLabel.text =  "Wrong OTP"
                                }else if (status!.contains("0x3115")){
                                    self.passwordTF?.errorLabel.text = "Account Banned"
                                    
                                }else if (status!.contains("0x3116")){
                                    self.passwordTF?.errorLabel.text = "IP address blocked"
                                }else if (status!.contains("0x3117")){
                                    self.passwordTF?.errorLabel.text = "Account Not Found"
                                }
                                   
                               
                           
                               
                               // return self.status!
                           }
                           }}
                   catch {
                       print("cant parse json \(error)")
                       Status = false
                       }

                        completion(Status,jwsToken ?? nil)
                       }).resume()
    } catch {
        print(error.localizedDescription)
    }
    }
    
    func userNamePresence(UserName:String,jws:String, completion: @escaping (_ success: Bool) -> ()){
    
    var Status:Bool = false
    let Authorization = "Bearer TN5sBit7LEZEICw6ws8NG6NjiCHmzzdc"
    let salt = "3vGX1PaaC5RhYxTZqNtCMlQGgh0wPlRD"
    var deviceId = UIDevice.current.identifierForVendor!.uuidString
    let now = Date()
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: now)
    deviceId = deviceId.replacingOccurrences(of: "-", with: "", options: NSString.CompareOptions.literal, range: nil)
    let token = UserName + deviceId + dateString + salt
   
    self.deviceIDentication = deviceId
    self.username = UserName

//    let checksum = data?.sha256()
//    let hamcHash = hexStringFromData(input: checksum as! NSData)
    let PayloadData: Array<UInt8> = Array(token.utf8)
      let Payloadsalt: Array<UInt8> = Array(salt.utf8)
//    let keyData = salt.data(using:.utf8)!
//    let hmacdata =  hmac(hashName:"SHA256", message:tokendata!, key:keyData)
  

    do {
      
        let result = try! HMAC(key: Payloadsalt, variant: .sha256).authenticate(PayloadData)
        let hashdata = Data(result)
        var hmacHash = hexStringFromData(input: hashdata as NSData)
        hmacHash = hmacHash.lowercased()
//        let userdata : Data = "username=\(UserName)&deviceid=\(deviceId)&token=\(hmacHash)".data(using: .utf8)!
       
        let apidata: [String: Any] = ["username":UserName,"deviceid":deviceId,"timestamp":dateString,"jws":jws,"token":hmacHash]
        let jsonData = try? JSONSerialization.data(withJSONObject: apidata)
        let urlstring = URL(string: "https://chat.securesignal.in:5222/generatecode")

                var urlrequest = URLRequest(url: urlstring!)
                urlrequest.httpMethod = "POST"
                urlrequest.httpBody = jsonData
                urlrequest.setValue(Authorization, forHTTPHeaderField: "Authorization")
       // urlrequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
//                                let SuccessToken = status?.split(separator: "(")
//                                let token = SuccessToken![1].split(separator: ")")
//                                self.ValidationToken = String(token[0])
                                Status = true
                              // self.invokeAudioVideoCall(buddyjid: to, finalJWT: roomname)
                              //  return self.status!
                           }else if (status!.contains("ERROR:")){
                            Status = false
                            DispatchQueue.main.async {
                                if (status!.contains("0x2001")){
                                    self.passwordTF?.errorLabel.text = "OTP Not Sent"
                                }else if (status!.contains("0x3112")){
                                    self.passwordTF?.errorLabel.text = "Unauthorized"
                                }else if (status!.contains("0x3113")){
                                    self.passwordTF?.errorLabel.text = "Already Logged in"
                                }else if (status!.contains("0x3114")){
                                    self.passwordTF?.errorLabel.text =  "Wrong OTP"
                                }else if (status!.contains("0x3115")){
                                    self.passwordTF?.errorLabel.text = "Account Banned"
                                    
                                }else if (status!.contains("0x3116")){
                                    self.passwordTF?.errorLabel.text = "IP address blocked"
                                }else if (status!.contains("0x3117")){
                                    self.passwordTF?.errorLabel.text = "Account Not Found"
                                }
                                   
                               
                           
                               
                               // return self.status!
                           }
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
    
    func goToNextController() {
        if let error = checkTF() {
            passwordTF?.errorLabel.text = error
            return
        }

        continueButton!.startAnimation() // 2: Then start the animation when the user tap the button
              let qualityOfServiceClass = DispatchQoS.QoSClass.background
              let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
              backgroundQueue.async(execute: {
// 3: Do your networking task or background work here.
                DispatchQueue.main.async {
//                    self.JWSGeneration(UserName: (self.usernameTF?.text)!) { Validstatus, token in
//                        if (Validstatus == true && token != nil) {
                       
                    self.userNamePresence(UserName: (self.usernameTF?.text)!, jws: self.token ) { (status) in
                                if (status == true ){

                                    DispatchQueue.main.async(execute: { () -> Void in

                                      self.continueButton!.stopAnimation(animationStyle: .expand, completion: {

                                        let OTPSubmitVC : LoginIdVerifyVC =
                                            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPVerifyVC") as! LoginIdVerifyVC;
                                        OTPSubmitVC.VerificationString = self.ValidationToken
                                        OTPSubmitVC.DeviceID  = self.deviceIDentication
                                        OTPSubmitVC.username = self.username
                                        OTPSubmitVC.JWSToken = self.token
                                         let OTPnavigationController = UINavigationController.init(rootViewController: OTPSubmitVC)
                                         OTPnavigationController.modalPresentationStyle = .overFullScreen
                                         self.present(OTPnavigationController, animated: true, completion: nil)
                                       
                                        })
                                    })

                                }else{
                                    DispatchQueue.main.async {
                                        self.continueButton!.stopAnimation(animationStyle: .shake, completion: {
                                          //  self.passwordTF?.errorLabel.text = "Unauthorized"
                                           // self.continueButton = ContinueButton(for: self)
                                          })

                                    }
                                }
                        }
//                    }
//                    }
                }
              })
          }
    
 
          
    func hmac(hashName:String, message:Data, key:Data) -> Data? {
        let algos = ["SHA1":   (kCCHmacAlgSHA1,   CC_SHA1_DIGEST_LENGTH),
                     "MD5":    (kCCHmacAlgMD5,    CC_MD5_DIGEST_LENGTH),
                     "SHA224": (kCCHmacAlgSHA224, CC_SHA224_DIGEST_LENGTH),
                     "SHA256": (kCCHmacAlgSHA256, CC_SHA256_DIGEST_LENGTH),
                     "SHA384": (kCCHmacAlgSHA384, CC_SHA384_DIGEST_LENGTH),
                     "SHA512": (kCCHmacAlgSHA512, CC_SHA512_DIGEST_LENGTH)]
        guard let (hashAlgorithm, length) = algos[hashName]  else { return nil }
        var macData = Data(count: Int(length))

        macData.withUnsafeMutableBytes {macBytes in
            message.withUnsafeBytes {messageBytes in
                key.withUnsafeBytes {keyBytes in
                    CCHmac(CCHmacAlgorithm(hashAlgorithm),
                           keyBytes,     key.count,
                           messageBytes, message.count,
                           macBytes)
                }
            }
        }
        return macData
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 1) {
            textField.layer.borderWidth = 1
            textField.layer.borderColor = AppColors.lightGreen.cgColor
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 1) {
            textField.layer.borderWidth = 0
        }
    }
    
    // MARK: NOTIFICATION CENTER
//
    func notificationCenterHandler() {
        
            
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: Notification.Name.UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: Notification.Name.UIResponder.keyboardWillHideNotification, object: nil)
//

        hideKeyboardOnTap()
    }

    @objc func handleKeyboardWillShow(notification: NSNotification){
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            print("notification: Keyboard will show")
           
            keyboardIsShown = true
//            if self.view.frame.origin.y == 0{
//                self.view.frame.origin.y -= keyboardSize.height
//            }
         //  self.continueButton?.frame.origin.y -= keyboardSize.height
        }
//        let kDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
//        guard let duration = kDuration else { return }
//        if !keyboardIsShown {
//            view.frame.origin.y -= 50
//        }
//        UIView.animate(withDuration: duration) {
//            self.view.layoutIfNeeded()
//        }
//        keyboardIsShown = true
    }

    @objc func handleKeyboardWillHide(notification: NSNotification){
//        let kDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
//        guard let duration = kDuration else { return }
//        view.frame.origin.y = 0
//        keyboardIsShown = false
//        UIView.animate(withDuration: duration) {
//            self.view.layoutIfNeeded()
//        }
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
//             if self.view.frame.origin.y != 0 {
//                 self.view.frame.origin.y += keyboardSize.height
//             }
           // self.continueButton?.frame.origin.y +=  keyboardSize.height
         }
        
    }
    
    private func hideKeyboardOnTap(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func hideKeyboard(){
        view.endEditing(true)
        keyboardIsShown = false
    }
    
}

