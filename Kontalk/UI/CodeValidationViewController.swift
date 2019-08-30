//
//  Kontalk iOS client
//  Copyright (C) 2018 Kontalk Devteam <devteam@kontalk.org>
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import UIKit

class CodeValidationViewController: BaseViewController, XMPPStreamDelegate, KontalkRegistrationDelegate {
    
    @IBOutlet weak var labelPoweredBy: UILabel!
    @IBOutlet weak var imgPoweredBy: UIImageView!
    @IBOutlet weak var textViewIntro: UITextView!
    @IBOutlet weak var textFieldCode: UITextField!
    @IBOutlet weak var btnVerify: KontalkUIButton!
    @IBOutlet weak var btnFallback: KontalkUIButton!
    
    var isCodeValidated = false
    
    var personalKey: PersonalKey!
    
    var phoneNumber: String!
    var challengeType: String!
    
    var brandLink: String?
    var brandImage:String?
    
    var xmppStream: XMPPStream?
    let kontalkRegister = XMPPRegistration.init()
    
    override func viewDidLoad() {
        
        xmppStream = AppDelegate.shared.xmppStream
        
        xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        kontalkRegister.addDelegate(self, delegateQueue: DispatchQueue.main)
        kontalkRegister.activate(xmppStream!)
        
        initUI()
    }
    
    func initUI() {
        if (brandLink == nil && brandImage == nil) {
            labelPoweredBy.updateConstraint(attribute: NSLayoutConstraint.Attribute.height, constant: 0)
            imgPoweredBy.updateConstraint(attribute: NSLayoutConstraint.Attribute.height, constant: 0)
        } else {
            
        }
        labelPoweredBy.text = "registration_poweredby".localized()
        textViewIntro.text = "code_validation_intro".localized()
        textFieldCode.placeholder = "hint_validation_code".localized()
        btnVerify.setTitle("button_validation_register".localized(), for: .normal)
        btnFallback.setTitle("button_validation_fallback".localized(), for: .normal)
        
        btnVerify.rx.tap.asObservable()
            .filter({ (_) -> Bool in
                guard !((self.textFieldCode.text ?? "")?.isEmpty)! else {
                    self.showMessageAlert(withTitle: "", andMessage: "msg_invalid_code".localized())
                    self.textFieldCode.becomeFirstResponder()
                    return false
                }
                
                return true
            })
            .subscribe { _ in
                self.showLoader()
                self.validateCode()
        }
    }
    
    func validateCode() {
        xmppStream?.disconnect()
                DispatchQueue.main.async {
                    do {
                        self.personalKey = try PersonalKey.generateKey(uid: self.phoneNumber.sha1(), name: "Andrea", passphrase: String().randomString(length: 40), network: "prime.kontalk.net")
                        do {
                            try self.xmppStream?.connect(withTimeout: 10000)
                        } catch {
                            log.error("could not connect")
                        }
                    } catch {
                        log.error("could not connect")
                    }
                }
        kontalkRegister.codeValidation(textFieldCode.text!)
    }
    
    func codeValidationFailed(_ sender: XMPPRegistration, withError error: DDXMLElement?) {
        hideLoader()
    }
    
    func codeValidationSuccessful(_ sender: XMPPRegistration, _ publicKey: String) {
        isCodeValidated = true
        hideLoader()
        do {
            personalKey.publicKey = try ObjectivePGP.readKeys(from: Data(base64Encoded: publicKey)!)
            xmppStream?.disconnect()
            try self.xmppStream?.connect(withTimeout: 10000)
        }
        catch {
            log.error("Public Key Error")
        }
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        if (!isCodeValidated) {
            kontalkRegister.codeValidation(textFieldCode.text!)
        } else {
            var auth = XMPPExternalAuthentication.init(stream: xmppStream!, password: "")
            do {
                try xmppStream?.authenticate(auth)
                
                
            } catch {
                log.error("Errore autenticazione")
            }
        }
        
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {

    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        
    }
    
    func xmppStream(_ sender: XMPPStream, willSecureWithSettings settings: NSMutableDictionary) {
        
        settings.setValue([personalKey?.getIdentity()], forKey: kCFStreamSSLCertificates as NSString as String)
        
        settings.setValue(xmppStream?.myJID?.domain, forKey: kCFStreamSSLPeerName as NSString as String)
        
        settings.setValue(SSLAuthenticate.alwaysAuthenticate.rawValue, forKey: GCDAsyncSocketSSLClientSideAuthenticate)
        
        settings.setValue(true, forKey: GCDAsyncSocketManuallyEvaluateTrust)
        
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        
        //        DispatchQueue.global(qos: .default).async {
        //            var result: SecTrustResultType =  kSecTrustResultDeny as! SecTrustResultType
        //            let status = SecTrustEvaluate(trust, &result)
        //
        //            if status == noErr {
        //                completionHandler(true)
        //            } else {
        //                completionHandler(false)
        //            }
        //        }
        
        completionHandler(true)
    }
}
