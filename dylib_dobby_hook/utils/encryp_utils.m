
#import <Foundation/Foundation.h>
#import "encryp_utils.h"
#import <Security/Security.h>
#import <IOKit/IOKitLib.h>
#import <stdio.h>
#import <stdlib.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <CoreWLAN/CoreWLAN.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>

@implementation EncryptionUtils

+ (NSString *)generateTablePlusDeviceId{

    CWWiFiClient *wifiClient = [CWWiFiClient sharedWiFiClient];
    CWInterface *wifiInterface = [wifiClient interface];
    NSString *hardwareAddress = [wifiInterface hardwareAddress];

    NSString *serialNumber = nil;
    
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 120000) // Before macOS 12 Monterey
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMainPortDefault,
                                                              IOServiceMatching("IOPlatformExpertDevice"));
#else
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                              IOServiceMatching("IOPlatformExpertDevice"));
#endif



    if (platformExpert) {
        CFTypeRef serialNumberAsCFString =
                IORegistryEntryCreateCFProperty(platformExpert,
                                                CFSTR(kIOPlatformSerialNumberKey),
                                                kCFAllocatorDefault, 0);
        if (serialNumberAsCFString) {
            serialNumber = CFBridgingRelease(serialNumberAsCFString);
        }
        IOObjectRelease(platformExpert);
    }else{
        return nil;
    }
    return [self calculateMD5:[hardwareAddress stringByAppendingString:serialNumber]];
}

+ (NSString *)generateSurgeDeviceId{
    
    NSMutableArray *rbx = [NSMutableArray array];
    io_service_t masterPort;
    io_service_t platformExpert;
    CFTypeRef uuidRef;
    masterPort = IO_OBJECT_NULL;
    platformExpert = IOServiceGetMatchingService(masterPort, IOServiceMatching("IOPlatformExpertDevice"));
    uuidRef = IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    NSString *uuidString = (__bridge NSString *)uuidRef;
    CFRelease(uuidRef);
    IOObjectRelease(platformExpert);
    [rbx addObject:uuidString];
    NSLog(@"IOPlatformUUID : %@",uuidString);
    char model[256];
    size_t size = sizeof(model);
    if (sysctlbyname("hw.model", model, &size, NULL, 0) == 0) {
        NSString *hwModel = [NSString stringWithUTF8String:model];
        [rbx addObject:hwModel];
        NSLog(@"hw.model : %@",hwModel);
    }
    size = sizeof(model); // 重新设置size
    if (sysctlbyname("machdep.cpu.brand_string", model, &size, NULL, 0) == 0) {
        NSString *cpu = [NSString stringWithUTF8String:model];
        [rbx addObject:cpu];
        NSLog(@"machdep.cpu.brand_string : %@",cpu);
    }
    int64_t signature = 0;
    size_t signatureSize = sizeof(signature);
    if (sysctlbyname("machdep.cpu.signature",  &signature, &signatureSize, NULL, 0) == 0) {
        
        NSNumber *numberSignature = [NSNumber numberWithLongLong:signature];
        [rbx addObject:numberSignature];
        NSLog(@"machdep.cpu.signature: %@", numberSignature);
    }else{
        [rbx addObject:@0];
    }
    int64_t memsize;
    size_t size_memsize = sizeof(memsize);
    if (sysctlbyname("hw.memsize", &memsize, &size_memsize, NULL, 0) == 0) {
        NSNumber *numberMemsize = [NSNumber numberWithLongLong:memsize];
        [rbx addObject:numberMemsize];
        NSLog(@"hw.memsize: %@", numberMemsize);
    }else {
        [rbx addObject:@"#"];
        NSLog(@"hw.memsize: %s", "#");
    }
    bool ActivationCompatibilityMode = false;
    
    CWWiFiClient *wifiClient = [CWWiFiClient sharedWiFiClient];
    CWInterface *wifiInterface = [wifiClient interface];
    NSString *hardwareAddress = [wifiInterface hardwareAddress];
    NSLog(@"Hardware Address: %@", hardwareAddress);
    [rbx addObject:hardwareAddress];
    
    if (!ActivationCompatibilityMode) {
    }
    
    NSString *joinedString = [rbx componentsJoinedByString:@"/"];
    NSLog(@"joinedString %@", joinedString);
    NSString *deviceIdMD5 = [self calculateMD5:joinedString];
    NSLog(@"deviceIdMD5 %@", deviceIdMD5);
    return deviceIdMD5;
};

