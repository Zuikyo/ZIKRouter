# Routable

为模块创建 router，以及注册 protocol 时，需要对 destination 类和 protocol 进行`可路由`的声明。声明时只需要为指定的类添加对应的 routable 扩展。

## Routable destination

在 view router 中，为 destination 添加`ZIKRoutableView`扩展：

```swift
extension EditorViewController: ZIKRoutableView {

}
```

<details><summary>Objective-C示例</summary>

```objectivec
@interface EditorViewController(EditorViewRouter)<ZIKRoutableView>
@end
@implementation EditorViewController(EditorViewRouter)
@end
```

或者使用宏定义：

```objectivec
DeclareRoutableView(EditorViewController, EditorViewRouter)
```

</details>

声明 routable destination 是为了支持 storyboard，如果在执行 segue 时检测到 view controller 遵守`ZIKRoutableView`，就会去搜索 view controller 对应的 view router 进行依赖注入。

## Routable protocol

当你使用一个 protocol 来获取 router 时，protocol 必须是可路由的。

针对不同程度的动态需求，提供了不同程度的动态方案。在 Swift 上和 Objective-C 上，routable 声明有不同的实现方式。

### Routable in Swift

Swift 示例：

在 Swift 中，用结构体的泛型值来传递 protocol：

```swift
public struct RoutableView<Protocol> {
    //外部无法访问初始化方法进行实例化
    @available(*, unavailable, message: "Protocol is not declared as routable")
    public init() { }
    
    /// 只在 extension 中使用此初始化方法
    public init(declaredProtocol: Protocol.Type) { }
}
```

声明`SwiftEditorViewInput`协议是可路由的，并且只能用于界面路由：

```swift
extension RoutableView where Protocol == SwiftEditorViewInput {
    //允许实例化
    init() { self.init(declaredProtocol: Protocol.self) }
}
```
`RoutableView`默认初始化方法是私有的，只有声明了的 protocol 才能访问它的初始化方法，进行实例化操作`RoutableView<SwiftEditorViewInput>()`：

```swift
class TestViewController: UIViewController {
    func showEditor() {
        Router.perform(
            to: RoutableView<SwiftEditorViewInput>(),
            path: .push(from: self)
            )
    }
}
```

因此当你传入一个错误的 protocol 时，例如`RoutableView<UnroutableProtocol>()`，会产生编译错误。

初始化方法 `init(declaredProtocol: Protocol.Type)` 只是用来消除 swift 的编译检查 `initializer for struct 'xxx' must use "self.init(...)" or "self = ..." because it is not in module xxx`. 参考 [restrict-cross-module-struct-initializers](https://github.com/apple/swift-evolution/blob/master/proposals/0189-restrict-cross-module-struct-initializers.md)。不要在除了 extension 之外的地方使用此初始化方法。如果你错误地在其他地方使用了这些初始化方法，在启动时会给出断言错误。

声明了之后，在使用时 Xcode 会自动列出所有可用的路由：

![Xcode Auto Completion](../Resources/route-auto-completion.png)

### 多 Protocol 组合

可以用组合而成的 protocol 声明：


```swift
extension RoutableView where Protocol == UIViewController & EditorViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

可以用类型别名简化:

```swift
typealias RequiredEditorViewInput = UIViewController & EditorViewInput
```
之后就能用组合 protocol 获取模块：

```swift
Router.perform(
            to: RoutableView<RequiredEditorViewInput>(),
            path: .push(from: self),
            configuring: { (config, prepareDestiantion, _) in
                prepareDestination({ destination in
                    // destination 被推断为 UIViewController & EditorViewInput 类型
                    // 无需再手动转换为 UIViewController
                })
        })
        
let destination = Router.makeDestination(to: RoutableView<RequiredEditorViewInput>())
// destination 被推断为 UIViewController & EditorViewInput 类型
```
使用组合 protocol，可以同时为 destination 指定多个类型，而无需再去进行类型转换操作。

### Routable in Objective-C

Swift 语言是静态的，本身就是类型安全的，而在 Objective-C 中，我们需要用另一种方式进行声明。

#### `ZIKViewRoutable`和`ZIKServiceRoutable`

当声明一个 protocol 可用于界面路由时，需要让 protocol 继承自`ZIKViewRoutable`。

```objectivec
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *editorTitle;
@end
```

类似的，如果是 service protocol，则继承自`ZIKServiceRoutable`。

#### `ZIKViewModuleRoutable`和`ZIKServiceModuleRoutable`

当声明一个 protocol 可用于界面模块路由时，需要让 protocol 继承自`ZIKViewModuleRoutable`。

```objectivec
@protocol EditorModuleInput <ZIKViewModuleRoutable>
@property (nonatomic, copy) NSString *editorTitle;
@end
```

类似的，如果是 service module protocol，则继承自`ZIKServiceModuleRoutable`。

#### 动态检查

当 app 在 DEBUG 模式下启动时，ZIKRouter 用 OC runtime 检查所有继承自`ZIKViewRoutable`、`ZIKServiceRoutable `、`ZIKViewModuleRoutable`、`ZIKServiceModuleRoutable`的 protocol，确保这些 protocol 都已经和某个 router 注册，并且 router 中注册的 destination 和 defaultRouteConfiguration 都遵守对应的 protocol。

对于纯 Swift 类型，ZIKRouter 也能动态遍历所有已声明的 swift protocols， 检查对应的类型是否遵守对应的纯 Swift 的 protocol。这个功能的实现使用了`libswiftCore.dylib`里的私有 API，仅在 DEBUG 模式下使用，在 release 模式下这部分代码不会被编译。

继承自`ZIKViewRoutable`的 objc protocol，在 Swift 中将会自动声明为 routable，不需要再按照 Swift 的方式重复声明。

关于类型检查的详细内容，请查看 [类型检查](TypeChecking.md)。

---
#### 下一节 [类型检查](TypeChecking.md)