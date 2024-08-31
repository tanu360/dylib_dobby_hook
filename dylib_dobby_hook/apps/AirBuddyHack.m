
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#include "common_ret.h"
#include <sys/ptrace.h>
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import <Cocoa/Cocoa.h>
#import "HackProtocolDefault.h"

@interface AirBuddyHack : HackProtocolDefault

@end
@implementation AirBuddyHack



- (NSString *)getAppName {
    return @"codes.rambo.AirBuddy";
}

- (NSString *)getSupportAppVersion {
    return @"2.";
}


void (*sub_10005ad20_ori)(void);
void hook_sub_10005ad20(void){
    NSLog(@">>>>>> hook_sub_10005bf30 is called");
    
#if defined(__arm64__) || defined(__aarch64__)
    __asm__ __volatile__(
        "strb wzr, [x20, #0x99]"
    );
#elif defined(__x86_64__)
    __asm__ (
         "movb $0, 0x99(%r13)"
    );
#endif
    return sub_10005ad20_ori();
}

- (BOOL)hack {
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/AirBuddy"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    

#if defined(__arm64__) || defined(__aarch64__)
    NSString *sub_10005ad20_hex = @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 95 DA 48 A9 97 62 42 39 88 66 42 39 1F 05 00 71";
    NSArray *ptrace_offsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:@"01 10 00 D4"
                                   count:(int)1
    ];
    intptr_t ptraceptr = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[ptrace_offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    uint8_t nop4[4] = {0x1F, 0x20,0x03, 0xD5};
    DobbyCodePatch((void *)ptraceptr, nop4, 4);
    
#elif defined(__x86_64__)
    NSString *sub_10005ad20_hex = @"55 48 89 E5 41 57 41 56 41 54 53 48 83 EC 10 4D 8B A5 .. .. .. ..";
#endif
    
    
    NSArray *sub_10005ad20_offsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:sub_10005ad20_hex
                                   count:(int)1
    ];
    intptr_t sub_10005ad20 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[sub_10005ad20_offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    
    DobbyHook((void *)sub_10005ad20, (void *)hook_sub_10005ad20, (void *)&sub_10005ad20_ori);
    NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
    [defaults setBool:true forKey:@"AMSkipOnboarding"];
    [defaults synchronize];

    return YES;
}


@end
