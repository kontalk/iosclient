//
//  Crypto.m
//  IAIK Encryption App
//
//  Created by Christof Stromberger on 29.02.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "X509Bridge.h"

//openssl includes
#include <openssl/cms.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/bn.h>
#include <openssl/pkcs12.h>

#include "openssl/rsa.h"
#import <ObjectivePGP/ObjectivePGP.h>

@interface X509Bridge()

- (EVP_PKEY*)convertNSDataToPrivateKey:(NSData*)pkey
                            passphrase:(NSString*)passphrase;


@end

@implementation X509Bridge

static X509Bridge *instance = NULL;


static void callback(int p, int n, void *arg);

/* getInstance
 * Singleton pattern instance method
 */
+ (X509Bridge*) getInstance {
    @synchronized(self) {
        if (instance == NULL) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

- (NSData*)convertX509CertToNSData:(X509*)certificate
{
    
    BIO *out = BIO_new(BIO_s_mem());

    PEM_write_bio_X509(out, certificate);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(out, &outputBuffer);
    NSData *temp = [NSData dataWithBytes:outputBuffer length:outputLength];
    
    return temp;
}

- (NSData*)createRSAKey
{
    return [self createRSAKeyWithKeyLength:2048];
}


//creating a new RSA key using OpenSSL with a particular length
- (NSData*)createRSAKeyWithKeyLength:(int)length
{
    NSData *key; 
    EVP_PKEY *pkey = EVP_PKEY_new();
    
    BIO *outKey = BIO_new(BIO_s_mem());
    
    RSA *rsa = RSA_generate_key(length, RSA_F4, callback, NULL);
    if (!EVP_PKEY_assign_RSA(pkey, rsa)) {
        [self throwWithText:@"RSA key creation failed"];
    }
    
    PEM_write_bio_PrivateKey(outKey, pkey, NULL, NULL, 0, NULL, NULL);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(outKey, &outputBuffer);
    key = [NSData dataWithBytes:outputBuffer length:outputLength];
    
    return key;
}

- (NSData*)createPrivateRSAKeyWithParams:(PGPBigNum*)n :(PGPBigNum*)e :(PGPBigNum*)d :(PGPBigNum*)p :(PGPBigNum*)q :(PGPBigNum*)u{
    EVP_PKEY *pkey = EVP_PKEY_new();
    
    BIO *outKey = BIO_new(BIO_s_mem());
    
    RSA *rsa = RSA_new();
    
    rsa->version = 0;
    rsa->n = [self dataToBigNum:[n data]];
    rsa->e = [self dataToBigNum:[e data]];
    rsa->d = [self dataToBigNum:[d data]];
    
    rsa->dmp1 = [self exponentOperation:[self dataToBigNum:[d data]] :[self dataToBigNum:[p data]]];
    rsa->dmq1 = [self exponentOperation:[self dataToBigNum:[d data]] :[self dataToBigNum:[q data]]];
    rsa->p = [self dataToBigNum:[p data]];
    rsa->q = [self dataToBigNum:[q data]];
    //rsa->iqmp = [self dataToBigNum:[u data]];
    BN_CTX *ctx2 = BN_CTX_new();
    rsa->iqmp = BN_mod_inverse(NULL, rsa->q, rsa->p, ctx2);
    
    if (!EVP_PKEY_assign_RSA(pkey, rsa)) {
        [self throwWithText:@"RSA key creation failed"];
    }
    
    PEM_write_bio_PrivateKey(outKey, pkey, NULL, NULL, 0, NULL, NULL);
    
    NSData *key;
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(outKey, &outputBuffer);
    key = [NSData dataWithBytes:outputBuffer length:outputLength];
    
    return key;
}

- (BIGNUM*) exponentOperation:(BIGNUM*)d :(BIGNUM*)x {
    BN_CTX *ctx = BN_CTX_new();
    
    BN_CTX_start(ctx);
    
    BIGNUM* sub = BN_CTX_get(ctx);
    
    if (!BN_sub(sub, x, BN_value_one()))
        return NULL;
    
    BIGNUM* res = BN_new();
    
    if(!BN_mod(res, d, sub, ctx))
        return NULL;
    
    return res;
}

- (BIGNUM *)dataToBigNum:(NSData*)num {
    return BN_bin2bn(num.bytes, num.length, NULL);
}



- (EVP_PKEY*)convertNSDataToPrivateKey:(NSData*)pkey
{
    EVP_PKEY *rkey;
    BIO *inKey = BIO_new_mem_buf((void*)[pkey bytes], [pkey length]);
    
    rkey = PEM_read_bio_PrivateKey(inKey, NULL, 0, NULL);
    
    return rkey;
}

- (NSData*) convertPrivateKeyToDer:(NSData*)key passphrase:(NSString*)passphrase {
    NSData *derKey;
    EVP_PKEY *rkey = [self convertNSDataToPrivateKey:key passphrase:passphrase];
    
    BIO *outKey = BIO_new(BIO_s_mem());
    i2d_PUBKEY_bio(outKey, rkey);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(outKey, &outputBuffer);
    derKey = [NSData dataWithBytes:outputBuffer length:outputLength];
    
    return derKey;
}

#pragma mark - Get Expiration Date
- (NSDate*)getExpirationDateOfCertificate:(NSData*)cert
{
    //parsing nsdata to x.509 object
    BIO *inCert = BIO_new_mem_buf((void*)[cert bytes], [cert length]);
    if (!inCert) {
        [self throwWithText:@"Could not load mem BIO for X509 NSData"];
    }
    
    X509 *certificate = d2i_X509_bio(inCert, NULL);
    if (!certificate) {
        [self throwWithText:@"Could not load X509 certificate from BIO"];
    }
    
    /*X509_EXTENSION *ext = X509_get_ext(certificate, 0);
       
    ASN1_TIME *begin = X509_get_notBefore(certificate);
    ASN1_TIME *end = X509_get_notAfter(certificate);*/  
    
    
    NSDate *expiryDate = nil;
    
    if (certificate != NULL) {
        ASN1_TIME *certificateExpiryASN1 = X509_get_notAfter(certificate);
        if (certificateExpiryASN1 != NULL) {
            ASN1_GENERALIZEDTIME *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(certificateExpiryASN1, NULL);
            if (certificateExpiryASN1Generalized != NULL) {
                unsigned char *certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized);
                
                NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
                NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
                
                expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
                expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
                expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
                expiryDateComponents.hour   = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
                expiryDateComponents.minute = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
                expiryDateComponents.second = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];
                
                NSCalendar *calendar = [NSCalendar currentCalendar];
                expiryDate = [calendar dateFromComponents:expiryDateComponents];
            }
        }
    }
    
    return expiryDate;
    
}