+ (NSString *)calculateMD5:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}


+ (NSDictionary *)generateKeyPair:(bool)is_pkcs8 {
    NSDictionary *parameters = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeySizeInBits: @2048
    };
    SecKeyRef publicKey, privateKey;
    CFErrorRef error = NULL;
    privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)parameters, &error);
    if (error != NULL) {       
        NSLog(@"密钥生成失败: %@", error);
        return nil;
    }
    
    publicKey = SecKeyCopyPublicKey(privateKey);
    NSData *publicKeyData = CFBridgingRelease(SecKeyCopyExternalRepresentation(publicKey, nil));
    NSData *privateKeyData = CFBridgingRelease(SecKeyCopyExternalRepresentation(privateKey, nil));
    
    if (is_pkcs8) {
        publicKeyData = [self addPublicKeyHeader:publicKeyData];
        privateKeyData = [self addPrivateKeyHeader:privateKeyData];
    }
    
    
    
    NSString *publicKeyString = [self convertToPEMFormat:publicKeyData withKeyType:@"PUBLIC"];
    NSString *privateKeyString = [self convertToPEMFormat:privateKeyData withKeyType:@"PRIVATE"];
    return @{
        @"publicKey": publicKeyString,
        @"privateKey": privateKeyString
    };
}


+ (NSData *)generateSignatureForData:(NSData *)data privateKey:(NSString *)privateKeyString isPKCS8:(bool)is_pkcs8 {
    NSArray *components = [privateKeyString componentsSeparatedByString:@"\n"];
    NSMutableArray *cleanedComponents = [NSMutableArray arrayWithArray:components];
    [cleanedComponents removeObject:@""];
    [cleanedComponents removeObject:@"-----BEGIN RSA PRIVATE KEY-----"];
    [cleanedComponents removeObject:@"-----END RSA PRIVATE KEY-----"];
    [cleanedComponents removeObject:@"-----BEGIN PRIVATE KEY-----"];
    [cleanedComponents removeObject:@"-----END PRIVATE KEY-----"];
    NSString *cleanedString = [cleanedComponents componentsJoinedByString:@""];
    NSData *privateKeyData = [[NSData alloc] initWithBase64EncodedString:cleanedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (is_pkcs8) {
        privateKeyData = [self removePrivateKeyHeader:privateKeyData];
    }
    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
    };
    
    SecKeyRef privateKey = NULL;
    CFErrorRef error = NULL;
    privateKey = SecKeyCreateWithData((__bridge CFDataRef)privateKeyData, (__bridge CFDictionaryRef)attributes, &error);
    SecKeyAlgorithm algorithm = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
    CFDataRef signedDataRef = SecKeyCreateSignature(privateKey, algorithm, (__bridge CFDataRef)data, &error);
    
    NSData *signedData = (__bridge NSData *)signedDataRef;
    
    if (error != NULL) {
        NSLog(@"Signature generation failed: %@", (__bridge NSError *)error);
        if (signedDataRef != NULL) {
            CFRelease(signedDataRef);
        }
        return nil;
    }
    
    return signedData;
}


+ (BOOL)verifySignatureWithBase64:(NSString *)policy signature:(NSString *)sign publicKey:(NSString *)publicKeyString isPKCS8:(bool)is_pkcs8{
    
    NSData *policyData = [[NSData alloc] initWithBase64EncodedString:policy options:0];
    NSData *signData = [[NSData alloc] initWithBase64EncodedString:sign options:0];
    return [self verifySignatureWithByte:policyData signature:signData publicKey:publicKeyString isPKCS8:(bool)is_pkcs8];
    
    
}

