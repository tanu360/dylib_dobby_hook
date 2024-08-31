
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import <Cocoa/Cocoa.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface PaddleBaseHack : HackProtocolDefault

@end

@implementation PaddleBaseHack

- (BOOL)shouldInject:(NSString *)target {
    
    int paddleIndex = [MemoryUtils indexForImageWithName:@"Paddle"];
    if (paddleIndex > 0) {
        return true;
    }
    return false;
}

- (NSNumber *) hook_trialDaysRemaining {
    NSLog(@">>>>>> called hook_trialDaysRemaining");
    return @9;
}

- (void) hook_viewDidLoad {
    NSLog(@">>>>>> called hook_viewDidLoad");
    [self valueForKey:@"window"];
    return ;
}
- (void) hook_windowDidLoad {
    NSLog(@">>>>>> called hook_windowDidLoad");
    NSWindow *window = [self valueForKey:@"window"];
    NSRect frame = NSMakeRect(0, 0, 0, 0);
    [window setFrame:frame display:YES];
    return ;
}

- (NSNumber *) hook_trialLength2 {
    NSLog(@">>>>>> called hook_trialLength2");
    return @9;
}


- (NSDate *) hook_activationDate{
    NSLog(@">>>>>> called hook_activationDate");
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:2099];
    [components setMonth:1]; // January
    [components setDay:1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *date = [calendar dateFromComponents:components];
    return date;
}
- (NSString *) hook_licenseCode{
    NSLog(@">>>>>> called hook_licenseCode");
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
}

- (NSString *) hook_activationEmail {
    NSLog(@">>>>>> called hook_activationEmail");
    return @"contact@paddle.com";
}

- (BOOL)hack {
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activated")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(ret1)

    ];
    
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activationDate")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_activationDate")

    ];
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"licenseCode")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_licenseCode")

    ];
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activationEmail")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_activationEmail")

    ];
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"verifyActivationDetailsWithCompletion:")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(ret)

    ];
    return YES;
}
@end
