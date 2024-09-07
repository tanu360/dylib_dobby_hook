#import <Foundation/Foundation.h>

@interface Constant : NSObject

@property(class, nonatomic, strong) NSString *G_EMAIL_ADDRESS;
@property(class, nonatomic, strong) NSString *G_EMAIL_ADDRESS_FMT;
@property(class, nonatomic, strong) NSString *G_DYLIB_NAME;

@property(class, nonatomic, strong) NSString *currentAppPath;
@property(class, nonatomic, strong) NSString *currentAppName;
@property(class, nonatomic, strong) NSString *currentAppVersion;
@property(class, nonatomic, strong) NSString *currentAppCFBundleVersion;
@property(class, nonatomic, assign) BOOL arm;
@property(class, nonatomic, assign) BOOL helper;

+ (BOOL)isFirstOpen;
+ (BOOL)isArm;
+ (BOOL)isHelper;
+ (NSString *)getCurrentAppPath;
+ (NSString *)getCurrentAppVersion;
+ (NSString *)getCurrentAppCFBundleVersion;
+ (NSString *)getSystemArchitecture;
+ (BOOL)isDebuggerAttached;
+ (NSArray<Class> *)getAllHackClasses;
+ (void)doHack;
@end
