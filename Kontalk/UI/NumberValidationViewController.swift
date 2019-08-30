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

import UIKit
import Foundation
import FlagPhoneNumber
import RxSwift
import RxCocoa
import libPhoneNumber_iOS
import PassKit

class NumberValidationViewController: BaseViewController, FPNTextFieldDelegate, XMPPStreamDelegate, KontalkRegistrationDelegate {
    
    @IBOutlet weak var textViewFirstIntro: UITextView!
    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var numberTextField: FPNTextField!
    @IBOutlet weak var buttonRegister: KontalkUIButton!
    @IBOutlet weak var textViewSecondIntro: UITextView!
    
    var isValidNumber: Bool = false
    
    var xmppStream: XMPPStream?
    let kontalkRegister = XMPPRegistration.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var payButton = PKAddPassButton.init(addPassButtonStyle: .black)
        self.view.addSubview(payButton)
        
        
//        var identity: AnyObject?
//        let searchQuery: NSMutableDictionary = NSMutableDictionary(objects: [String(kSecClassIdentity), kCFBooleanTrue], forKeys: [String(kSecClass) as NSCopying,String(kSecReturnRef) as NSCopying])
//        let status:OSStatus = SecItemCopyMatching(searchQuery as CFDictionary, &identity)
        
        xmppStream = AppDelegate.shared.xmppStream
        
        kontalkRegister.activate(xmppStream!)
        
        initUI()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        kontalkRegister.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        xmppStream?.removeDelegate(self)
        kontalkRegister.removeDelegate(self)
    }
    
    func initUI() {
        title = "Kontalk"
        self.navigationController?.navigationBar.tintColor = .white
        
        textViewFirstIntro.text = "number_validation_intro1".localized()
        textViewSecondIntro.text = "number_validation_intro2".localized()
    
        textFieldName.placeholder = "title_no_name".localized()
        
        buttonRegister.setTitle("button_validate".localized(), for: .normal)
        
        numberTextField.parentViewController = self
        numberTextField.delegate = self
        
        if let countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String {
            numberTextField.setFlag(for: FPNCountryCode.init(rawValue: countryCode) ?? .US)
        }
        
        buttonRegister.rx.tap.asObservable()
            .filter({ (_) -> Bool in
                guard !((self.textFieldName.text ?? "")?.isEmpty)! else {
                    self.showMessageAlert(withTitle: "", andMessage: "msg_no_name".localized())
                    self.textFieldName.becomeFirstResponder()
                    return false
                }
            
                guard self.isValidNumber else {
                    self.showMessageAlert(withTitle: "", andMessage: "warn_invalid_number".localized())
                    self.numberTextField.becomeFirstResponder()
                    return false
                }
                
                return true
            })
            .subscribe { _ in
                self.showLoader()
                self.xmppConnect()
            }
    }
    
    func xmppConnect() {
        if (!xmppStream!.isConnected) {
            DispatchQueue.main.async {
                do {
                    try AppDelegate.shared.xmppStream.connect(withTimeout: 10000)
                } catch {
                    log.error("could not connect")
                }
            }
        }
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        log.info("Connected")
        kontalkRegister.numberValidation(numberTextField.getFormattedPhoneNumber(format: .E164) ?? "", acceptTerms: true, forceRegistration: false)
    }
    
    func numberValidationSuccessful(_ sender: XMPPRegistration, _ challengeType: String) {
        hideLoader()
        let storyBoard: UIStoryboard = UIStoryboard(name: "Registration", bundle: nil)
        let codeValidationViewController = storyBoard.instantiateViewController(withIdentifier: "codeValidationViewController") as! CodeValidationViewController
        codeValidationViewController.phoneNumber = numberTextField.getFormattedPhoneNumber(format: .E164)
        codeValidationViewController.challengeType = challengeType
        self.navigationController?.pushViewController(codeValidationViewController, animated: true)
    }
    
    func numberValidationFailed(_ sender: XMPPRegistration, withError error: DDXMLElement?) {
        hideLoader()
        log.error(error?.xmlString ?? "")
        if (error != nil) {
            let errorCode = error?.attributeIntValue(forName: "code")
            if (errorCode == 409) {
                forceRegistration()
            } else {
                let errorText = error?.element(forName: "text", xmlnsPrefix: "")
                showMessageAlert(withTitle: "", andMessage: errorText?.stringValue! ?? "")
            }
        }
    }
    
    func forceRegistration() {
        let alertController = UIAlertController(title: "", message: "err_validation_user_exists".localized(), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "ok".localized(), style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.showLoader()
            self.kontalkRegister.numberValidation(self.numberTextField.getFormattedPhoneNumber(format: .E164) ?? "",
                                                  acceptTerms: true, forceRegistration: true)
        }
        let cancelAction = UIAlertAction(title: "cancel".localized(), style: UIAlertAction.Style.cancel) {
            UIAlertAction in
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        isValidNumber = isValid
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        log.error(error.debugDescription)
    }
}
