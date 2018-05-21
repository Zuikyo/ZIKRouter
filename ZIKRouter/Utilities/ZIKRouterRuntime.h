//
//  ZIKRouterRuntime.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/20.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Replace a method with another method
 @discussion
 You can call original method by calling the swizzle method name:
 @code
 ZIKRouter_replaceMethodWithMethod([ClassA class],
                                   @selector(myMethod),
                                   [ClassB class],
                                   @selector(hooked_myMethod));
 
 @implementation ClassA
 - (void)myMethod {
     NSLog(@"Call origin method");
 }
 @end
 
 @implementation ClassB
 - (void)hooked_myMethod {
     //Call origin method
     [self hooked_myMethod];
 }
 @end
 @endcode
 
 @param originalClass The class you want to hook
 @param originalSelector The selector to be hooked. When there are same selector for class method and instance method, instance method is priority.
 @param swizzledClass The class providing the new method
 @param swizzledSelector The selector of new method. When there are same selector for class method and instance method, instance method is priority.
 @return True when hook successfully
 */
extern bool ZIKRouter_replaceMethodWithMethod(Class originalClass, SEL originalSelector,
                                              Class swizzledClass, SEL swizzledSelector);

///Same with ZIKRouter_replaceMethodWithMethod, but you can specify class method or instance method.
extern bool ZIKRouter_replaceMethodWithMethodType(Class originalClass, SEL originalSelector, bool originIsClassMethod,
                                                  Class swizzledClass, SEL swizzledSelector, bool swizzledIsClassMethod);

///Enumerate all classes
extern void ZIKRouter_enumerateClassList(void(^handler)(Class aClass));

///Enumerate all protocols
extern void ZIKRouter_enumerateProtocolList(void(^handler)(Protocol *protocol));

///Check whether a class is a subclass of another class
extern bool ZIKRouter_classIsSubclassOfClass(Class aClass, Class parentClass);

///Check whether a class is from Apple's system framework, or from your project.
extern bool ZIKRouter_classIsCustomClass(Class aClass);

///Check whether a class self implementing a method.
extern bool ZIKRouter_classSelfImplementingMethod(Class aClass, SEL method, bool isClassMethod);

///Check whether an object is an objc protocol.
extern bool ZIKRouter_isObjcProtocol(id protocol);

///Return objc protocol if object is Protocol.
extern Protocol *_Nullable ZIKRouter_objcProtocol(id protocol);

NS_ASSUME_NONNULL_END
