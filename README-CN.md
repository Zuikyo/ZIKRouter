# ZIKRouter

一个用于模块间路由，基于接口进行依赖注入的Router。包括view router和service router。

View router将UIKit中的所有界面跳转方式封装成一个统一的方法。

Service router用于模块寻找，通过protocol寻找对应的模块，并用protocol进行依赖注入和模块调用。

---

## Features

* 用protocol获取界面和模块
* 用protocol配置模块的参数，基于接口进行模块调用，避免了直接获取对应实例进行参数赋值的耦合
* 支持界面路由和任意模块的路由
* 支持UIKit里的所有界面跳转方式（push、present modally、present as popover、segue、show、showDetail、addChildViewController、addSubview）以及自定义的展示方式，封装成一个统一的方法
* 支持用一个方法执行界面回退，不必区分使用pop、dismiss、removeFromParentViewController、removeFromSuperview
* 支持storyboard，可以对从segue中跳转的界面执行依赖注入
* 完备的错误检查，可以检测界面跳转时的大部分问题
* 支持界面跳转过程中的AOP回调

## 面向接口

ZIKRouter是基于面向接口编程的思想进行设计的。调用者不必知道模块的具体类，只需要知道模块的接口，就可以获取到模块，并且进行依赖注入和方法调用。实现了模块功能和具体的类分离。

相对于URL router的方式，面向接口的方式更加安全，耦合程度更低，在重构时的效率也更高。

## 依赖注入

可以在Router中对模块进行自定义初始化配置，也就可以执行依赖注入。同时模块可以对外声明所需的依赖参数。

## 简单演示

### View Router

界面跳转的代码如下：

```
///editor模块的依赖声明
@protocol NoteEditorProtocol <NSObject>
@property (nonatomic, weak) id<ZIKEditorDelegate> delegate;
- (void)constructForCreatingNewNote;
- (void)constructForEditingNote:(ZIKNoteModel *)note;
@end

```

```

@implementation TestEditorViewController

- (void)showEditor {
    //跳转到编辑器界面；通过protocol获取对应的router类，再通过protocol注入依赖
    //App可以用Adapter把NoteEditorProtocol和真正的protocol进行匹配和转接
    [ZIKViewRouterForConfig(@protocol(NoteEditorProtocol))
	     performWithConfigure:^(ZIKViewRouteConfiguration<NoteEditorProtocol> *config) {
	         //路由配置
	         //跳转的源界面
	         config.source = self;
	         //设置跳转方式
	         config.routeType = ZIKViewRouteTypePush;
	         //Router内部负责用获取到的参数初始化editor模块
	         config.delegate = self;
	         [config constructForCreatingNewNote];
	         config.prepareForRoute = ^(id destination) {
	             //跳转前配置目的界面
	         };
	         config.routeCompletion = ^(id destination) {
	             //跳转结束处理
	         };
	         config.performerErrorHandler = ^(SEL routeAction, NSError * error) {
	             //跳转失败处理
	         };
	     }];
}

@end
```

### Service Router

任意模块获取和调用：

```
///time service的接口
@protocol ZIKTimeServiceInput <NSObject>
- (NSString *)currentTimeString;
@end
```

```
@interface TestServiceViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation TestServiceViewController

- (void)callTimeService {
   [ZIKServiceRouterForService(@protocol(ZIKTimeServiceInput))
         performWithConfigure:^(ZIKServiceRouteConfiguration *config) {
            config.prepareForRoute = ^(id<ZIKTimeServiceInput> destination) {
                //配置time service初始化需要的参数
            };
            config.routeCompletion = ^(id<ZIKTimeServiceInput> destination) {
                //获取到timeService，进行调用
                timeService = destination;
                NSString *timeString = [timeService currentTimeString];
                self.timeLabel.text = timeString;
            };
        }];
    
}

```

## 使用方法

### 为模块创建对应Router

```
//MasterViewRouter.h

//声明Master界面的protocol已经被注册，可以用于获取MasterViewRouter类
DeclareRoutableViewProtocol(MasterViewProtocol, MasterViewRouter)

@interface MasterViewRouter : ZIKViewRouter <ZIKViewRouterProtocol>

@end
```
```
//MasterViewRouter.m

//把MasterViewController和对应的Router子类进行注册，一个Router可以注册多个界面，一个界面也可以使用多个Router
RegisterRoutableView(MasterViewController, MasterViewRouter)

//注册MasterViewProtocol，可以动态获取到MasterViewRouter类
RegisterRoutableViewProtocol(MasterViewProtocol, MasterViewRouter)

@implementation MasterViewRouter

//实现ZIKRouter的接口
//返回需要获取的目的模块
- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MasterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"master"];
    return destination;
}

//在执行路由前配置模块
- (void)prepareDestination:(MasterViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    destination.tableView.backgroundColor = [UIColor lightGrayColor];
}

//配置完毕，检查是否配置正确
- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

//路由时的AOP回调
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    
}

@end
```

### 使用Router

```
//In some view controller

@implementation TestViewController

- (void)showMasterViewController {
	ZIKViewRouter *router;
	
	//可以直接使用ZIKTestPushViewRouter，也可以用ZIKViewRouterForView(@protocol(MasterViewProtocol))获取Router类
	//区别是用protocol获取时，就可以用protocol来配置目的界面
	router = [ZIKTestPushViewRouter
	          performWithConfigure:^(ZIKViewRouteConfiguration *config) {
	              config.source = self;
	              config.routeType = ZIKViewRouteTypePush;
	              config.animated = YES;
	              config.prepareForRoute = ^(UIViewController *destination) {
	              //界面显示前配置
	                  destination.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	              };
	              config.routeCompletion = ^(UIViewController *destination) {
	                  //界面显示完毕
	              };
	              config.performerErrorHandler = ^(SEL routeAction, NSError *error) {
	                  //界面显示失败
	              };
	          }];
	 self.router = router;
}

- (void)removeMasterViewController {	    
	//可以用removeRoute方法消除已经展示的界面
	[self.router removeRouteWithSuccessHandler:^{
	    //消除成功
	} performerErrorHandler:^(SEL routeAction, NSError *error) {
	    //消除失败
	}];
}
```

## Demo和工程实践

ZIKRouter一开始是为了实施VIPER架构模式而设计的，不过它也可以用于MVC，并没有限制。

当前项目的Demo里演示了用ZIKRouter执行各种路由的过程。如果想要查看ZIKRouter在VIPER项目中的应用，可以前往[ZIKViper](https://github.com/Zuikyo/ZIKViper)。

## Cocoapods

支持cocoapods：

```
pod "ZIKRouter"
```

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.