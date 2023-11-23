//
//  Labradorite.m
//  Labradorite
//
//  Created by Eva Isabella Luna on 11/21/23.
//

#import "Labradorite.h"

@implementation Labradorite

/**
 Function used to grab the current device's model identifier,
 i.e. iPhone16,2 or Mac15,11.
 */
+(NSString *) getDeviceID {
    NSString *identifier;
#if TARGET_OS_IPHONE
    return [self returnSysctlFlag:"hw.machine"];
#elif TARGET_OS_OSX
    return [self returnSysctlFlag:"hw.product"];
#endif
    return identifier;
}

/**
 Returns the current device's marketing name,
 i.e. iPhone 15 Pro Max, MacBook Pro (16-inch, Nov 2023).
 */
+(NSString *)getDeviceModel {
    NSString *fallbackName = [self getDeviceID];
    NSString *trueName = NULL;
    
    trueName = [self getDeviceModelMain];
    if (trueName == NULL) {
        NSLog(@"trueName = %@", trueName);
        trueName = [self getDeviceModelFallback];
        if(trueName != NULL) { NSLog(@"trueName = %@", trueName); return trueName; }
    } else {
        NSLog(@"trueName = %@", trueName);
        return trueName;
    }
    NSLog(@"trueName = %@", trueName);
    return fallbackName;
}

/**
 Function used to return the device model on an Apple Silicon device.
 These devices all have `product-description` in their `IODeviceTree`.
 */
+(NSString *) getDeviceModelMain {
        NSString *outName = NULL;

#if !TARGET_OS_WATCH
        BOOL status = FALSE;
    
        io_registry_entry_t registry = IO_OBJECT_NULL;
        CFDataRef data = NULL;
        CFStringRef string = NULL;
        char *end = NULL;
        
        if(@available(iOS 15.0, watchOS 8.0, tvOS 15.0, macOS 12.0, *)) {
            registry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product");
        } else {
            registry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/product");
        }
    
        if (registry == IO_OBJECT_NULL) { goto fin; }
        
        CFStringRef key = CFSTR("product-description");
        data = IORegistryEntryCreateCFProperty(registry, key, kCFAllocatorDefault, 0);
        if (data == NULL) { goto fin; }
        
        string = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(data), CFDataGetLength(data), kCFStringEncodingUTF8, FALSE);
        if (string == NULL) { goto fin; }
        
        CFIndex length = CFStringGetLength(string);
        if (length == 0) { goto fin; }
    
        CFIndex size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
        
        if (size == 0) { goto fin; }

        end = malloc(size);
        memset(end, 0, size);
        
        status = CFStringGetCString(string, end, size, kCFStringEncodingUTF8);
        if (!status) { goto fin; }
        
        outName = [NSString stringWithCString:end encoding:NSUTF8StringEncoding];
        
    fin:
        if (registry != IO_OBJECT_NULL) { IOObjectRelease(registry); }
        if (data != NULL) { CFRelease(data); }
        if (string != NULL) { CFRelease(string); }
        if (end != NULL) { free(end); }
#endif

        return (outName == NULL) ? NULL : outName;
}

/**
 Function used to return the device model on non-Apple Silicon devices
 Only supports Intel-based Macs, and uses a hardcoded list of identifiers.
 */
+(NSString *) getDeviceModelFallback {
    //TODO: Actually implement this
    //return (outName == NULL) ? NULL : outName;
    return @"fazbear";
}

#pragma mark - Utilities

/**
 Returns the specified `sysctl` flag as an NSString.
 */
+(NSString *) returnSysctlFlag:(char *)name {
    size_t size;
    sysctlbyname(name, NULL, &size, NULL, 0);
    char *temp = malloc(size);
    sysctlbyname(name, temp, &size, NULL, 0);
    NSString *sysctloutput = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
    return sysctloutput;
}

@end
