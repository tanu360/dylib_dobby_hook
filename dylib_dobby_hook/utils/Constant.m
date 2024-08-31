
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <Cocoa/Cocoa.h>
#import "common_ret.h"
#include <mach-o/arch.h>
#include <sys/sysctl.h>
#import "HackProtocolDefault.h"
#import "HackHelperProtocolDefault.h"

@implementation Constant
static void __attribute__ ((constructor)) initialize(void){

    NSLog(@">>>>>> Constant ((constructor)) initialize(void)");

}


static NSString *G_EMAIL_ADDRESS = @"someone@example.com";;
static NSString *G_EMAIL_ADDRESS_FMT = @"someone@example.com";;
static NSString *G_DYLIB_NAME = @"libdylib_dobby_hook.dylib";

static NSString *currentAppPath;
static NSString *currentAppName;
static NSString *currentAppVersion;
static NSString *currentAppCFBundleVersion;
static BOOL arm;
static BOOL helper;
@dynamic G_EMAIL_ADDRESS;
@dynamic G_EMAIL_ADDRESS_FMT;
@dynamic G_DYLIB_NAME;
@dynamic currentAppPath;
@dynamic currentAppName;
@dynamic currentAppVersion;
@dynamic currentAppCFBundleVersion;
@dynamic arm;
@dynamic helper;

+ (NSString *)G_EMAIL_ADDRESS {
    return love69(G_EMAIL_ADDRESS);
}
+ (NSString *)G_EMAIL_ADDRESS_FMT {
    return love69(G_EMAIL_ADDRESS_FMT);
}
+ (NSString *)G_DYLIB_NAME {
    return G_DYLIB_NAME;
}

+ (NSString *)currentAppName {
    return currentAppName;
}

+ (BOOL) isFirstOpen {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; 
    NSString *storedVersion = [defaults objectForKey:@"appVersion"]; 

    if (!storedVersion || ![storedVersion isEqualToString:currentVersion]) {
        [defaults setObject:currentVersion forKey:@"appVersion"];
        [defaults synchronize];
        return true;
    }
    return false;
}
+ (void)initialize {
    if (self == [Constant class]) {
        NSLog(@">>>>>> Constant initialize");
        NSLog(@">>>>>> DobbyGetVersion: %s", DobbyGetVersion());

        NSBundle *app = [NSBundle mainBundle];
        currentAppName = [[app bundleIdentifier] copy];
        currentAppVersion =[ [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"] copy];
        currentAppCFBundleVersion = [[app objectForInfoDictionaryKey:@"CFBundleVersion"] copy];
        NSLog(@">>>>>> AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", currentAppName.UTF8String, currentAppVersion.UTF8String, currentAppCFBundleVersion.UTF8String);
        NSLog(@">>>>>> App Architecture is: %@", [Constant getSystemArchitecture]);
        NSLog(@">>>>>> App DebuggerAttached is: %d", [Constant isDebuggerAttached]);
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSLog(@">>>>>> plistPath is %@", plistPath);
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

        NSString *NSUserDefaultsPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"Preferences/%@.plist", bundleIdentifier]];
        NSLog(@">>>>>> NSUserDefaultsPath is %@", NSUserDefaultsPath);
        NSRange range = [[Constant getSystemArchitecture] rangeOfString:@"arm" options:NSCaseInsensitiveSearch];
        arm = range.location != NSNotFound;
        currentAppPath = [[app bundlePath] copy];
        NSLog(@">>>>>> [app bundlePath] %@",currentAppPath);
        if ([currentAppPath isEqualToString:@"/Library/PrivilegedHelperTools"]) {
            helper = YES;
        }
    }
}

+ (BOOL)isHelper {
    return helper;
}

+ (BOOL)isArm {
    return arm;
}

+ (NSString *)getCurrentAppPath {
    return currentAppPath;
}
+ (NSString *)getCurrentAppVersion {
    return currentAppVersion;
}
+ (NSString *)getCurrentAppCFBundleVersion {
    return currentAppCFBundleVersion;
}
+ (NSString *)getSystemArchitecture {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *machineString = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);    
    return machineString;
}


+ (BOOL)isDebuggerAttached {
    BOOL isDebugging = NO;
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSDictionary *environment = [processInfo environment];
    if (environment != nil) {
        if (environment[@"DYLD_INSERT_LIBRARIES"] ||
            environment[@"MallocStackLogging"] ||
            environment[@"NSZombieEnabled"] ||
            environment[@"__XDEBUGGER_PRESENT"] != nil) {
            isDebugging = YES;
        }
    }
    return isDebugging;
}


+ (NSArray<Class> *)getAllHackClasses {
    if ([self isHelper]) {
        return [self getAllSubclassesOfClass:[HackHelperProtocolDefault class]];
    }else{
        return [self getAllSubclassesOfClass:[HackProtocolDefault class]];
    }
    
}

+ (NSArray<Class> *)getAllSubclassesOfClass:(Class)parentClass {
    NSMutableArray<Class> *subclasses = [NSMutableArray array];
    unsigned int numClasses = 0;
    Class *classes = objc_copyClassList(&numClasses);
    for (int i = 0; i < numClasses; i++) {
        Class currentClass = classes[i];
        if ([self isSubclassOfClass:currentClass parentClass:parentClass] &&
            currentClass != parentClass) {
            [subclasses addObject:currentClass];
        }
    }
    
    free(classes);
    return [subclasses copy];
}

+ (BOOL)isSubclassOfClass:(Class)class parentClass:(Class)parentClass {
    while (class != nil) {
        if (class == parentClass) {
            return YES;
        }
        class = class_getSuperclass(class);
    }
    return NO;
}

+ (void)doHack {
    NSArray<Class> *personClasses = [Constant getAllHackClasses];
    
    for (Class class in personClasses) {

        id<HackProtocol> it = [[class alloc] init];
        
        if ([it shouldInject:currentAppName]) {
            NSString *supportAppVersion = [it getSupportAppVersion];
            if (supportAppVersion!=nil && supportAppVersion.length>0 && ![currentAppVersion hasPrefix:supportAppVersion]){
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"OK"];
                alert.messageText =  [NSString stringWithFormat:@"Unsupported current appVersion !!\nSuppert appVersion: [%s]\nCurrent appVersion: [%s]",[it getSupportAppVersion].UTF8String, currentAppVersion.UTF8String];;
                [alert runModal];
                return;
            }            
            [it hack];
            return;
        }
    }
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText =  [NSString stringWithFormat:@"Unsupported current app: [%s]", currentAppName.UTF8String];;
    [alert runModal];
}
@end
