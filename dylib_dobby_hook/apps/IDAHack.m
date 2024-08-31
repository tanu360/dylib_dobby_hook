
#import <Foundation/Foundation.h>
#import "dobby.h"
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <objc/objc-exception.h>

@interface IDAHack : HackProtocolDefault



@end


@implementation IDAHack

- (NSString *)getAppName {
    return @"com.hexrays.ida64";
}

- (NSString *)getSupportAppVersion {
    
    return @"9.";
}
- (BOOL)hack {


    DobbyHook(objc_addExceptionHandler, (void *)ret0, NULL);
    DobbyHook(objc_removeExceptionHandler, (void *)ret0, NULL);

    
    return YES;
}


@end
