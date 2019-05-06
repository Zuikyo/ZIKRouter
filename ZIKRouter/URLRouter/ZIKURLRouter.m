//
//  ZIKURLRouter.m
//  ZIKRouter
//
//  Created by zuik on 2019/4/20.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKURLRouter.h"
#import "ZIKURLRouteResult.h"

static NSString *kPlaceholderComponent = @"<>";

@interface ZIKURLRouter ()

/**
 Container for static url or url with continuous placeholders like: scheme://host/path/:placeholder/:placeholder2
 Key: fixed pattern Value: origin pattern
 */
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *patternContainer;

/**
 Container for url with discontinuous placeholders like: scheme://host/:placeholder/path1/:placeholder2
 {
     5 // url component count
     : [
        ["scheme", "host", ":placeholder", "path1", ":placeholder2", "scheme://host/:placeholder/path1/:placeholder2", 24 \* placeholder idxs *\],
     ],
 }
 */
@property(nonatomic, strong) NSMutableDictionary<NSNumber *,  NSMutableArray *> *placeholderPatternContainer;
@end

@implementation ZIKURLRouter

- (instancetype)init {
    if (self = [super init]) {
        _patternContainer = [NSMutableDictionary dictionary];
        _placeholderPatternContainer = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerURLPattern:(NSString *)pattern {
    NSParameterAssert(pattern);
    NSURL *url = [NSURL URLWithString:pattern];
    NSAssert1(url, @"Invalid url pattern: %@", pattern);
    if (!url) {
        return;
    }
    NSString *path = url.path;
    if (!path || [path rangeOfString:@":"].location == NSNotFound) {
        _patternContainer[pattern] = pattern;
        return;
    }
    NSMutableString *key = [NSMutableString string];
    NSString *scheme = url.scheme;
    if (scheme) {
        [key appendString:scheme];
    }
    [key appendString:@"://"];
    NSString *host = url.host;
    if (host) {
        [key appendString:host];
    }
    
    BOOL hasPlaceHolder = NO;
    BOOL hasDiscontinuousPlaceHolders = NO;
    NSArray *pathComponents = url.pathComponents;
    if (pathComponents.count > 0) {
        for (NSString *pathComponent in pathComponents) {
            if ([pathComponent isEqualToString:@"/"]) {
                continue;
            }
            [key appendString:@"/"];
            // Replace placeholder with kPlaceholderComponent
            if ([pathComponent hasPrefix:@":"]) {
                [key appendString:kPlaceholderComponent];
                hasPlaceHolder = YES;
            } else {
                [key appendString:pathComponent];
                if (hasPlaceHolder) {
                    hasDiscontinuousPlaceHolders = YES;
                    break;
                }
            }
        }
    }
    if (!hasDiscontinuousPlaceHolders) {
        _patternContainer[key] = pattern;
    } else {
        [self _addPlaceholderPattern:pattern scheme:scheme host:host url:url];
    }
}

- (void)_addPlaceholderPattern:(NSString *)pattern scheme:(NSString *)scheme host:(NSString *)host url:(NSURL *)url {
    if (!scheme) {
        scheme = @"";
    }
    if (!host) {
        host = @"";
    }
    NSMutableArray *components = [self pathComponetsForURL:url];
    [components insertObject:host atIndex:0];
    [components insertObject:scheme atIndex:0];
    
    NSNumber *count = @(components.count);
    NSMutableArray *countedRoutes = _placeholderPatternContainer[count];
    if (!countedRoutes) {
        countedRoutes = [NSMutableArray array];
        _placeholderPatternContainer[count] = countedRoutes;
    }
    
    int idxsToCheck = 0;
    for (int idx = 0; idx < components.count; idx++) {
        NSString *component = components[idx];
        if (![component hasPrefix:@":"]) {
            idxsToCheck = idxsToCheck * 10 + idx;
        }
    }
    [components addObject:pattern];
    [components addObject:@(idxsToCheck)];
    [countedRoutes addObject:components];
}

- (ZIKURLRouteResult *)resultForURLWithDiscontinuousPlaceHolders:(NSURL *)url {
    ZIKURLRouteResult *result;
    NSString *scheme = url.scheme ?: @"";
    NSString *host = url.host ?: @"";
    NSMutableArray<NSString *> *components = [self pathComponetsForURL:url];
    [components insertObject:host atIndex:0];
    [components insertObject:scheme atIndex:0];
    
    NSMutableArray *countedRoutes = _placeholderPatternContainer[@(components.count)];
    if (!countedRoutes) {
        return nil;
    }
    NSArray *matchedComponents;
    for (NSArray *registeredComponents in countedRoutes) {
        if (![[components firstObject] isEqualToString:[registeredComponents firstObject]]) {
            continue;
        }
        int idxsToCheck = [[registeredComponents lastObject] intValue];
        int idx;
        BOOL match = YES;
        while (idxsToCheck > 0) {
            idx = idxsToCheck % 10;
            NSString *component = components[idx];
            NSString *registeredComponent = registeredComponents[idx];
            if (![component isEqualToString:registeredComponent]) {
                match = NO;
                break;
            }
            idxsToCheck = idxsToCheck / 10;
        }
        if (match) {
            matchedComponents = registeredComponents;
            break;
        }
    }
    
    if (!matchedComponents) {
        return nil;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (int idx = 0; idx < components.count; idx++) {
        NSString *key = matchedComponents[idx];
        if ([key hasPrefix:@":"]) {
            key = [key substringFromIndex:1];
            NSString *value = components[idx];
            parameters[key] = value;
        }
    }
    NSString *pattern = matchedComponents[matchedComponents.count - 2];
    
    result = [ZIKURLRouteResult new];
    result.url = url;
    result.parameters = parameters;
    result.identifier = pattern;
    return result;
}

- (ZIKURLRouteResult *)resultForURL:(NSString *)urlString {
    NSParameterAssert(urlString);
    if (!urlString) {
        return nil;
    }
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ZIKURLRouteResult *result;
    NSURL *url = [NSURL URLWithString:urlString];
    NSAssert1(url, @"Invalid url: %@", urlString);
    if (!url) {
        return nil;
    }
    NSString *identifier;
    NSInteger placeholderLevel = 0;
    NSArray<NSString *> *pathComponents = [self pathComponetsForURL:url];
    NSInteger maxPlaceholderLevel = pathComponents.count;
    for (placeholderLevel = 0; placeholderLevel <= maxPlaceholderLevel; placeholderLevel++) {
        identifier = [self _identifierForURL:url placeholderLevel:placeholderLevel];
        if (identifier) {
            break;
        }
    }
    if (!identifier) {
        return [self resultForURLWithDiscontinuousPlaceHolders:url];
    }
    result = [ZIKURLRouteResult new];
    result.url = url;
    result.identifier = identifier;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (placeholderLevel > 0) {
        NSArray<NSString *> *patternPathComponents = [self pathComponetsForURL:[NSURL URLWithString:identifier]];
        if (pathComponents && patternPathComponents && pathComponents.count == patternPathComponents.count && patternPathComponents.count >= placeholderLevel) {
            NSInteger idx = patternPathComponents.count - 1;
            NSInteger parameterCount = placeholderLevel;
            while (parameterCount-- > 0) {
                NSString *key = [patternPathComponents[idx] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                if ([key hasPrefix:@":"]) {
                    key = [key substringFromIndex:1];
                }
                parameters[key] = [pathComponents[idx] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                idx--;
            }
        }
        result.parameters = parameters;
    }
    NSString *query = url.query;
    if (query) {
        [[NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO].queryItems
         enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            parameters[[item.name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] = [item.value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }];
    }
    result.parameters = parameters;
    return result;
}

- (NSString *)_identifierForURL:(NSURL *)url placeholderLevel:(NSInteger)level {
    NSInteger placeholderLevel = level;
    while (level > 0) {
        url = url.URLByDeletingLastPathComponent;
        level--;
    }
    NSMutableArray *components = [@[(url.scheme ?: @""), @"://", (url.host ?: @"")] mutableCopy];
    for (NSString *pathComponent in [self pathComponetsForURL:url]) {
        [components addObject:@"/"];
        [components addObject:pathComponent];
    }
    for (int i = 0; i < placeholderLevel; i++) {
        [components addObject:@"/"];
        [components addObject:kPlaceholderComponent];
    }
    NSString *key = [components componentsJoinedByString:@""];
    return _patternContainer[key];
}

- (NSMutableArray<NSString *> *)pathComponetsForURL:(NSURL *)url {
    NSString *path = url.path;
    if (!path || path.length == 0) {
        return nil;
    }
    NSArray *pathComponents = url.pathComponents;
    NSMutableArray *components;
    if (pathComponents.count > 0) {
        components = [NSMutableArray array];
        for (NSString *pathComponent in pathComponents) {
            if ([pathComponent isEqualToString:@"/"]) {
                continue;
            }
            [components addObject:pathComponent];
        }
    }
    return components;
}

@end
