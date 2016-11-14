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

#import "ViewController.h"
#import "RefreshControl.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,weak) UITableView *tableView;
//1.定义一个成员变量,下拉刷新控件
@property (nonatomic,weak) RefreshControl *refreshControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //调用初始化方法
    [self setUpUI];
}

#pragma mark 初始化方法
- (void)setUpUI
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    //2.添加下拉刷新的视图
    RefreshControl *refreshControl = [[RefreshControl alloc] init];
    [self.tableView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    //3.給下拉控件添加执行事件
    [refreshControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
    
}

- (void)loadData
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //模拟耗时操作
        [NSThread sleepForTimeInterval:5];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //4.加载数据完成以后关闭刷新的动画
            [self.refreshControl endRefreshing];
        });
    });

}

#pragma mark - 数据源方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 16;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"leftCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd------%zd",indexPath.section,indexPath.row];
    return cell;
}




@end
