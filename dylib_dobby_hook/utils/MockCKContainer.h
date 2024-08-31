#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"

#ifndef MockCKContainer_h
#define MockCKContainer_h

@interface MockCKContainer : CKContainer

@property(nonatomic, strong) NSDictionary *options;
@property(nonatomic, readonly) MockCKDatabase *privateDatabase;
@property(nonatomic, readonly) MockCKDatabase *publicDatabase;
@property(nonatomic, strong) NSString *identifier;

+ (instancetype)defaultContainer;
+ (instancetype)containerWithIdentifier:(NSString *)identifier;

- (CKDatabase *)privateCloudDatabase;
- (CKDatabase *)publicCloudDatabase;

- (void)accountStatusWithCompletionHandler:(void(NS_SWIFT_SENDABLE ^)(CKAccountStatus accountStatus, NSError *error))completionHandler;

@end

#endif /* MockCKContainer_h */
