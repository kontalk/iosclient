//
//  Crypto.h
//  IAIK Encryption App
//
//  Created by Christof Stromberger on 29.02.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Types.h"
#import <openssl/x509.h>
#import <ObjectivePGP/ObjectivePGP.h>


@interface X509Bridge : NSObject

+ (X509Bridge*) getInstance;

- (X509*) loadCertificateFromFile:(NSString*)pathToCertificate;

- (NSData*)convertX509CertToNSData:(X509*)certificate;

- (NSData*)createRSAKey;
- (NSData*)createRSAKeyWithKeyLength:(int)length;

- (NSData*)createPrivateRSAKeyWithParams:(PGPBigNum*)n :(PGPBigNum*)e :(PGPBigNum*)d :(PGPBigNum*)p :(PGPBigNum*)q :(PGPBigNum*)u;

- (NSData*) convertPrivateKeyToDer:(NSData*)key passphrase:(NSString*)passphrase;

- (EVP_PKEY*) loadPrivateKeyFromFile:(NSString*)pathToPrivateKey
                      withPassphrase:(NSString*)passphrase;

- (NSDate*)getExpirationDateOfCertificate:(NSData*)cert;

//new
- (NSData*)createX509CertificateWithPrivateKey:(NSData*)pkey
                                      withPublicKey:(NSData*)publicKey
                                  withPassphrase:(NSString*)passphrase;

- (NSData*) saveP12FromX509:(X509*)certificate :(NSData*)privateKey :(NSString*)password;

- (NSData*) getDataFromP12:(NSString*) path :(NSString*)password;

- (void) addExtensionToCert:(X509*)cert
                     withId:(int)nid
                   andValue:(NSString*)value;

- (void) addTextEntryToCert:(X509_NAME**)name
                     forKey:(NSString*)key
                  withValue:(NSString*)value;


- (void) throwWithText:(NSString*)message;

@end