- (X509*) loadCertificateFromFile:(NSString*)pathToCertificate {
    
    OpenSSL_add_all_algorithms();
	ERR_load_crypto_strings();
    
    BIO *certBio = BIO_new_file([pathToCertificate cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    if (!certBio) {
        [self throwWithText:@"Could not load certificate BIO"];
    }
    
    X509 *cert = d2i_X509_bio(certBio, NULL);
    if (!cert) {
        [self throwWithText:@"Could not load X509 certificate from BIO"];
    }
    
    return cert;
}

- (EVP_PKEY*) loadPrivateKeyFromFile:(NSString*)pathToPrivateKey
                      withPassphrase:(NSString*)passphrase {
    
    EVP_PKEY *rkey = NULL;
    
    OpenSSL_add_all_algorithms();
	ERR_load_crypto_strings();
    
    BIO *pkey = BIO_new_file([pathToPrivateKey cStringUsingEncoding:NSUTF8StringEncoding], "r");
    rkey = PEM_read_bio_PrivateKey(pkey, NULL, 0, (void*)[passphrase cStringUsingEncoding:NSUTF8StringEncoding]);
	if (!rkey) {
        [self throwWithText:@"Certificate or primary key was not valid"];
        
    }
    
    return rkey;
}

- (NSData*) saveP12FromX509:(X509*)certificate :(NSData*)privateKey :(NSString*)password {
    PKCS12 *p12;
    
    EVP_PKEY *key = [self convertNSDataToPrivateKey:privateKey];
    
    SSLeay_add_all_algorithms();
    ERR_load_crypto_strings();
    
    
    p12 = PKCS12_create("kontalk", "prime.kontalk.net", key, certificate, NULL, 0,0,0,0,0);
    
    if(!p12) {
        fprintf(stderr, "Error creating PKCS#12 structure\n");
        ERR_print_errors_fp(stderr);
        exit(1);
    }
    
    NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *p12FilePath = [documentsFolder stringByAppendingPathComponent:@"CERT.p12"];
    if (![[NSFileManager defaultManager] createFileAtPath:p12FilePath contents:nil attributes:nil])
    {
        NSLog(@"Error creating file for P12");
        @throw [[NSException alloc] initWithName:@"Fail getP12File" reason:@"Fail Error creating file for P12" userInfo:nil];
    }
    
    //get a FILE struct for the P12 file
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:p12FilePath];
    FILE *p12File = fdopen([outputFileHandle fileDescriptor], "w");
    
    i2d_PKCS12_fp(p12File, p12);
    PKCS12_free(p12);
    fclose(p12File);
    
    if([[NSFileManager defaultManager] fileExistsAtPath:p12FilePath])
    {
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:p12FilePath];
        return data;
    }
    else
    {
        NSLog(@"File not exits");
    }
    return NULL;
}

