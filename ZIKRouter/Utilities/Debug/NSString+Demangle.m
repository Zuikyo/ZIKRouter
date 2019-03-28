//
//  NSString+Demangle.mm
//  ZIKRouter
//
//  Created by zuik on 2018/5/15.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NSString+Demangle.h"

#if DEBUG

#import <dlfcn.h>

static const char *demangleAsSwiftString(const char *name) {
    typedef char *(*swift_demangle_ft)(const char *mangledName, size_t mangledNameLength, char *outputBuffer, size_t *outputBufferSize, uint32_t flags);
    static swift_demangle_ft swift_demangle_f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swift_demangle_f = (swift_demangle_ft) dlsym(RTLD_DEFAULT, "swift_demangle");
    });
    
    if (swift_demangle_f) {
        return swift_demangle_f(name, strlen(name), 0, 0, 0);
    }
    return name;
}

@implementation NSString (Demangle)

- (NSString *)demangledAsSwift {
    const char *demangledString = demangleAsSwiftString(self.UTF8String);
    if (demangledString) {
        return @(demangledString);
    }
    return self;
}

- (NSString *)demangledAsSimplifiedSwift {
    const char *demangledString = demangleAsSwiftString(self.UTF8String);
    if (demangledString) {
        return @(demangledString);
    }
    return self;
}

@end

#endif
