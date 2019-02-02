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
import ObjectivePGP
import CommonCrypto
import Security

extension Data {
    func castToCPointer<T>() -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
}

class PersonalKey {
    
    var publicKey: Array<Key>
    let secretKey: Array<Key>
    let passphrase: String

    init(publicKey: Array<Key>, secretKey: Array<Key>, passphrase: String) {
        self.publicKey = publicKey
        self.secretKey = secretKey
        self.passphrase = passphrase
    }

    func getBridgeCertificate() -> (Data, Data) {
        
        let x509Bridge = X509Bridge.init()
        
        do {
            
            let publicKeyPacket = publicKey[0].publicKey?.primaryKeyPacket as! PGPPublicKeyPacket
            
            let secretKeyPacket = try secretKey[0].secretKey?.decrypted(withPassphrase: passphrase).primaryKeyPacket as! PGPSecretKeyPacket
            
            let n = publicKeyPacket.publicMPI(PGPMPI_N)?.bigNum
            let e = publicKeyPacket.publicMPI(PGPMPI_E)?.bigNum
            let d = secretKeyPacket.secretMPI(PGPMPI_D)?.bigNum
            let p = secretKeyPacket.secretMPI(PGPMPI_P)?.bigNum
            let q = secretKeyPacket.secretMPI(PGPMPI_Q)?.bigNum
            let u = secretKeyPacket.secretMPI(PGPMPI_U)?.bigNum
            
            let privateKey = x509Bridge.createPrivateRSAKey(withParams: n, e, d, p, q, u)
            
            let certificate = x509Bridge.createX509Certificate(withPrivateKey: privateKey, withPublicKey: try publicKey[0].export(), withPassphrase: passphrase)
            return (privateKey!, certificate!)
        } catch {
            log.error("error")
        }

        return (Data(), Data())
    }
    
    func getIdentity() -> SecIdentity {
        let (key, cer) = getBridgeCertificate()
        
        let password = "kontalk"
        let options = [ kSecImportExportPassphrase as String: password ]
        
        var rawItems: CFArray?
        let status = SecPKCS12Import(cer as CFData,
                                     options as CFDictionary,
                                     &rawItems)
        
        if status != errSecSuccess {
//            throw <# an error #>
            log.error("error")
        }
        
        let items = rawItems! as! Array<Dictionary<String, Any>>
        let firstItem = items[0]
        
        let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity?
        
        return identity!
    }

    static func generateKey(uid: String, name: String, passphrase: String, network: String) throws -> PersonalKey {
        let userId = name + " <" + uid + "@" + network + ">"
        let keyGen = KeyGenerator()
        keyGen.keyBitsLength = 2048
        keyGen.keyAlgorithm = PGPPublicKeyAlgorithm.RSA
        let key = keyGen.generate(for: userId, passphrase: passphrase)
        let publicKey = try key.export(keyType: .public)
        let secretKey = try key.export(keyType: .secret)
        
        return PersonalKey(publicKey: try ObjectivePGP.readKeys(from: publicKey), secretKey: try ObjectivePGP.readKeys(from: secretKey), passphrase: passphrase)
    }
}
