# FAQ

### 是否需要用公共库存放所有的 protocol？

用一个公共库管理所有的 protocol 是最直接的方式，但是维护起来可能会很麻烦，而且也可能会导致引入许多没有使用到的 protocol。

ZIKRouter 所使用的 protocol 都经过路由声明，而且允许你使用多个 protocol 指向相同的模块，因此 protocol 可以分散管理，不必全都放在一个公共库里管理。

### 如何知道哪些 protocol 可以用于路由？

只需要查找路由声明的地方即可。搜索头文件中的

`extension RoutableView where Protocol ==`

`extension RoutableViewModule where Protocol ==`

`extension RoutableService where Protocol ==`

`extension RoutableServiceModule where Protocol ==`

`@protocol ... <ZIKViewRoutable>`

`@protocol ... <ZIKViewModuleRoutable>`

`@protocol ... <ZIKServiceRoutable>`

`@protocol ... <ZIKServiceModuleRoutable>`

等声明代码，即可找到所有的路由声明。也可以通过 runtime 方法，动态打印出所有声明的路由。

如果你使用的是 swift，则 Xcode 会自动列出所有已声明的路由：

![Xcode Auto Completion](../Resources/route-auto-completion.png)

当使用 protocol 进行路由时，会进行编译检查，所以不用担心使用了错误的 protocol。

### 什么是 required protocol 和 provided protocol？

`required protocol`是使用者使用模块时用到的接口。`provided protocol`是模块真正提供的接口。同一个`provided protocol`可以有多个相对应的`required protocol`。

### 为什么要区分 required protocol 和 provided protocol？

* 模块的使用者和模块本身从代码实现上是隔离的，分开接口后，两者就可以彻底解耦
* required protocol 对应的模块可以随时被替换，只需要由模块的使用者（app）对接好 required protocol 和 provided protocol 即可
* 模块声明自己用到的 required protocol，就能明确所用到的依赖，在测试也更容易提供 mock 依赖，单独测试，不必引入其他模块

### required protocol 是否可以和 provided protocol 不同？

只要接口提供的功能相同即可，required protocol 中的接口可以和 provided protocol 中的接口有不同的名称。可以用 category、extension、proxy、subclass 等技术为模块添加 required protocol。

一般 required protocol 和 provided protocol 只是名字不同，接口完全一样，或者 required protocol 是 provided protocol 的子集。只有在出现了模块替换时，才会出现两个 protocol 的接口出现差别的情况。

### adapter 的作用是什么？

ZIKViewRouteAdapter 和 ZIKServiceRouteAdapter 只是用于为其他 router 注册 required protocol。仍然需要为模块实现 required protocol。

### 在哪里进行模块适配？

模块适配的工作由模块的使用者 app context 进行。模块不知道适配层的存在。可以集中在一个文件中编写模块适配的代码，也可以分散在多个文件中。

### ZIKRouter 和 ZRouter 有什么不同？

ZRouter 是对 ZIKRouter 的封装，为 swift 提供了更 swifty 的语法，也对纯 swift class 和 swift protocol 进行了支持。

### ZIKRouter 是否支持 swift 值类型？

不支持值类型，只支持 class 类型。值类型不应该用在跨模块的交互中，如果你实在想要管理值类型，可以通过 protocol 中的接口提供值类型。

### 如何同时声明 protocol 是 UIViewController 类型？

在 swift 中，可以同时声明模块的类型和 protocol：

```swift
typealias ViewControllerInput = UIViewController & ControllerInput

extension RoutableView where Protocol == ViewControllerInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

当你用 ViewControllerInput 获取模块时，获取到的就是一个遵守`ControllerInput`的`UIViewController`。

类似的，也可以声明为 UIView，或者其他自定义类型。

在 Objective-C 中没有 swift 这样严格的类型安全机制，也就无法实现这种声明。

### 在执行界面跳转之后，如何再使用 destination？

router 实例在执行路由后，只持有对 destination 的弱引用。如果你还想再使用 destination，需要自己持有 destination：

```swift
class TestViewController: UIViewController {
	var mySubview: MySubviewInput?
	
	func addMySubview() {
        Router.perform(
        to: RoutableView<MySubviewInput>(),
        path: .addAsSubview(from: self.view),
        configuring: { (config, _) in
            config.successHandler = { destination in
                self.mySubview = destination
            }
    	 })
	}
}
```

<details><summary>Objective-C Sample</summary>
  
```objectivec
@interface TestViewController: UIViewController
@property (nonatomic, strong) UIView<MySubviewInput> *mySubview;
@end
@implementation TestViewController

- (void)addMySubview {
    [ZIKRouterToView(MySubviewInput) performPath:ZIKViewRoutePath.addAsSubviewFrom(self.view) configuring:^(ZIKViewRouteConfiguration *config) {
        config.successHandler = ^(id<MySubviewInput> destination) {
            self.mySubview = destination;
        };
    }];
}

@end
```

</details>

### 如何处理路由错误？

路由出现错误一般都是在开发阶段，原因有：

* 界面跳转出现 UIKit 错误，例如在没有 navigationController 的界面上执行 push 操作
* 获取模块时传递了错误的参数，模块禁止了本次调用

这些问题应该在开发阶段就解决。可以在`globalErrorHandler`中记录错误。

### 如何处理路由降级？

按照 URL router 的思维，你可能想要处理模块不存在时的路由操作，降级到某个默认界面。

由于编译阶段就能确保不会使用未声明的 protocol，因此 ZIKRouter 没有直接提供路由下沉的接口。你只有在用字符串 identifier 获取模块时，才会出现模块不存在的情况。如果模块不存在，就使用一个默认的 router 进行跳转。