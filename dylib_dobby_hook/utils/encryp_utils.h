
#ifndef encryp_utils_h
#define encryp_utils_h

@interface EncryptionUtils : NSObject

+ (NSString *)generateTablePlusDeviceId;

+ (NSString *)generateSurgeDeviceId;
+ (NSString *)calculateMD5:(NSString *) input;

+ (NSDictionary *)generateKeyPair:(bool)is_pkcs8;
+ (NSData *)generateSignatureForData:(NSData *)data privateKey:(NSString *)privateKeyString isPKCS8:(bool)is_pkcs8;

+ (BOOL)verifySignatureWithBase64:(NSString *)policy signature:(NSString *)sign publicKey:(NSString *)publicKeyString isPKCS8:(bool)is_pkcs8;
+ (BOOL)verifySignatureWithByte:(NSData *)policyData signature:(NSData *)signData publicKey:(NSString *)publicKeyString isPKCS8:(bool)is_pkcs8;

+ (NSString *)convertToPEMFormat:(NSData *)keyData withKeyType:(NSString *)keyType;


+ (NSData *)cccEncryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv;
+ (NSData *)cccDecryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv;
+ (NSString*) calculateSHA1OfFile:(NSString *)filePath;
@end
#endif /* encryp_utils_h */
