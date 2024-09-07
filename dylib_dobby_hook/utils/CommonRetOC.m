#import <Foundation/Foundation.h>
#import "CommonRetOC.h"
#import <CloudKit/CloudKit.h>
#import "MockCKContainer.h"

@implementation CommonRetOC

- (void)ret {
    NSLog(@">>>>>> called - ret");
}
- (void)ret_ {
    NSLog(@">>>>>> called - ret_");
}
- (void)ret__ {
    NSLog(@">>>>>> called - ret__");
}

- (int)ret1 {
    NSLog(@">>>>>> called - ret1");
    return 1;
}
- (int)ret0 {
    NSLog(@">>>>>> called - ret0");
    return 0;
}
+ (int)ret1 {
    NSLog(@">>>>>> called + ret1");
    return 1;
}
+ (int)ret0 {
    NSLog(@">>>>>> called + ret0");
    return 0;
}
+ (void)ret {
    NSLog(@">>>>>> called + ret");
}


- (NSString *)getAppName { 
    return @"";
}

- (NSString *)getSupportAppVersion { 
    return @"";
}



- (BOOL)shouldInject:(NSString *)target {
    NSString *appName = [self getAppName];
    return [target hasPrefix:appName];
}



- (BOOL)hack { 
    return NO;
}





+ (id)hook_defaultStore{
    NSLog(@">>>>>> hook_defaultStore");
    return [NSUserDefaults standardUserDefaults];
}

- (id)hook_NSFileManager:(nullable NSString *)containerIdentifier{
    NSLog(@">>>>>> hook_NSFileManager containerIdentifier = %@",containerIdentifier);
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *url = [[defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    url = [url URLByAppendingPathComponent:containerIdentifier];
    
    BOOL isDirectory;
    if (![defaultManager fileExistsAtPath:[url path] isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        BOOL success = [defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLog(@">>>>>> Failed to create directory: %@", error.localizedDescription);
        }
    } else {
        NSLog(@">>>>>> Directory already exists.");
    }
    return url;
}


+ (id)hook_containerWithIdentifier:identifier {
    NSLog(@">>>>>> hook_containerWithIdentifier identifier = %@",identifier);
    return [MockCKContainer containerWithIdentifier:identifier];

}
+ (id)hook_defaultContainer {
    NSLog(@">>>>>> hook_defaultContainer");
    return [MockCKContainer defaultContainer];

}

@end