+ (BOOL)verifySignatureWithByte:(NSData *)policyData signature:(NSData *)signData publicKey:(NSString *)publicKeyString isPKCS8:(bool)is_pkcs8{
    NSArray *components = [publicKeyString componentsSeparatedByString:@"\n"];
    NSMutableArray *cleanedComponents = [NSMutableArray arrayWithArray:components];
    [cleanedComponents removeObject:@""];
    [cleanedComponents removeObject:@"-----BEGIN PUBLIC KEY-----"];
    [cleanedComponents removeObject:@"-----END PUBLIC KEY-----"];
    NSString *cleanedString = [cleanedComponents componentsJoinedByString:@""];
    NSData *publicKeyData = [[NSData alloc] initWithBase64EncodedString:cleanedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (is_pkcs8) {
        publicKeyData = [self removePublicKeyHeader:publicKeyData];
    }
    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
    };
    
    SecKeyRef publicKey = NULL;
    CFErrorRef error1 = NULL;
    publicKey = SecKeyCreateWithData((__bridge CFDataRef)publicKeyData, (__bridge CFDictionaryRef)attributes, &error1);
    
    SecKeyAlgorithm algorithm = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
    BOOL verificationResult = SecKeyVerifySignature(publicKey, algorithm, (__bridge CFDataRef)policyData, (__bridge CFDataRef)signData, NULL);
    
    return verificationResult;
}
+ (NSString *)convertToPEMFormat:(NSData *)keyData withKeyType:(NSString *)keyType {
    NSString *header = [NSString stringWithFormat:@"-----BEGIN %@ KEY-----\n", keyType];
    NSString *footer = [NSString stringWithFormat:@"-----END %@ KEY-----", keyType];
    
    NSString *base64Key = [keyData base64EncodedStringWithOptions:0];
    NSMutableString *pemKey = [NSMutableString stringWithString:header];
    NSInteger length = [base64Key length];
    for (NSInteger i = 0; i < length; i += 64) {
        NSInteger remainingLength = length - i;
        NSInteger lineLength = remainingLength > 64 ? 64 : remainingLength;
        NSString *line = [base64Key substringWithRange:NSMakeRange(i, lineLength)];
        [pemKey appendString:line];
        [pemKey appendString:@"\n"];
    }
    
    [pemKey appendString:footer];
    
    return pemKey;
}

+ (NSData *)addPublicKeyHeader:(NSData *)d_key {
    unsigned char pkcs8_header[] = {
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    };
    
    NSMutableData *result = [NSMutableData dataWithBytes:pkcs8_header length:sizeof(pkcs8_header)];
    [result appendData:d_key];
    
    return result;
}

+ (NSData *)addPrivateKeyHeader:(NSData *)d_key {
    unsigned char pkcs8_header[] = {
        0x30, 0x82, 0x01, 0x2f, 0x02, 0x01, 0x00, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7,
        0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x04, 0x82, 0x01, 0x1b
    };
    
    NSMutableData *result = [NSMutableData dataWithBytes:pkcs8_header length:sizeof(pkcs8_header)];
    [result appendData:d_key];
    
    return result;
}
    

+ (NSData *)removePublicKeyHeader:(NSData *)d_key {
    NSUInteger headerLength = 24;
    
    if (d_key.length <= headerLength) {
        return nil; // Invalid key data
    }
    
    return [d_key subdataWithRange:NSMakeRange(headerLength, d_key.length - headerLength)];
}

+ (NSData *)removePrivateKeyHeader:(NSData *)d_key {
    NSUInteger headerLength = 26;
    
    if (d_key.length <= headerLength) {
        return nil; // Invalid key data
    }
    
    return [d_key subdataWithRange:NSMakeRange(headerLength, d_key.length - headerLength)];
}


+ (NSData *)cccEncryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv {
    NSMutableData *encryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    size_t encryptedDataLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          data.bytes,
                                          data.length,
                                          encryptedData.mutableBytes,
                                          encryptedData.length,
                                          &encryptedDataLength);
    
    if (cryptStatus == kCCSuccess) {
        encryptedData.length = encryptedDataLength;
        return encryptedData;
    }
    
    return nil;
}

+ (NSData *)cccDecryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv {
    NSMutableData *decryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    size_t decryptedDataLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          data.bytes,
                                          data.length,
                                          decryptedData.mutableBytes,
                                          decryptedData.length,
                                          &decryptedDataLength);
    
    if (cryptStatus == kCCSuccess) {
        decryptedData.length = decryptedDataLength;
        return decryptedData;
    }
    
    return nil;
}



+ (NSString *)calculateSHA1OfFile:(NSString *)filePath {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!fileHandle) {
        return nil;
    }
    CC_SHA1_CTX sha1Context;
    CC_SHA1_Init(&sha1Context);
    static const size_t bufferSize = 4096;
    NSData *fileData;
    while ((fileData = [fileHandle readDataOfLength:bufferSize])) {
        CC_SHA1_Update(&sha1Context, [fileData bytes], (CC_LONG)[fileData length]);
        if ([fileData length] == 0) {
            break;
        }
    }
    [fileHandle closeFile];
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(hash, &sha1Context);
    NSMutableString *hashString = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x", hash[i]];
    }

    return hashString;
}
@end
