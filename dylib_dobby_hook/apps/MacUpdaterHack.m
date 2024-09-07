#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "EncryptionUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import "common_ret.h"

@interface MacUpdaterHack : HackProtocolDefault



@end


@implementation MacUpdaterHack

static IMP defaultStringIMP;
static IMP defaultIntIMP;
static IMP URLSessionIMP2;
static IMP dataTaskWithRequest;
static IMP URLWithHostIMP;
static IMP directoryContentsIMP;
static IMP URLSessionIMP;
static IMP fileChecksumSHAIMP;
static IMP checksumSparkleFrameworkIMP;
static IMP downloadURLWithSecurePOSTIMP;
static Class stringClass;
static NSString* licenseCode = @"123456789";

- (NSString *)getAppName {
    return @"com.corecode.MacUpdater";
}

- (NSString *)getSupportAppVersion {
    return @"3.3";
}



-(NSString *) hk_defaultString{
    id ret = ((NSString *(*)(id,SEL))defaultStringIMP)(self,_cmd);
    if ([self isEqualTo:@"SavedV3PurchaseEmail"]) {
        ret = [[Constant G_EMAIL_ADDRESS_FMT] performSelector:NSSelectorFromString(@"rot13")];
    } else if ([self isEqualTo:@"SavedV3PurchaseLicense"]) {
        ret = [licenseCode performSelector:NSSelectorFromString(@"rot13")];
    }else if ([self isEqualTo:@"SavedPurchaseLicense"]) {
    }else if ([self isEqualTo:@"NSNavLastRootBacktraceDiag"]) {
    }
    NSLog(@">>>>>> hk_defaultString %@:%@",self,ret);
    return ret;
}


-(int) hk_defaultInt{
    int ret = ((int(*)(id,SEL))defaultIntIMP)(self,_cmd);
    if ([self isEqualTo:@"SavedV3PurchaseActivation"]) {
        ret = 2;
    }else if ([self isEqualTo:@"Usages3"]) {
        ret = 5;
    }
    NSLog(@">>>>>> hk_defaultInt %@:%d",self,ret);
    return ret;
}

-(void) hk_refreshAuthentication{
    SEL selector = NSSelectorFromString(@"setStatus:email:license:");
    if ([self respondsToSelector:selector]) {
        NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
        if (methodSignature) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            [invocation setTarget:self];
            [invocation setSelector:selector];
            NSInteger *param1 = 0xc9;
            NSString *param2 = [Constant G_EMAIL_ADDRESS_FMT];
            NSString *param3 = licenseCode;
            [invocation setArgument:&param1 atIndex:2];
            [invocation setArgument:&param2 atIndex:3];
            [invocation setArgument:&param3 atIndex:4];
            [invocation invoke];
        }
    }
}

- (NSMutableArray *) hk_directoryContents{
    NSString* dylib_name = [Constant G_DYLIB_NAME];
    NSMutableArray* ret = ((NSMutableArray*(*)(id,SEL))directoryContentsIMP)(self,_cmd);
    if ([ret containsObject:dylib_name]) {
        [ret removeObject:dylib_name];
    }
    return ret;
}


+(id)hook_URLWithHost:(id)arg2 path:(id)arg3 query:(id)arg4 user:(id)arg5 password:(id)arg6 fragment:(id)arg7 scheme:(id)arg8 port:(id)arg9 {
    if ([arg2 isEqualToString:@"macupdater-backend.com"]) {
        if(([arg3 containsString:@".cgi"] && arg4!=nil )){
            arg4 = [arg4 stringByReplacingOccurrencesOfString:@"a=2" withString:@"a=0"];
        }
        if(arg4!=nil){
            arg4 = [arg4 stringByReplacingOccurrencesOfString:[@"=" stringByAppendingString:[Constant G_EMAIL_ADDRESS_FMT]] withString:@"=(null)"];
            arg4 = [arg4 stringByReplacingOccurrencesOfString:[@"=" stringByAppendingString:licenseCode] withString:@"=(null)"];
        }
    }
    NSLog(@">>>>>> hook_URLWithHost %@,%@,%@,%@,%@,%@",arg2,arg3,arg4,arg5,arg6,arg7);
    id ret = ((id(*)(id,SEL,id,id,id,id,id,id,id,id))URLWithHostIMP)(self,_cmd,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9);
    return ret;
}


+ (NSString *) hk_checksumSparkleFramework{
    NSLog(@">>>>>> hk_checksumSparkleFramework");
    static NSString *cachedChecksum = nil;
    if (!cachedChecksum){
        NSString *Sparkle = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle_Backup"];
        cachedChecksum = [[EncryptionUtils calculateSHA1OfFile:Sparkle] copy];
        NSLog(@">>>>>> hk_checksumSparkleFramework cachedChecksum = %@", cachedChecksum);
    }
    return  cachedChecksum;
}