/**
 * createX509CertificateWith...
 * This method is a objective-c wrapper for creating certificates 
 * with a given private key as NSData*
 */
- (NSData*)createX509CertificateWithPrivateKey:(NSData*)pkey withPublicKey:(NSData *)publicKey withPassphrase:(NSString *)passphrase
{
    NSData *cert;
    BIO *outCert = BIO_new(BIO_s_mem());
    
    BIO *bio_err;
	X509 *x509=NULL;
    
	CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON);
    
	bio_err=BIO_new_fp(stderr, BIO_NOCLOSE);
    
    EVP_PKEY *key = [self convertNSDataToPrivateKey:pkey];
    
    [self createNewCertificate:&x509 withPrivateKey:&key withPublicKey:publicKey andExpiresIn:365];
	CRYPTO_cleanup_all_ex_data();
    
	CRYPTO_mem_leaks(bio_err);
	BIO_free(bio_err);
    
    i2d_X509_bio(outCert, x509);

    /*char *outputBuffer;
    long outputLength = BIO_get_mem_data(outCert, &outputBuffer);
    cert = [NSData dataWithBytes:outputBuffer length:outputLength];*/
    
    NSData *p12Data = [self saveP12FromX509:x509 :pkey :@"kontalk"];
    
//    BIO *bio = NULL;
//    char *pem = NULL;
//
//    /*if (NULL == cert) {
//        return NULL;
//    }*/
//
//    bio = BIO_new(BIO_s_mem());
//    if (NULL == bio) {
//        return NULL;
//    }
//
//    if (0 == PEM_write_bio_X509(bio, x509)) {
//        BIO_free(bio);
//        return NULL;
//    }
//
//    pem = (char *) malloc(bio->num_write + 1);
//    if (NULL == pem) {
//        BIO_free(bio);
//        return NULL;
//    }
//
//    memset(pem, 0, bio->num_write + 1);
//    BIO_read(bio, pem, bio->num_write);
//    BIO_free(bio);
//
//    cert = [NSData dataWithBytes:pem length:strlen(pem)];
    
    BIO_free(outCert);
    X509_free(x509);
    
    return p12Data;
}


/**
 * createNewCertificate
 * This method creates a new certificate and sets the issuer and subject 
 * fields correctly. It sets both (issuer and subject) because of it's a 
 * self signed certificate. As parameters this method takes a reference to 
 * the certificate in which everything is stored, then a reference to the 
 * users private key (should be RSA) and a serial number and a expiration 
 * date. Furthermore it sets the users issuer and subject attributes such as 
 * common name, email address, country, city, organization and organization unit.
 */
- (void) createNewCertificate:(X509**)x509p
               withPrivateKey:(EVP_PKEY**)pkeyp
                withPublicKey:(NSData*)publicKey
                 andExpiresIn:(int)days {
	X509 *x;
	EVP_PKEY *pk;
	X509_NAME *name = NULL;
	
    //debug
    if (*pkeyp == NULL) {
        [self throwWithText:@"Private key was null. This should not happen! You have to initialize it before calling createNewCertificate"];
    }
    pk= *pkeyp;
    x = X509_new();
    
    //x509 stuff
	X509_set_version(x, 2);
    
    //creating new serial number (64 bit)
    ASN1_INTEGER *sno = ASN1_INTEGER_new();
    BIGNUM *b = BN_new();
    if (!BN_pseudo_rand(b, 64, 0, 0)) {
        [self throwWithText:@"Creating random serial number failed"];
    }
    BN_to_ASN1_INTEGER(b, sno);
    
    //setting serial number
    X509_set_serialNumber(x, sno); //todo use this for a random serial number
    //int serial = 123456789;
    //ASN1_INTEGER_set(X509_get_serialNumber(x), serial);
    
    
    //debug test!!!
//    BIO *stdoutput = BIO_new_fp(stdout, BIO_NOCLOSE);
//    BN_print(stdoutput, b); //todo
//    
	X509_gmtime_adj(X509_get_notBefore(x), 0);
	X509_gmtime_adj(X509_get_notAfter(x), (long)60*60*24*days);
	X509_set_pubkey(x, pk);
    
    //retrieving X509_name
	name = X509_get_subject_name(x);

    //adding basic information about issuer and subject to certificate
//    //if ([country length] != 0)
//        [self addTextEntryToCert:&name forKey:@"C" withValue:@"IT"];
//    //if ([commonName length] != 0)
//        [self addTextEntryToCert:&name forKey:@"CN" withValue:@""];
//    //if ([city length] != 0)
//        [self addTextEntryToCert:&name forKey:@"L" withValue:@"Rome"];
//    //if ([organization length] != 0)
        [self addTextEntryToCert:&name forKey:@"O" withValue:@"Kontalk"];
//    //if ([emailAddress length] != 0)
//        [self addTextEntryToCert:&name forKey:@"emailAddress" withValue:@""];

    
	//setting issuer and subject to the same cuz of its self signed
	X509_set_issuer_name(x, name);
    
    //adding certificate extensions
    /* Add various extensions: standard extensions */
    [self addExtensionToCert:x withId:NID_basic_constraints andValue:@"critical,CA:TRUE"];
    
    [self addExtensionToCert:x withId:NID_key_usage andValue:@"digitalSignature,nonRepudiation,keyEncipherment,keyAgreement,keyCertSign"];
    
    /* Some Netscape specific extensions */
    [self addExtensionToCert:x withId:NID_netscape_cert_type andValue:@"client,email"];
    
    [self addExtensionToCert:x withId:NID_authority_key_identifier andValue:@"keyid,issuer"];
    
    [self addExtensionToCert:x withId:NID_subject_key_identifier andValue:@"hash"];
    
    int nid;
    nid = OBJ_create("2.25.49058212633447845622587297037800555803", "SubjectPGPPublicKeyInfo", "SubjectPGPPublicKeyInfo");
    
    [self addBitStringExtensionToCert:x nid:nid value:publicKey];
    
    if (!X509_sign(x, pk, EVP_sha1())) {
        [self throwWithText:@"X509 sign failed"];
    }
    
	*x509p=x;
	*pkeyp=pk;
}


