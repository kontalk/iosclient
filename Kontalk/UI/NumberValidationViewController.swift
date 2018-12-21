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

import XMPPFramework

class NumberValidationViewController: BaseViewController, FPNTextFieldDelegate, XMPPStreamDelegate, KontalkRegistrationDelegate {
    
    @IBOutlet weak var textViewFirstIntro: UITextView!
    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var numberTextField: FPNTextField!
    @IBOutlet weak var buttonRegister: KontalkUIButton!
    @IBOutlet weak var textViewSecondIntro: UITextView!
    
    var isValidNumber: Bool = false
    
    let xmppStream = XMPPStream()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    
    func initUI() {
        textViewFirstIntro.text = "number_validation_intro1".localized()
        textViewSecondIntro.text = "number_validation_intro2".localized()
    
        textFieldName.placeholder = "title_no_name".localized()
        
        buttonRegister.setTitle("button_validate".localized(), for: .normal)
        
        numberTextField.parentViewController = self
        numberTextField.flagPhoneNumberDelegate = self
        
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
                self.xmppRegister()
            }
    }
    
    func xmppRegister() {
        DDLog.add(DDTTYLogger.sharedInstance, with: DDLogLevel.all)
        xmppStream.hostName = "prime.kontalk.net"
        xmppStream.hostPort = 7222
        //xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        
        let xmppRosterStorage = XMPPRosterCoreDataStorage()
        let xmppRoster: XMPPRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        
        xmppRoster.activate(xmppStream)
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        xmppStream.myJID = XMPPJID(string: "prime@prime.kontalk.net")
        
        do {
            try xmppStream.connect(withTimeout: 10000)
        } catch {
            log.error("could not connect")
        }
        
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        let x = XMPPRegistration.init()
        x.addDelegate(self, delegateQueue: DispatchQueue.main)
        x.activate(xmppStream)
        x.numberValidation(numberTextField.getFormattedPhoneNumber(format: .E164) ?? "", acceptTerms: true)
    }
    
    func numberValidationSuccessful(_ sender: XMPPRegistration) {
        hideLoader()
    }
    
    func numberValidationFailed(_ sender: XMPPRegistration, withError error: Error?) {
        hideLoader()
        log.error(error)
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        isValidNumber = isValid
    }
    
}
