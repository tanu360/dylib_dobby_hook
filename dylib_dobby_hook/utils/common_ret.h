
#ifndef common_ret_h
#define common_ret_h
#include <sys/types.h>
#include <stdio.h>

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#include <sys/ptrace.h>
#import <objc/message.h>
#import "common_ret.h"
#include <sys/xattr.h>
#import <CommonCrypto/CommonCrypto.h>
#import "encryp_utils.h"
#import <sys/ptrace.h>
#import <sys/sysctl.h>
#include <dlfcn.h>
#include <libproc.h>
#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#include <sys/ioctl.h>
#include <mach/mach.h>
#include <mach/thread_act.h>
#include <mach/mach_types.h>
#include <mach/i386/thread_status.h>

int ret2 (void);
int ret1 (void);
int ret0 (void);
void ret(void);
typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);
extern ptrace_ptr_t orig_ptrace;


typedef int (*sysctl_ptr_t)(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize);
int my_sysctl(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize);
extern sysctl_ptr_t orig_sysctl;

typedef kern_return_t (*task_get_exception_ports_ptr_t)(
    task_inspect_t task,
    exception_mask_t exception_mask,
    exception_mask_array_t masks,
    mach_msg_type_number_t *masksCnt,
    exception_handler_array_t old_handlers,
    exception_behavior_array_t old_behaviors,
    exception_flavor_array_t old_flavors
    );
kern_return_t my_task_get_exception_ports
(
     task_inspect_t task,
     exception_mask_t exception_mask,
     exception_mask_array_t masks,
     mach_msg_type_number_t *masksCnt,
     exception_handler_array_t old_handlers,
     exception_behavior_array_t old_behaviors,
     exception_flavor_array_t old_flavors
 );
extern task_get_exception_ports_ptr_t orig_task_get_exception_ports;


typedef kern_return_t (*task_swap_exception_ports_ptr_t)(
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
    );
kern_return_t my_task_swap_exception_ports
(
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
 );
extern task_swap_exception_ports_ptr_t orig_task_swap_exception_ports;
typedef OSStatus (*SecCodeCheckValidityWithErrors_ptr_t)(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
OSStatus hk_SecCodeCheckValidityWithErrors(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
extern SecCodeCheckValidityWithErrors_ptr_t SecCodeCheckValidityWithErrors_ori;


typedef OSStatus (*SecCodeCopySigningInformation_ptr_t)(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo);
extern SecCodeCopySigningInformation_ptr_t SecCodeCopySigningInformation_ori;


NSString *love69(NSString *input);
#endif /* common_ret_h */
