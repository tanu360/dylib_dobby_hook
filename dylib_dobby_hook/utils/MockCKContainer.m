#import <Foundation/Foundation.h>
#import "MockCKContainer.h"
#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"
#import <objc/runtime.h>
#import <AppKit/AppKit.h>

@implementation MockCKContainer

+ (instancetype)defaultContainer {
    static MockCKContainer *defaultContainer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultContainer = [[self alloc] initWithIdentifier:@"default"];
    });
    return defaultContainer;
}

+ (instancetype)containerWithIdentifier:(NSString *)identifier {
    return [[self alloc] initWithIdentifier:identifier];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    NSLog(@">>>>>> initWithIdentifier identifier = %@",identifier);
    if (self) {
        _identifier = [identifier copy];
        _privateDatabase = [[MockCKDatabase alloc] initDatabase];
        _publicDatabase = [[MockCKDatabase alloc] initDatabase];
    }
    return self;
}
- (CKDatabase *)privateCloudDatabase {
    NSLog(@">>>>>> privateCloudDatabase");
    return (CKDatabase *)self.privateDatabase;
}

- (CKDatabase *)publicCloudDatabase {
    NSLog(@">>>>>> publicCloudDatabase");
    return (CKDatabase *)self.publicDatabase;
}


- (void)accountStatusWithCompletionHandler:(void (NS_SWIFT_SENDABLE ^)(CKAccountStatus accountStatus, NSError * error))completionHandler{
    NSLog(@">>>>>> accountStatusWithCompletionHandler");
    CKAccountStatus mockAccountStatus = CKAccountStatusAvailable;
    NSError *mockError = nil;
   
    if (completionHandler) {
        completionHandler(mockAccountStatus, mockError);
    }
   
}
@end

