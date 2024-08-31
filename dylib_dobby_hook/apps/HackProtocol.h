
@protocol HackProtocol

- (NSString *)getAppName;
- (NSString *)getSupportAppVersion;

- (BOOL)shouldInject:(NSString *)target;

- (BOOL)hack;
@end

