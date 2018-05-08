# Routable

为模块创建router，以及注册protocol时，需要对destination类和protocol进行`可路由`的声明。声明时只需要为指定的类添加对应的routable扩展。

## Routable destination

在view router中，为destination添加`ZIKRoutableView`扩展：

```swift
extension EditorViewController: ZIKRoutableView {

}
```

<details><summary>Objecive-C示例</summary>

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

声明routable destination是为了支持storyboard，如果在执行segue时检测到view controller遵守`ZIKRoutableView`，就会去搜索view controller对应的view router进行依赖注入。

## Routable protocol

当你使用一个protocol来获取router时，protocol必须是可路由的。

针对不同程度的动态需求，提供了不同程度的动态方案。在Swift上和Objective-C上，routable声明有不同的实现方式。

### Routable in Swift

Swift示例：

在Swift中，用结构体的泛型值来传递protocol：

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
`RoutableView`默认初始化方法是私有的，只有声明了的protocol才能访问它的初始化方法，进行实例化操作`RoutableView<SwiftEditorViewInput>()`：

```swift
class TestViewController: UIViewController {
    func showEditor() {
        Router.perform(
            to: RoutableView<SwiftEditorViewInput>(),
            from: self,
            routeType: .push
            )
    }
}
```

因此当你传入一个错误的protocol时，例如`RoutableView<UnroutableProtocol>()`，会产生编译错误。

初始化方法 `init(declaredProtocol: Protocol.Type)` 只是用来消除 swift 的编译检查 `initializer for struct 'xxx' must use "self.init(...)" or "self = ..." because it is not in module xxx`. 参考 [restrict-cross-module-struct-initializers](https://github.com/apple/swift-evolution/blob/master/proposals/0189-restrict-cross-module-struct-initializers.md)。不要在除了 extension 之外的地方使用此初始化方法。

### Routable in Objective-C

Swift语言是静态的，本身就是类型安全的，但是Objective-C上就很难保证这些安全了。因此在Objective-C上主要是依靠动态检查来保证路由的可靠和安全。

#### `ZIKViewRoutable`和`ZIKServiceRoutable`

当声明一个protocol可用于界面路由时，需要让protocol继承自`ZIKViewRoutable`。

```
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *editorTitle;
@end
```

类似的，如果是service protocol，则继承自`ZIKServiceRoutable`。

#### `ZIKViewModuleRoutable`和`ZIKServiceModuleRoutable`

当声明一个protocol可用于界面模块路由时，需要让protocol继承自`ZIKViewModuleRoutable`。

```
@protocol EditorModuleInput <ZIKViewModuleRoutable>
@property (nonatomic, copy) NSString *editorTitle;
@end
```

类似的，如果是service module protocol，则继承自`ZIKServiceModuleRoutable`。

#### 动态检查

在app启动时，ZIKRouter会在debug模式下，用OC runtime检查所有继承自`ZIKViewRoutable`、`ZIKServiceRoutable `、`ZIKViewModuleRoutable`、`ZIKServiceModuleRoutable`的protocol，确定这些protocol都已经和某个router注册，并且router中注册的destination和defaultConfiguration都遵守对应的protocol。

继承自`ZIKViewRoutable`的objc protocol，在Swift中将会自动声明为routable，不需要再按照Swift的方式重复声明。

对于纯Swift类型，ZIKRouter也能通过runtime检查对应的类型是否遵守对应的纯Swift的protocol。

关于类型检查的详细内容，请查看 [Type Checking](TypeChecking.md)。