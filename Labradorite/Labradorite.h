//
//  Labradorite.h
//  Labradorite
//
//  Created by Eva Isabella Luna on 11/21/23.
// 

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import <sys/types.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/machine.h>
#import <stdint.h>
#import <device/device_types.h>
#import <CoreFoundation/CoreFoundation.h>
#import <mach/mach.h>
#import <pwd.h>

#if TARGET_OS_IPHONE

    #define IO_OBJECT_NULL ((io_object_t)0)

    typedef UInt32 IOOptionBits;

    typedef mach_port_t io_object_t;
    typedef io_object_t io_registry_entry_t;

    extern mach_port_t kIOMainPortDefault;
    extern mach_port_t kIOMasterPortDefault;

    extern kern_return_t IOObjectRelease(io_object_t object);

    extern io_registry_entry_t IORegistryEntryFromPath(mach_port_t mainPort, io_string_t path);
    extern CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

#endif

@interface Labradorite : NSObject
+(NSString *) getDeviceID;
+(NSString *) getDeviceModel;
+(NSString *) getDeviceModelMain;
+(NSString *) getDeviceModelFallback;
+(NSString *) returnSysctlFlag:(char *)name;

@end

NSString *deviceModel;

extern CFURLRef CFCopyHomeDirectoryURLForUser(CFStringRef user);
extern CFDictionaryRef _CFCopySystemVersionDictionary(void);
extern CFBundleRef _CFBundleCreateWithExecutableURLIfLooksLikeBundle(CFAllocatorRef allocator, CFURLRef url);
