# Documentation

一个用于模块间路由，基于接口进行模块发现和依赖注入的Router，能够同时实现高度解耦和类型安全。

View router将UIKit中的所有界面跳转方式封装成一个统一的方法。

Service router用于模块寻找，通过protocol寻找对应的模块，并用protocol进行依赖注入和模块调用。

`ZRouter`为Swift提供更加Swifty、更加安全的路由方式。

---

## Features

* 支持Swift和Objective-C，以及两者混编
* 支持对模块进行静态依赖注入和动态依赖注入
* 用protocol动态获取界面和模块，隐藏具体类
* 用protocol向模块传递参数，基于接口进行类型安全的模块调用
* 明确声明可用于路由的public protocol，进行编译时检查和运行时检查，避免了动态特性带来的过于自由的安全问题
* 使用泛型表明指定功能的router
* 用adapter对两个模块进行解耦和接口兼容
* 支持界面路由和任意模块的路由
* 封装UIKit里的所有界面跳转方式（push、present modally、present as popover、segue、show、showDetail、addChildViewController、addSubview）以及自定义的展示方式，封装成一个统一的方法
* 支持用一个方法执行界面回退和模块销毁，不必区分使用pop、dismiss、removeFromParentViewController、removeFromSuperview
* 支持storyboard，可以对从segue中跳转的界面执行依赖注入
* 完备的错误检查，可以检测界面跳转时的大部分问题
* 支持界面跳转过程中的AOP回调

## Table of Contents

### Basics

1. [Router Implementation](RouterImplementation.md)
2. [Module Registration](ModuleRegistration.md)
3. [Routable Declaration](RoutableDeclaration.md)
4. [Type Checking](TypeChecking.md)
5. [Perform Route](PerformRoute.md)
6. [Remove Route](RemoveRoute.md)
7. [Make Destination](MakeDestination.md)

### Advanced Features

1. [Error Handle](ErrorHandle.md)
2. [Storyboard](Storyboard.md)
3. [AOP](AOP.md)
4. [Dependency Injection](DependencyInjection.md)
5. [Adapter](Adapter.md)
6. [Modularization](Modularization.md)