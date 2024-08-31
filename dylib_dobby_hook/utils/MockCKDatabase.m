
#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"

@implementation MockCKDatabase

- (instancetype)initDatabase {
    if (self) {

        _records = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler {
    NSLog(@">>>>>> saveRecord record = %@",record);
    self.records[record.recordID] = record;
    if (completionHandler) {
        completionHandler(record, nil);
    }
}

- (void)fetchRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler {
    NSLog(@">>>>>> fetchRecordWithID recordID = %@",recordID);
    CKRecord *record = self.records[recordID];
    if (completionHandler) {
        completionHandler(record, nil);
    }
}

- (void)deleteRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(NSError *error))completionHandler {
    NSLog(@">>>>>> deleteRecordWithID recordID = %@",recordID);
    [self.records removeObjectForKey:recordID];
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(NSArray<CKRecord *> *records, NSError *error))completionHandler {
    NSLog(@">>>>>> performQuery query = %@,zoneID = %@",query,zoneID);
    NSPredicate *predicate = query.predicate;
    NSMutableArray<CKRecord *> *results = [NSMutableArray array];
    
    for (CKRecord *record in self.records.allValues) {
        if ([predicate evaluateWithObject:record]) {
            [results addObject:record];
        }
    }
    
    if (completionHandler) {
        completionHandler(results, nil);
    }
}

- (void)fetchAllRecordsWithCompletion:(void (^)(NSArray<CKRecord *> *records, NSError *error))completionHandler {
    NSLog(@">>>>>> fetchAllRecordsWithCompletion");

    if (completionHandler) {
        completionHandler(self.records.allValues, nil);
    }
}


- (void)addOperation:(NSOperation *)operation {
    NSString *operationClass = NSStringFromClass([operation class]);
    BOOL isAsynchronous = [operation isAsynchronous];
    BOOL isReady = [operation isReady];
    BOOL isExecuting = [operation isExecuting];
    BOOL isFinished = [operation isFinished];
    BOOL isCancelled = [operation isCancelled];
    
    NSLog(@">>>>>> addOperation operation: %@\nClass: %@\nIs Asynchronous: %@\nIs Ready: %@\nIs Executing: %@\nIs Finished: %@\nIs Cancelled: %@",
          operation,
          operationClass,
          isAsynchronous ? @"YES" : @"NO",
          isReady ? @"YES" : @"NO",
          isExecuting ? @"YES" : @"NO",
          isFinished ? @"YES" : @"NO",
          isCancelled ? @"YES" : @"NO");
   
    if (isAsynchronous && [operation isReady]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (operation.completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    operation.completionBlock();
                });
            }
        });
    }
}



- (void)fetchAllRecordZonesWithCompletionHandler:(void (^)(NSArray<CKRecordZone *> * zones, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchAllRecordZonesWithCompletionHandler");
    NSArray<CKRecordZone *> *zones = [_recordZones allValues];
    completionHandler(zones, nil);
}
- (void)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZone * zone, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchRecordZoneWithID zoneID = %@",zoneID);
    CKRecordZone *zone = _recordZones[zoneID];
    if (zone) {
        completionHandler(zone, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Record zone not found"}];
        completionHandler(nil, error);
    }
}

- (void)saveRecordZone:(CKRecordZone *)zone completionHandler:(void (^)(CKRecordZone * zone, NSError * error))completionHandler {
    NSLog(@">>>>>> saveRecordZone zone = %@",zone);
    _recordZones[zone.zoneID] = zone;
    completionHandler(zone, nil);
}

- (void)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZoneID * zoneID, NSError * error))completionHandler {
    NSLog(@">>>>>> deleteRecordZoneWithID zoneID = %@",zoneID);
    if (_recordZones[zoneID]) {
        [_recordZones removeObjectForKey:zoneID];
        completionHandler(zoneID, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Record zone not found"}];
        completionHandler(nil, error);
    }
}


- (void)fetchSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscription * subscription, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchSubscriptionWithID subscriptionID = %@",subscriptionID);
    CKSubscription *subscription = _subscriptions[subscriptionID];
    if (subscription) {
        completionHandler(subscription, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Subscription not found"}];
        completionHandler(nil, error);
    }
}

- (void)fetchAllSubscriptionsWithCompletionHandler:(void (^)(NSArray<CKSubscription *> * subscriptions, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchAllSubscriptionsWithCompletionHandler");
    completionHandler(_subscriptions.allValues, nil);
}

- (void)saveSubscription:(CKSubscription *)subscription completionHandler:(void (^)(CKSubscription * subscription, NSError * error))completionHandler {
    NSLog(@">>>>>> saveSubscription subscription = %@",subscription);
    _subscriptions[subscription.subscriptionID] = subscription;
    completionHandler(subscription, nil);
}

- (void)deleteSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscriptionID subscriptionID, NSError * error))completionHandler {
    NSLog(@">>>>>> deleteSubscriptionWithID subscriptionID = %@",subscriptionID);
    if (_subscriptions[subscriptionID]) {
        [_subscriptions removeObjectForKey:subscriptionID];
        completionHandler(subscriptionID, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Subscription not found"}];
        completionHandler(nil, error);
    }
}

#pragma mark - Persistence Methods


@end

