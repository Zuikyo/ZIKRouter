# Design Idea

## Basic Architecture

![Basic Architecture](../Resources/ArchitecturePreview.png)

## Design Idea

ZIKRouter uses protocol to manage modules. The advantages of interface oriented programming:

* Strict type safety with compile time check
* Reduce refactoring costs with compile time check
* Make sure the module implements its protocol
* Declare module's dependencies with protocol
* Avoid using non-existent module with parameter checking when routing
* Separate required protocol and provided protocol to thoroughly decouple

## Why ZIKRouter？

Comparing to other module manage or router frameworks, what's the advantages of ZIKRouter?

### URL Router

ZIKRouter manages modules with protocol, but most of router frameworks use URL matching to get modules.

Advantages of URL router:

* Highly dynamic
* East to manage route rules in multi platforms
* East to use URL Scheme

Disadvantages of URL router:

* Type of parameters is limited when routing, and there is no compile time check
* Only for view module, not for any service module
* Can't use designated initializer to provide required parameters
* Need to add new initializer in the view controller to support its url
* Doesn't support storyboard
* Can't declare module's interface, highly rely on documentation. So it's not that safe when refactoring
* Can't make sure whether the module exists or not when you use it
* Hard to manage route strings
* Can't separate required protocol and provided protocol. So you can't thoroughly decouple

#### Improvement

All disadvantages of URL router can be resolved if we use protocol to manage modules. We can pass parameters with protocols and check type of parameters with the compile. And with routable declaration and compile-time check, ZIKRouter can make sure the module exists when you use it. You don't need to modify the module when adding route for it.

ZIKRouter also allows you to get router with string identifier. So it's easy to use ZIKRouter with other URL router frameworks.

### Module Manager with Reflection

Some module manager use runtime and category features in Objective-C to get modules. Such as getting class with `NSClassFromString `, then use `performSelector:` `NSInvocation`to perform methods.

The general implementation is adding new interfaces with categories in the module manager, and in the category method, use strings to get class with runtime and perform methods.

Advantages:

* Compile time check for category methods
* The implementation is lightweight

Disadvantages:

* Still use strings in category
* Can't make sure whether the module exists or not when you use it
* Can't separate required protocol and provided protocol in category methods. So you can't thoroughly decouple
* Rely too much on runtime feature, can't be used in pure Swift
* According to the [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), it's not recommanded to invoke arbitrary methods with runtime. See [Are performSelector and respondsToSelector banned by App Store?
](https://stackoverflow.com/questions/42662028/are-performselector-and-respondstoselector-banned-by-app-store)

#### Improvement

ZIKRouter fetch modules with protocol matching instead of runtime discovering with strings. It can be used in Objective-C and Swift. And ZIKRouter can make sure all modules exists.

### Module Manager with Type Matching

Some module manager matchs module with its class or protocol.

#### Improvement

It's similar to ZIKRouter, but it doesn't support pure Swift type, and it can't apply additional configuration to the module. ZIKRouter doesn't match protocol or class with the module directly, it matchs protocol with its router subclass, and let the router subclass to instantiate the module object.

Adding a router layer can let the module be matched with multi protocols. And in the router subclass, you can also inject dependencies, adapt different protocols and do additional actions.

And ZIKRouter makes limitation when passing protocol to fetch module. Only those protocols declared as routable can be used. Then you won't use a non-existent module.

## Architecture

![Architecture](../Resources/Architecture.png)