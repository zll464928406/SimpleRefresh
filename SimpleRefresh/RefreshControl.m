/*
 如何使用
 - 1.定义一个成员变量
 //下拉刷新控件
 @property (nonatomic,weak) RefreshControl *refreshControl;
 - 2.把控件添加到视图中,并设置全局变量
 //添加下拉刷新的视图
 RefreshControl *refreshControl = [[RefreshControl alloc] init];
 [self.tableView addSubview:refreshControl];
 self.refreshControl = refreshControl;
 - 3.給下拉控件添加执行事件
 [refreshControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
 - 4.加载数据完成以后关闭刷新的动画
 [self.refreshControl endRefreshing];
 */

#import "RefreshControl.h"
#import <Masonry.h>
//定义刷新控件的刷新状态
typedef enum : NSUInteger {
    RefreshControlStateNormal = 1,
    RefreshControlStatePulling = 2,
    RefreshControlStateRefreshing = 3,
} RefreshControlState;
//刷新控件的高度
static CGFloat RefreshH = 50;

@interface RefreshControl ()
@property (nonatomic,weak) UIScrollView *scrollView;
@property (nonatomic,assign) RefreshControlState refreshState;
//添加三个控件
@property (nonatomic,weak) UIImageView *imageView;
@property (nonatomic,weak) UILabel *label;
@property (nonatomic,weak) UIActivityIndicatorView *indicatorView;
@end
@implementation RefreshControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI];
    }
    return self;
}

#pragma mark - 初始化方法
- (void)setUpUI
{
    CGFloat ScreenW = [UIScreen mainScreen].bounds.size.width;
    self.frame = CGRectMake(0, -RefreshH, ScreenW, RefreshH);
    //创建控件
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableview_pull_refresh"]];
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:14];
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.color = [UIColor darkGrayColor];
    //设置全局变量
    self.imageView = imageView;
    self.label = label;
    self.indicatorView = indicatorView;
    self.refreshState = RefreshControlStateNormal;
    //添加控件
    [self addSubview:imageView];
    [self addSubview:label];
    [self addSubview:indicatorView];
    //设置自动布局
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self).offset(-35);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(imageView.mas_right);
    }];
    [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self).offset(-35);
    }];
}

#pragma mark - 将要移动到父视图的时候会执行当前的方法
-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        //记录当前的父视图
        self.scrollView = (UIScrollView *)newSuperview;
        //添加观察者
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
    }
    
}
#pragma mark - 接收变化的方法
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSLog(@"%.2f",self.scrollView.contentOffset.y);
    //如果小于某个值就代表刷新的视图彻底的漏出来了
    CGFloat contentInsetTop = self.scrollView.contentInset.top;
    CGFloat conditionValue = -contentInsetTop - RefreshH;
    // idDragging 代表用户是否在拖动
    if (self.scrollView.isDragging) {
        if (self.refreshState==RefreshControlStateNormal && self.scrollView.contentOffset.y<=conditionValue) {
            //进入到松手就刷新的状态
            self.refreshState = RefreshControlStatePulling;
            self.scrollView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0);
        }else if(self.refreshState==RefreshControlStatePulling && self.scrollView.contentOffset.y>conditionValue){
            //进入到默认状态
            self.refreshState = RefreshControlStateNormal;
        }
    }else{
        // 用户没有拖动，松开手
        if (self.refreshState == RefreshControlStatePulling) {
            self.refreshState = RefreshControlStateRefreshing;
        }
    }
    
}
#pragma mark - 重写refreshState的set方法来完成设定
-(void)setRefreshState:(RefreshControlState)refreshState
{
    //先取出当前的值,也就是赋值前的旧值
    RefreshControlState oldValue = _refreshState;
    _refreshState = refreshState;
    //判断条件
    switch (_refreshState) {
        case RefreshControlStatePulling:
        {
            [UIView animateWithDuration:0.25 animations:^{
                self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, M_PI);
            }];
            self.label.text = @"松开刷新数据";
        }
            break;
        case RefreshControlStateNormal:
        {
            [UIView animateWithDuration:0.25 animations:^{
                self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, M_PI);
            }];
            // 进入到默认状态应该将菊花转停止掉
            [self.indicatorView stopAnimating];
            self.imageView.hidden = false;
            self.label.text = @"上拉刷新数据";
            // 判断如果之前是刷新状态的话,把位置移动过去
            if (oldValue == RefreshControlStateRefreshing) {
                [UIView animateWithDuration:0.25 animations:^{
                    self.scrollView.frame = [UIScreen mainScreen].bounds;
                }];
            }
        }
            break;
        case RefreshControlStateRefreshing:
        {
            //把箭头隐藏，显示菊花转
            self.imageView.hidden = true;
            [self.indicatorView startAnimating];
            self.label.text = @"正在刷新数据";
            //让其转动的时候停留在顶端
            [UIView animateWithDuration:0.25 animations:^{
                CGRect rect = self.scrollView.frame;
                rect.origin.y = rect.origin.y+RefreshH;
                self.scrollView.frame = rect;
            }];
            //发送事件，其实就是调用addTarget里面的方法
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
            break;
    }
}
#pragma mark - 结束刷新的方法
- (void)endRefreshing
{
    NSLog(@"刷新结束---------");
    self.refreshState = RefreshControlStateNormal;
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.scrollView.contentOffset = CGPointMake(0, 0);
}

#pragma mark - 视图将要销毁的执行方法
-(void)dealloc
{
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}


@end