+ (NSString *) hk_uniqueIdentifierForDB{
    NSLog(@">>>>>> hk_uniqueIdentifierForDB");
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:40];
    for (int i = 0; i < 40; i++) {
        uint32_t randomIndex = arc4random_uniform((uint32_t)[letters length]);
        [randomString appendFormat:@"%C", [letters characterAtIndex:randomIndex]];
    }
    return  randomString;
}


-(void)hk_URLSession:(NSURLSession *)arg2 didReceiveChallenge:(NSURLAuthenticationChallenge*)arg3 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))arg4 {
    if(arg4){

        arg4(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:arg3.protectionSpace.serverTrust]);
    }
}


- (id)hook_downloadURLWithSecurePOST:(NSURL *)url timeout:(NSTimeInterval)timeout{

    NSString* path = [url path];
    if ([path isEqualToString:@"/configfile.cgi"]) {
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSString * cacheConfigFile = [cacheDir stringByAppendingPathComponent:@"com.corecode.MacUpdater/cache_configfile.cgi"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL fileExists = [fileManager fileExistsAtPath:cacheConfigFile];
        if (fileExists) {
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:cacheConfigFile error:nil];
            NSDate *modificationDate = [attributes fileModificationDate];
            if (modificationDate) {
                NSDate *currentDate = [NSDate date];
                NSDate* fakaData = [NSData dataWithContentsOfFile:cacheConfigFile];
                NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:modificationDate];
                NSTimeInterval oneMonthInterval = 30 * 24 * 60 * 60;
                if (timeInterval < oneMonthInterval) {
                    return fakaData;
                }
            }
        }
        NSData* ret = ((NSData*(*)(id,SEL,NSURL*,NSTimeInterval))downloadURLWithSecurePOSTIMP)(self,_cmd,url,timeout);
        if (ret.length > 409600) {
            BOOL success = [ret writeToFile:cacheConfigFile options:NSDataWritingAtomic error:nil];
            NSLog(@">>>>>> [cache_configfile.cgi] saved %hhd",success);
        } else {
            NSLog(@">>>>>> [configfile.cgi] api returns data exception, possibly banned IP !!");
        }
        return ret;
    }
    id ret = ((id(*)(id,SEL,NSURL*,NSTimeInterval))downloadURLWithSecurePOSTIMP)(self,_cmd,url,timeout);
    return ret;
}

- (BOOL)hack {
    defaultStringIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"__NSCFString")
                   originalSelector:NSSelectorFromString(@"defaultString")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_defaultString)
    ];
    defaultIntIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"__NSCFString")
                   originalSelector:NSSelectorFromString(@"defaultInt")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_defaultInt)
    ];
    [MemoryUtils hookInstanceMethod:NSClassFromString(@"Meddle")
                   originalSelector:NSSelectorFromString(@"refreshAuthentication")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_refreshAuthentication)
    ];

    [MemoryUtils replaceClassMethod:NSClassFromString(@"LicenseHelper")
                   originalSelector:NSSelectorFromString(@"licenseIsPro:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];

    [MemoryUtils replaceClassMethod:objc_getClass("Meddle")
                originalSelector:NSSelectorFromString(@"_isValidEmailAddress:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];
    [MemoryUtils replaceClassMethod:objc_getClass("CGIInfoHelper")
                originalSelector:NSSelectorFromString(@"checkExpiry:eventType:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret)
    ];
    directoryContentsIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"NSString")
                   originalSelector:NSSelectorFromString(@"directoryContents")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_directoryContents)
    ];
    checksumSparkleFrameworkIMP = [MemoryUtils hookClassMethod:NSClassFromString(@"AppDelegate")
                   originalSelector:NSSelectorFromString(@"checksumSparkleFramework")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_checksumSparkleFramework)
    ];
    URLWithHostIMP = [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSURL")
                   originalSelector:NSSelectorFromString(@"URLWithHost:path:query:user:password:fragment:scheme:port:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_URLWithHost:path:query:user:password:fragment:scheme:port:")
    ];
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"AppDelegate")
                   originalSelector:NSSelectorFromString(@"uniqueIdentifierForDB")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_uniqueIdentifierForDB")
    ];
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"HTTPSecurePOST")
                   originalSelector:NSSelectorFromString(@"URLSession:didReceiveChallenge:completionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_URLSession:didReceiveChallenge:completionHandler:")
    ];
    downloadURLWithSecurePOSTIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"HTTPSecurePOST")
                   originalSelector:NSSelectorFromString(@"downloadURLWithSecurePOST:timeout:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_downloadURLWithSecurePOST:timeout:")
    ];
    return YES;
}

@end