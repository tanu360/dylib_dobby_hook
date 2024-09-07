#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "EncryptionUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"
#import "URLSessionHook.h"

@interface DummyURLSessionDataTask : NSObject
@end

@implementation DummyURLSessionDataTask

- (void)resume {
    NSLog(@">>>>>> DummyURLSessionDataTask.resume");
}

@end


@interface TablePlusHack : HackProtocolDefault

@end

@implementation TablePlusHack

static IMP urlWithStringSeletorIMP;
static IMP NSURLSessionClassIMP;
static IMP dataTaskWithRequestIMP;
static IMP decryptDataIMP;


- (NSString *)getAppName {
    return @"com.tinyapp.TablePlus";
}

- (NSString *)getSupportAppVersion {
    return @"6.";
}



- (BOOL)hack {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *appDirectory = [applicationSupportDirectory stringByAppendingPathComponent:bundleIdentifier];
    NSString *licensePath = [appDirectory stringByAppendingPathComponent:@".licensemac"];
    
    NSLog(@">>>>>> License file path: %@", licensePath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:licensePath];
    
    if (!fileExists) {
        NSString *licenseContent = @"?";
        BOOL success = [licenseContent writeToFile:licensePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@">>>>>> License file: %hhd",success);
    }
    decryptDataIMP = [MemoryUtils hookClassMethod:
                          NSClassFromString(@"RNDecryptor")
                originalSelector:NSSelectorFromString(@"decryptData:withPassword:error:")
                   swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hk_decryptData:withPassword:error:")
    ];
    
    
    
    dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"AFHTTPSessionManager")
                   originalSelector:NSSelectorFromString(@"dataTaskWithHTTPMethod:URLString:parameters:headers:uploadProgress:downloadProgress:success:failure:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_dataTaskWithHTTPMethod:URLString:parameters:headers:uploadProgress:downloadProgress:success:failure:")
    ];
    [MemoryUtils replaceInstanceMethod:NSClassFromString(@"SPUUpdater")
                      originalSelector:NSSelectorFromString(@"startUpdater:")
                         swizzledClass:[self class]
                      swizzledSelector:@selector(ret1)
    ];
    
    return YES;
}

- (id)hk_dataTaskWithHTTPMethod:(NSString *)method
                                               URLString:(NSString *)URLString
                                              parameters:(id)parameters
                                                 headers:(NSDictionary<NSString *,NSString *> *)headers
                                          uploadProgress:(void (^)(NSProgress *uploadProgress))uploadProgress
                                        downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgress
                                                 success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                                 failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
        if ([URLString containsString:@"tableplus.com"]) {
        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];
        if ([URLString containsString:@"v1/licenses/devices"]){
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            [result setObject:[EncryptionUtils generateTablePlusDeviceId] forKey:@"DeviceID"];
            [result setObject:@"2025-07-16" forKey:@"UpdatesAvailableUntilString"];
            success(nil, @{
                @"Data":result,
            });
        }else if ([URLString containsString:@"apps/osx/tableplus"]){
            success(nil, @{
                @"Data":@{
                    @"DayBeforeExpiration":@521
                },
            });
        }
        NSLog(@">>>>>> [hk_dataTaskWithHTTPMethod] Intercept url: %@, req params: %@",URLString,parameters);
        return dummyTask;
    }
    NSLog(@">>>>>> [hk_dataTaskWithHTTPMethod] Allow to pass url: %@",URLString);
    return ((id(*)(id, SEL,NSString *,NSString *,id,id,id,id,id,id))dataTaskWithRequestIMP)(self, _cmd,method,URLString,parameters,headers,uploadProgress,downloadProgress,success,failure);
}




+ (id) hk_decryptData:arg1 withPassword:(NSString *)withPassword error:(int)error{
    
    if ([arg1 isKindOfClass:NSClassFromString(@"_NSInlineData")]) {
        NSDictionary *propertyDictionary = @{
            @"sign": @"12345678901234567890123456789012345678901234567890",
            @"email": [Constant G_EMAIL_ADDRESS],
            @"deviceID":[EncryptionUtils generateTablePlusDeviceId],
            @"licenseKey": @"licenseKey",
            @"purchasedAt": @"2025-06-16",
            @"nextChargeAt": @"2025-06-16",
            @"updatesAvailableUntil": @"2025-06-16"
        };
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:propertyDictionary options:0 error:nil];
        return jsonData;
    }
    
    return ((id(*)(id, SEL,id,NSString*,int))decryptDataIMP)(self, _cmd,arg1,withPassword,error);
}

+ (id)hk_URLWithString:arg1{
    
    if ([arg1 hasPrefix:@"https://"] && [arg1 containsString:@"tableplus"]) {
        NSLog(@">>>>>> hk_URLWithString Intercept requests %@",arg1);
        arg1 =  @"https://127.0.0.1";
    }
    id ret = ((id(*)(id, SEL,id))urlWithStringSeletorIMP)(self, _cmd,arg1);
    return ret;
}
@end
