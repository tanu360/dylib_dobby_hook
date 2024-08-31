
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface InfuseHack : NSObject <HackProtocol>



@end


@implementation InfuseHack


- (NSString *)getAppName {
    return @"com.firecore.infuse";
}

- (NSString *)getSupportAppVersion {
    return @"7.7";
}

- (BOOL)hack {
   
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);

    [MemoryUtils hookInstanceMethod:
                objc_getClass("FCInAppPurchaseServiceFreemium")
                originalSelector:NSSelectorFromString(@"iapVersionStatus")
                swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];

    return YES;
}

@end
