
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"

@interface DevUtilsHack : HackProtocolDefault

@end

@implementation DevUtilsHack


- (NSString *)getAppName {
    return @"tonyapp.devutils";
}

- (NSString *)getSupportAppVersion {
    return @"1.";
}



- (void)hk_showUnregistered{
    NSLog(@">>>>>> Swizzled showUnregistered method called");
}




- (BOOL)hack {
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/DevUtils"];
    
    
    [MemoryUtils hookInstanceMethod:
         objc_getClass("_TtC8DevUtils16WindowController")
           originalSelector:NSSelectorFromString(@"showUnregistered")
              swizzledClass:[self class]
           swizzledSelector:NSSelectorFromString(@"hk_showUnregistered")
    ];
    
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];

    
    
#if defined(__arm64__) || defined(__aarch64__)
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"AA E3 40 39"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    intptr_t freeTrialPtr = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];


    NSLog(@">>>>>> Before %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:4].UTF8String); // AA E3 40 39; ldrb       w10, [fp, arg_28]
    uint8_t freeTrialHex[4] = {0x2A,0x00,0x80,0x52};
    DobbyCodePatch((void*)freeTrialPtr,(uint8_t *)freeTrialHex,4);
    NSLog(@">>>>>> After %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:4].UTF8String); // 2A 00 80 52; mov w10, #1


    
    
#elif defined(__x86_64__)
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"24 01 41 88 44 0d 00"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    intptr_t freeTrialPtr = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];


    NSLog(@">>>>>> Before %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:2].UTF8String); // 24 01 and        al, 0x1
    uint8_t freeTrialHex[2] = {0xB0,0x1};
    DobbyCodePatch((void*)freeTrialPtr,(uint8_t *)freeTrialHex,2);
    NSLog(@">>>>>> After %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:2].UTF8String); // B0 01 mov        al, 0x1

    
#endif
    
    return YES;
}
@end
