#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface PasteHack : HackProtocolDefault

@end

@implementation PasteHack


- (NSString *)getAppName {
    return @"com.wiheads.paste";
}

- (NSString *)getSupportAppVersion {
    return @"4.1.3";
}

int (*validSubscriptionOri)(void);

- (int) hook_ubiquityIdentityToken {
    NSLog(@">>>>>> hook_ubiquityIdentityToken");
    return 0;
}

- (BOOL)hack {
    
#if defined(__arm64__) || defined(__aarch64__)
    
    [MemoryUtils hookInstanceMethod:objc_getClass("NSFileManager") originalSelector:NSSelectorFromString(@"ubiquityIdentityToken") swizzledClass:[self class] swizzledSelector:NSSelectorFromString(@"hook_ubiquityIdentityToken")];
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Paste"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    hookSubscription(searchFilePath, fileOffset);
    
#elif defined(__x86_64__)
#endif
    
    return YES;
}

void hookSubscription(NSString *searchFilePath, uintptr_t fileOffset) {
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 F5 03 01 AA F6 03 00 AA F7 1C 00 90 F7 42 2D 91"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    
    intptr_t validSubscription = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)validSubscription, (void *)ret1, (void *)&validSubscriptionOri);
}

@end
