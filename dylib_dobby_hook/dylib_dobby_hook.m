#import "dylib_dobby_hook.h"
#import "dobby.h"
#import "Constant.h"
#import "MemoryUtils.h"
#import <Cocoa/Cocoa.h>

@implementation dylib_dobby_hook

#ifdef DEBUG
const bool SHOW_ALARM = true;
#else
const bool SHOW_ALARM = false;
#endif
int sum(int a, int b) {
    return a+b;
}
static int (*sum_p)(int a, int b);
int mySum(int a,int b){
    return a - b;
}
void initTest(void){

    NSLog(@"before %d", sum(1, 2));
    NSLog(@"%s", DobbyGetVersion());
    DobbyHook(sum, mySum, nil);
    NSLog(@"after %d", sum(1, 2));

}


+ (void) load {
    if (SHOW_ALARM) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Warning"];
        [alert setInformativeText:@"Please confirm if the app has been backed up.\nIf there are any issues, please restore it yourself!"];
        [alert addButtonWithTitle:@"Confirm"];
        [alert addButtonWithTitle:@"Cancel"];
        NSInteger response = [alert runModal];
        if (response == NSAlertFirstButtonReturn) {
            [Constant doHack];
        } else {
            return;
        }
    }else {
        [Constant doHack];
    }
}
@end
