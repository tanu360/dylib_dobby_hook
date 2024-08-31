
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import <AppKit/AppKit.h>
#import "common_ret.h"
#import <Cocoa/Cocoa.h>



@interface MyWindow : NSWindow
@end
@implementation MyWindow
- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {
    contentRect = NSMakeRect(0, 0, 800, 600);
    styleMask |= NSWindowStyleMaskTitled;
    self = [super initWithContentRect:contentRect styleMask:styleMask backing:backingStoreType defer:flag];
    if (self) {
        self.backgroundColor = [NSColor clearColor];
        self.opaque = NO;
        self.ignoresMouseEvents = NO;
        self.level = NSStatusWindowLevel;
    }
    return self;
}
- (BOOL)canBecomeKeyWindow {
    return NO;
}

@end

@interface MyView : NSView
@property (nonatomic, assign) NSPoint pointA;
@property (nonatomic, assign) NSPoint pointB;
@property (nonatomic, assign) BOOL isLine;
@end
@implementation MyView
- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPath];
    if (self.isLine) {
        [path moveToPoint:self.pointA];
        [path lineToPoint:self.pointB];
    } else {
        NSRect rect = NSMakeRect(self.pointA.x, self.pointA.y, self.pointB.x - self.pointA.x, self.pointB.y - self.pointA.y);
        [path appendBezierPathWithRect:rect];
    }
    [[NSColor redColor] setStroke];
    [path setLineWidth:2.0];
    [path stroke];
}
@end


@interface DevHack : HackProtocolDefault
@end

@implementation DevHack

static NSWindow *myWindow = nil;

+ (void)load {
    
}

- (NSString *)getAppName {
    return @"com.voidm.mac-app-dev-swift";
}

- (NSString *)getSupportAppVersion {
    return @"";
}
+ (void)mem_event:(id)sender {
    NSLog(@">>>>> mem_event");
    uintptr_t *ptr = (void *)0x1000815d0; // 读取基址的内容,转为指针
    void * addressPtr = (void *) *ptr;
    [MemoryUtils readIntAtAddress:(addressPtr+0x40)];
    [MemoryUtils writeInt:(int)1 toAddress:(addressPtr+0x40)];
    
    NSLog(@">>>>>> mem_event over");

}

+ (void)draw_event:(id)sender {
    NSLog(@">>>>> draw_event");
    if (myWindow==nil) {
        NSApplication *application = [NSApplication sharedApplication];
        NSRect windowRect = NSMakeRect(0, 0, NSScreen.mainScreen.frame.size.width, NSScreen.mainScreen.frame.size.height);
        myWindow = [[MyWindow alloc] initWithContentRect:windowRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        MyView *line = [[MyView alloc] initWithFrame:myWindow.contentView.bounds];
        line.pointA = NSMakePoint(50, 50);
        line.pointB = NSMakePoint(200, 200);
        line.isLine = YES;
        [myWindow.contentView addSubview:line];
        MyView *rect = [[MyView alloc] initWithFrame:myWindow.contentView.bounds];
        rect.pointA = NSMakePoint(300, 300);
        rect.pointB = NSMakePoint(400, 500);
        rect.isLine = NO;
        [myWindow.contentView addSubview:rect];
        [myWindow makeKeyAndOrderFront:nil];
        [application run];
    }else {
        if ([myWindow isVisible]) {
           [myWindow orderOut:nil];
        } else {
           [myWindow makeKeyAndOrderFront:nil];
        }
    }
    NSLog(@">>>>>> draw_event over");
}

- (BOOL)hack {

    return YES;
}
typedef void (*CPrintHelloPointer)(void);
typedef int (*CRetOnePointer)(void);
typedef int (*CRetAddMethodPointer)(int a,int b);



typedef void (*MethodPointer)(id, SEL);
MethodPointer methodPointer = NULL;
IMP originalMethodIMP = nil;
- (void)hk_viewDidLoad {
    NSLog(@">>>>>> my_viewDidLoad is called with self: %@ and selector: %@", self, NSStringFromSelector(_cmd));
    ((void *(*)(id, SEL))originalMethodIMP)(self, _cmd);
}
int (*viewDidLoadImp_ori)(void);
void my_viewDidLoad(id self, SEL _cmd) {

    NSLog(@">>>>>> viewDidAppear is hooked!");
    ((void(*)(id, SEL))viewDidLoadImp_ori)(self, _cmd);
}
void fuckPoint(void){
    intptr_t *a = (void *)0x123;
    int aValue = (int)*a;
    intptr_t* addressOfA =(void *) &aValue;
    intptr_t* a2 = (void *)0x123;
    intptr_t* b2 = (void *)*a2;
    int value = (int)*b2;

}

@end
