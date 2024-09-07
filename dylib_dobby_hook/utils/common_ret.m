#include "common_ret.h"
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "MemoryUtils.h"
#include <mach-o/dyld.h>
#include <sys/ptrace.h>
#import <sys/sysctl.h>
#include <mach/mach_types.h>
#include <mach/i386/thread_status.h>

int ret2 (void){
    printf(">>>>>> ret2\n");
    return 2;
}
int ret1 (void){
    printf(">>>>>> ret1\n");
    return 1;
}
int ret0 (void){
    printf(">>>>>> ret0\n");
    return 0;
}

void ret(void){
    printf(">>>>>> ret\n");
}
ptrace_ptr_t orig_ptrace = NULL;
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if(_request != 31){
        return orig_ptrace(_request,_pid,_addr,_data);
    }
    printf(">>>>>> [AntiAntiDebug] - ptrace request is PT_DENY_ATTACH\n");
    return 0;
}
sysctl_ptr_t orig_sysctl = NULL;
int my_sysctl(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize){
    int ret = orig_sysctl(name,namelen,info,infosize,newinfo,newinfosize);
    if(namelen == 4 && name[0] == 1 && name[1] == 14 && name[2] == 1){
        struct kinfo_proc *info_ptr = (struct kinfo_proc *)info;
        if(info_ptr && (info_ptr->kp_proc.p_flag & P_TRACED) != 0){
            NSLog(@">>>>>> [AntiAntiDebug] - sysctl query trace status.");
            info_ptr->kp_proc.p_flag ^= P_TRACED;
            if((info_ptr->kp_proc.p_flag & P_TRACED) == 0){
                NSLog(@">>>>>> [AntiAntiDebug] - trace status reomve success!");
            }
        }
    }
    return ret;
}
task_get_exception_ports_ptr_t orig_task_get_exception_ports = NULL;
kern_return_t my_task_get_exception_ports
(
 task_inspect_t task,
 exception_mask_t exception_mask,
 exception_mask_array_t masks,
 mach_msg_type_number_t *masksCnt,
 exception_handler_array_t old_handlers,
 exception_behavior_array_t old_behaviors,
 exception_flavor_array_t old_flavors
 ){
    kern_return_t r = orig_task_get_exception_ports(task, exception_mask, masks, masksCnt, old_handlers, old_behaviors, old_flavors);
    for (int i = 0; i < *masksCnt; i++)
    {
        if (old_handlers[i] != 0) {
            old_handlers[i] = 0;
        }
        if (old_flavors[i]  == THREAD_STATE_NONE) {
            old_flavors[i] = 9;
            NSLog(@">>>>>> [AntiAntiDebug] - my_task_get_exception_ports reset old_flavors[i]=9");
        }
    }
    return r;
}
task_swap_exception_ports_ptr_t orig_task_swap_exception_ports = NULL;
kern_return_t my_task_swap_exception_ports(
    task_t task,
    exception_mask_t exception_mask,
    mach_port_t new_port,
    exception_behavior_t new_behavior,
    thread_state_flavor_t new_flavor,
    exception_mask_array_t old_masks,
    mach_msg_type_number_t *old_masks_count,
    exception_port_array_t old_ports,
    exception_behavior_array_t old_behaviors,
    thread_state_flavor_array_t old_flavors
) {
   if (exception_mask & EXC_MASK_BREAKPOINT) {
       NSLog(@">>>>>> [AntiAntiDebug] - my_task_swap_exception_ports Breakpoint exception detected, blocking task_swap_exception_ports");
       return KERN_FAILURE; // 返回错误码阻止调用
   }
   return orig_task_swap_exception_ports(task, exception_mask, new_port, new_behavior, new_flavor, old_masks, old_masks_count, old_ports, old_behaviors, old_flavors);
}
SecCodeCheckValidityWithErrors_ptr_t SecCodeCheckValidityWithErrors_ori = NULL;
OSStatus hk_SecCodeCheckValidityWithErrors(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors) {
    NSLog(@">>>>>> hk_SecCodeCheckValidityWithErrors  requirement = %@", requirement);
    return errSecSuccess;
}
SecCodeCopySigningInformation_ptr_t SecCodeCopySigningInformation_ori = NULL;
NSString *love69(NSString *input) {
    NSMutableString *output = [NSMutableString stringWithCapacity:input.length];
    for (NSUInteger i = 0; i < input.length; i++) {
        unichar ch = [input characterAtIndex:i];

        if (ch >= 'A' && ch <= 'Z') {
            ch = 'A' + (ch - 'A' + 13) % 26;
        } else if (ch >= 'a' && ch <= 'z') {
            ch = 'a' + (ch - 'a' + 13) % 26;
        }
        [output appendFormat:@"%C", ch];
    }
    return output;
}