/**
 * addTextEntryToCert
 * This method adds text extension to a given certificate.
 * It sets the issuer and subject values such as 'Common Name', 
 * 'Location', 'Country', 'Email Address' and so on...
 */
- (void) addTextEntryToCert:(X509_NAME**)name
                     forKey:(NSString*)key
                  withValue:(NSString*)value {
    //adding text entry to certificate
    X509_NAME_add_entry_by_txt(*name, [key cStringUsingEncoding:NSUTF8StringEncoding],
                               MBSTRING_ASC, (unsigned char*)[value cStringUsingEncoding:NSUTF8StringEncoding], 
                               -1, -1, 0);
}

/**
 * addExtensionToCert
 * This sets the cert extensions such as basic constraints, 
 * subject key identifiers and so on...
 */
- (void) addExtensionToCert:(X509*)cert
                     withId:(int)nid
                   andValue:(NSString*)value {
	X509_EXTENSION *ex;
	X509V3_CTX ctx;
	
    //setting extension context
	X509V3_set_ctx_nodb(&ctx);
	
    //issuer and subject cert is the same cuz of self signed
	X509V3_set_ctx(&ctx, cert, cert, NULL, NULL, 0);
	ex = X509V3_EXT_conf_nid(NULL, &ctx, nid, (char*)[value cStringUsingEncoding:NSUTF8StringEncoding]);
	if (!ex) {
        [self throwWithText:@"Adding extension to cert failed"];
    }
    
    //adding extension to cert
	X509_add_ext(cert, ex, -1);
	X509_EXTENSION_free(ex);
    
}

- (int)addBitStringExtensionToCert:(X509 *)cert nid:(int)nid value:(NSData *)value
{
    unsigned char* encoded;
    unsigned char* buf;
    
    ASN1_BIT_STRING* bitstr = ASN1_BIT_STRING_new();
    ASN1_BIT_STRING_set(bitstr, (unsigned char*) value.bytes, (int) value.length);
    
    int len = i2d_ASN1_BIT_STRING(bitstr, NULL);
    buf = encoded = OPENSSL_malloc(len);
    memset(buf, 0, len);
    i2d_ASN1_BIT_STRING(bitstr, &encoded);
    
    X509V3_EXT_add_alias(nid, NID_netscape_cert_type);
    
    X509_EXTENSION* ext = X509V3_EXT_i2d(nid, 0, bitstr);
    int ret = X509_add_ext(cert, ext, -1);
    X509_EXTENSION_free(ext);
    
    ASN1_BIT_STRING_free(bitstr);
    OPENSSL_free(buf);
    return ret;
}

//openssl cert creationc allback method
static void callback(int p, int n, void *arg)
{
	char c='B';
    
	if (p == 0) c='.';
	if (p == 1) c='+';
	if (p == 2) c='*';
	if (p == 3) c='\n';
	fputc(c, stderr);
}


/* throwWithText
 * This method throws a objective c exception with the 
 * corresponding OpenSSL error and a user defined message.
 */
- (void) throwWithText:(NSString*)message {
    [NSException raise:@"Crypto error occured" 
                format:@"%@. OpenSSL Errorcode: %s", message, 
     ERR_reason_error_string((unsigned long)ERR_get_error())];
}

@end
