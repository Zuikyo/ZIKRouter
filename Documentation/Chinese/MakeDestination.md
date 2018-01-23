# 获取模块

如果不想执行路由，只是想获取模块，可以使用`makeDestination`方法。在获取模块时，可以在preparation block里进行依赖注入。

Swift示例：

```swift
///time service的接口
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        //获取TimeServiceInput对应的模块
        let timeService = Router.makeDestination(
            to: RoutableService<TimeServiceInput>(),
            preparation: { destination in
            //配置service
        })
        //调用service
        timeLabel.text = timeService.currentTimeString()
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
///time service的接口
@protocol TimeServiceInput <ZIKServiceRoutable>
- (NSString *)currentTimeString;
@end
```

```objectivec
@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation TestViewController

- (void)callTimeService {
   //用protocol获取对应的模块
   id<TimeServiceInput> timeService = [ZIKServiceRouterToService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```

</details>