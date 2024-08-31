
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface NavicatPremiumHack : HackProtocolDefault

@end
@implementation NavicatPremiumHack


static IMP displayRegisteredInfoIMP;


- (NSString *)getAppName {
    return @"com.navicat.NavicatPremium";
}

- (NSString *)getSupportAppVersion {
    return @"17.";
}


- (BOOL)hack {
    
    
#if defined(__arm64__) || defined(__aarch64__)
#elif defined(__x86_64__)
#endif
    
    [MemoryUtils hookInstanceMethod:
                objc_getClass("IAPHelper")
                originalSelector:NSSelectorFromString(@"isProductSubscriptionStillValid")
                swizzledClass:[self class]
                swizzledSelector: @selector(ret1)
    ];
    
    [MemoryUtils hookClassMethod:
                objc_getClass("AppStoreReceiptValidation")
                originalSelector:NSSelectorFromString(@"validate")
                swizzledClass:[self class]
                swizzledSelector:@selector(ret)
    ];


    displayRegisteredInfoIMP = [MemoryUtils hookInstanceMethod:
                                    NSClassFromString(@"AboutNavicatWindowController")
                   originalSelector:NSSelectorFromString(@"displayRegisteredInfo")
                      swizzledClass:[self class]
                   swizzledSelector: @selector(hk_displayRegisteredInfo)
    ];
    
    
    return YES;
}
- (void)hk_displayRegisteredInfo {

    ((void(*)(id, SEL))displayRegisteredInfoIMP)(self, _cmd);
    Ivar InfoLabel = class_getInstanceVariable([self class], "_appExtraInfoLabel");
    if (InfoLabel != NULL) {
        ptrdiff_t offset = ivar_getOffset(InfoLabel);
        uintptr_t address = (uintptr_t)(__bridge void *)self + offset;
        id  __autoreleasing *deviceIdPtr = (id  __autoreleasing *)(void *)address;
        id _appExtraInfoLabel = *deviceIdPtr;
         [_appExtraInfoLabel setStringValue:[Constant G_EMAIL_ADDRESS]];

    }
}
@end
