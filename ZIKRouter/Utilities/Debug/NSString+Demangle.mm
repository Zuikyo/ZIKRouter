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

#include <cxxabi.h>
#include <string>
#import "ZIKFindSymbol.h"

struct DemangleOptions {
    bool SynthesizeSugarOnTypes = false;
    bool DisplayDebuggerGeneratedModule = true;
    bool QualifyEntities = true;
    bool DisplayExtensionContexts = true;
    bool DisplayUnmangledSuffix = true;
    bool DisplayModuleNames = true;
    bool DisplayGenericSpecializations = true;
    bool DisplayProtocolConformances = true;
    bool DisplayWhereClauses = true;
    bool DisplayEntityTypes = true;
    bool ShortenPartialApply = false;
    bool ShortenThunk = false;
    bool ShortenValueWitness = false;
    bool ShortenArchetype = false;
    bool ShowPrivateDiscriminators = true;
    bool ShowFunctionArgumentTypes = true;
    
    DemangleOptions() {}
    
    static DemangleOptions FullDemangleOptions() {
        auto Opt = DemangleOptions();
        Opt.SynthesizeSugarOnTypes = true;
        Opt.DisplayDebuggerGeneratedModule = true;
        Opt.QualifyEntities = true;
        Opt.DisplayExtensionContexts = true;
        Opt.DisplayUnmangledSuffix = false;
        Opt.DisplayModuleNames = true;
        Opt.DisplayGenericSpecializations = true;
        Opt.DisplayProtocolConformances = true;
        Opt.DisplayWhereClauses = true;
        Opt.DisplayEntityTypes = true;
        Opt.ShortenPartialApply = true;
        Opt.ShortenThunk = true;
        Opt.ShortenValueWitness = true;
        Opt.ShortenArchetype = true;
        Opt.ShowPrivateDiscriminators = true;
        Opt.ShowFunctionArgumentTypes = true;
        return Opt;
    };
};

static std::string _demangleSymbolAsString(const char *mangledName, size_t mangledNameLength, const DemangleOptions &options = DemangleOptions()) {
    static std::string (*demangleSymbolAsString)(const char *, size_t, const DemangleOptions &) = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        demangleSymbolAsString = (std::string (*)(const char *, size_t, const DemangleOptions &))
        ZIKFindSymbol(ZIKGetImageByName("libSwiftCore.dylib"), ^bool(const char *symbolName) {
            if (strstr(symbolName, "swift") != 0 &&
                strstr(symbolName, "Demangle") != 0 &&
                strstr(symbolName, "demangleSymbolAsString") != 0 &&
                strstr(symbolName, "DemangleOptions") != 0 &&
                strstr(symbolName, "llvm") == 0 &&
                strstr(symbolName, "StringRef") == 0) {
                return true;
            }
            return false;
        });
    });
    if (demangleSymbolAsString) {
        return demangleSymbolAsString(mangledName, mangledNameLength, options);
    }
    NSCAssert(demangleSymbolAsString != NULL, @"Can't find demangleSymbolAsString in libswiftCore.dylib.");
    return nullptr;
};

@implementation NSString (Demangle)

- (NSString *)demangledAsSwift {
    DemangleOptions options = DemangleOptions::FullDemangleOptions();
    std::string demangled = _demangleSymbolAsString(self.UTF8String, self.length, options);
    if(demangled.length() == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:demangled.c_str()];
}

- (NSString *)demangledAsSimplifiedSwift {
    DemangleOptions options = DemangleOptions::FullDemangleOptions();
    options.QualifyEntities = false;
    std::string demangled = _demangleSymbolAsString(self.UTF8String, self.length, options);
    if(demangled.length() == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:demangled.c_str()];
}

- (NSString *)demangledAsCPP {
    NSString *result = nil;
    int status = 0;
    char* demangled = __cxxabiv1::__cxa_demangle(self.UTF8String, NULL, NULL, &status);
    
    if(status == 0 && demangled != NULL) {
        result = [NSString stringWithUTF8String:demangled];
    }
    
    if(demangled != NULL) {
        free(demangled);
    }
    
    return result;
}

@end

#endif
