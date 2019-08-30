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

class ViewController: UIViewController, XMPPStreamDelegate {
    
    var xmppStream: XMPPStream?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        xmppStream = AppDelegate.shared.xmppStream
        xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        do {
            try self.xmppStream?.connect(withTimeout: 10000)
        } catch {
            log.error("could not connect")
        }
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        var auth = XMPPExternalAuthentication.init(stream: xmppStream!, password: "")
        do {
            try xmppStream?.authenticate(auth)
            
            
        } catch {
            log.error("Errore autenticazione")
        }
    }

    func xmppStream(_ sender: XMPPStream, willSecureWithSettings settings: NSMutableDictionary) {
        var identity: AnyObject?
        let searchQuery: NSMutableDictionary = NSMutableDictionary(objects: [String(kSecClassIdentity), kCFBooleanTrue], forKeys: [String(kSecClass) as NSCopying,String(kSecReturnRef) as NSCopying])
        let status:OSStatus = SecItemCopyMatching(searchQuery as CFDictionary, &identity)
        
        settings.setValue([identity as! SecIdentity], forKey: kCFStreamSSLCertificates as NSString as String)
        
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

