//
//  HomeViewController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 15/11/18.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "HomeViewController.h"
#import "HomeNavigationController.h"
#import "HttpTool.h"
#import "MessageViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerBarButtonItem.h"
#import "UseBeanCheckViewController.h"
#import "UseStickCheckViewController.h"
#import "AddMedicalRecordViewController.h"

@interface HomeViewController ()<UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource,JMHoledViewDelegate>{
    NSUserDefaults *userDefaults;
}
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

//@property (nonatomic,assign)NSInteger myStyle;
/**
 *	体温棒测温的界面，三个可以滑动的页面
 */
@property (strong, nonatomic) UIPageControl *pageControl;
@property (nonatomic,strong)UIScrollView *scrollView;

/**
 *	温豆测温的界面，是一个UIView
 */
@property (nonatomic,strong) UseBeanCheckViewController *beanView;
/**
 *	体温棒测温界面
 */
@property (nonatomic,strong) UseStickCheckViewController *stickView;
/**
 *	没有选择任何设备的页面
 */
@property(nonatomic,strong)UIView *noDeviceView;
/**
 *	设备列表的tableView
 */
@property(nonatomic,strong)UITableView *deviceListTV;
/**
 *	导航条上用于显示按钮的view
 */
@property (weak, nonatomic) IBOutlet UIView *NavItemView;

@property (weak, nonatomic) IBOutlet UIButton *selectDeviceBtn;//导航条上添加一个选择设备的button
@property (weak, nonatomic) IBOutlet UIImageView *pullImageView;//选择设备按钮旁边下拉箭头

- (IBAction)onClickOnceCheck;

@property (nonatomic,strong) JMHoledView *holeView;
@end
@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:UIVIEW_BACKGROUND_COLOR];
    //设置Nav
    [self setupNav];

    self.NavItemView.backgroundColor = NAVIGATIONBAR_BACKGROUND_COLOR;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectDevice)];
    [self.NavItemView addGestureRecognizer:recognizer];
    userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger myStyle = [userDefaults integerForKey:@"myInteger"];
    if (myStyle == 1) {
        [self setUpStickScrollView];
    }else if (myStyle == 2){
        [self SetUpBeanView];
    }else if (myStyle == 0){
        [self setUpNoDeviceView];
    }
    
    /**
     设备列表
     */
    
    self.deviceListTV = [[UITableView alloc] initWithFrame:CGRectMake(self.view.center.x - 100, -240, 200, 158) style:UITableViewStylePlain];
    self.deviceListTV.scrollEnabled = NO;
    self.deviceListTV.delegate = self;
    self.deviceListTV.dataSource = self;
    self.deviceListTV.layer.borderWidth = 1.0f;
    self.deviceListTV.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.view addSubview:self.deviceListTV];
}


- (IBAction)selectDevice {
    [self.view bringSubviewToFront:self.deviceListTV];
    self.pullImageView.center = CGPointMake(self.pullImageView.center.x, self.pullImageView.center.y);
    if (self.deviceListTV.frame.origin.y == 64) {
        //收起
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.deviceListTV.frame = CGRectMake(self.view.center.x - 100, -240, 200, 158);
            self.pullImageView.transform = CGAffineTransformMakeRotation(0);
        } completion:^(BOOL finished) {
            
        }];
    }else if (self.deviceListTV.frame.origin.y == -240){
        //展开
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.deviceListTV.frame = CGRectMake(self.view.center.x - 100, 64, 200, 158);
            self.pullImageView.transform = CGAffineTransformMakeRotation(M_PI);
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)setUpStickScrollView{
    int myInteger = 1;
    userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:myInteger forKey:@"myInteger"];
    [userDefaults synchronize];
    self.NavItemView.backgroundColor = [UIColor clearColor];

    [self.stickView.view removeFromSuperview];
    [self.noDeviceView removeFromSuperview];
    [self.beanView.view removeFromSuperview];
    
    
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    self.stickView = [board instantiateViewControllerWithIdentifier:@"UseStickCheckViewController"];
    self.stickView.view.frame =  CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 49);
    self.stickView.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.stickView.view];
    
    [self.selectDeviceBtn setTitle:@"米开体温棒" forState:UIControlStateNormal];
    
    /**
     *  SoulJa 2015-01-18
     *  添加指示层
     */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger isInitGuideSelectDevice = [defaults integerForKey:@"isInitGuideSelectDevice"];
    if (isInitGuideSelectDevice == 0) {
        self.holeView = [[JMHoledView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.holeView.holeViewDelegate = self;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((kScreen_Width - 240)/2, 260 + 60 + 64, 240, 140)];
        [imageView setImage:[UIImage imageNamed:@"stickStartCheck"]];
        [self.holeView addHCustomView:imageView onRect:imageView.frame];
        UITapGestureRecognizer *recongnizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHoleView)];
        [self.holeView addGestureRecognizer:recongnizer];
        
        [self.holeView addHoleRoundedRectOnRect:CGRectMake((kScreen_Width - 80)/2, 260 + 55 + 64, 80, 80) withCornerRadius:40];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(kScreen_Width - 100 - 10 , kScreen_Height - 60, 100, 40)];
        [btn setTitle:@"不再提示" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onClickNoGuide) forControlEvents:UIControlEventTouchUpInside];
        [self.holeView addSubview:btn];
        
        UIImageView *guideSwipeRight = [[UIImageView alloc] init];
        guideSwipeRight.image = [UIImage imageNamed:@"swiftRight"];
        guideSwipeRight.frame = CGRectMake((kScreen_Width - 200)/2, 44, 200, 100);
        [self.holeView addSubview:guideSwipeRight];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:self.holeView];
    }
    
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [avSession requestRecordPermission:^(BOOL available) {
            if(!available) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (myInteger == 1) {
                        [SVProgressHUD showInfoWithStatus:@"请在“设置-隐私-麦克风”选项中允许体温棒访问您的麦克风"];
                    }
                });
                return;
            }
        }];
    }

}

- (void)setUpNoDeviceView{
    self.NavItemView.backgroundColor = [UIColor clearColor];

    self.noDeviceView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.noDeviceView.backgroundColor = UIVIEW_BACKGROUND_COLOR;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2, 64 + 50, 200, 200)];
    [imageView setImage:[UIImage imageNamed:@"yuanquan"]];
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake((200 - 100) / 2, 50, 100, 70)];
    [logoImageView setImage:[UIImage imageNamed:@"start_logo"]];
    [imageView addSubview:logoImageView];
    [self.noDeviceView addSubview:imageView];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    btn.frame = CGRectMake((self.view.bounds.size.width - 120)/2, CGRectGetMaxY(imageView.frame) + 50, 120, 120);
    
    [btn setBackgroundImage:[UIImage imageNamed:@"anniu"] forState:UIControlStateNormal];
    
    [btn addTarget:self action:@selector(onClickSelect) forControlEvents:UIControlEventTouchUpInside];
    
    [self.noDeviceView addSubview:btn];
    
    [self.view addSubview:self.noDeviceView];
    [self.selectDeviceBtn setTitle:@"米开设备" forState:UIControlStateNormal];
    
    /**
     *  SoulJa 2015-01-18
     *  添加指示层
     */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger isInitGuideSelectDevice = [defaults integerForKey:@"isInitGuideSelectDevice"];
    if (isInitGuideSelectDevice == 0) {
        self.holeView = [[JMHoledView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.holeView.holeViewDelegate = self;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((kScreen_Width - 200)/2 + 60, 35, 200, 100)];
        [imageView setImage:[UIImage imageNamed:@"selectDevice"]];
        [self.holeView addHCustomView:imageView onRect:imageView.frame];
        UITapGestureRecognizer *recongnizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHoleView)];
        [self.holeView addGestureRecognizer:recongnizer];
        
        [self.holeView addHoleRoundedRectOnRect:CGRectMake((kScreen_Width - 120) / 2, 20, 120, 44) withCornerRadius:8];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(kScreen_Width - 100 - 10 , kScreen_Height - 60, 100, 40)];
        [btn setTitle:@"不再提示" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onClickNoGuide) forControlEvents:UIControlEventTouchUpInside];
        [self.holeView addSubview:btn];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:self.holeView];
    }
}

#pragma mark - 点击HoleView
- (void)tapHoleView {
    [self.holeView removeFromSuperview];
}

#pragma mark - 点击“不在提示”
- (void)onClickNoGuide {
    [self.holeView removeFromSuperview];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:1 forKey:@"isInitGuideSelectDevice"];
    [defaults synchronize];
}

- (void)onClickSelect {
    [SVProgressHUD showInfoWithStatus:@"请选择设备!"];
}

- (void)SetUpBeanView{
    int myInteger = 2;
    //将数据全部存储到NSUserDefaults中
    userDefaults = [NSUserDefaults standardUserDefaults];
    //存储时，除NSNumber类型使用对应的类型意外，其他的都是使用setObject:forKey:
    [userDefaults setInteger:myInteger forKey:@"myInteger"];
    
    //这里建议同步存储到磁盘中，但是不是必须的
    [userDefaults synchronize];
    NSLog(@"设备设置为温豆");
    
    self.NavItemView.backgroundColor = [UIColor clearColor];

    [self.scrollView removeFromSuperview];
    [self.pageControl removeFromSuperview];
    [self.noDeviceView removeFromSuperview];
    
    [self.beanView.view removeFromSuperview];
    
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    self.beanView = [board instantiateViewControllerWithIdentifier:@"UseBeanCheckViewController"];
    self.beanView.view.frame =  CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 49);
    self.beanView.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.beanView.view];
    
    [self.selectDeviceBtn setTitle:@"米开温豆" forState:UIControlStateNormal];

    /**
     *  SoulJa 2015-01-18
     *  添加指示层
     */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger isInitGuideSelectDevice = [defaults integerForKey:@"isInitGuideSelectDevice"];
    if (isInitGuideSelectDevice == 0) {
        self.holeView = [[JMHoledView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.holeView.holeViewDelegate = self;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((kScreen_Width - 200)/2 + 20, 240 + 10, 250, 200)];
        [imageView setImage:[UIImage imageNamed:@"stickStartCheck"]];
        [self.holeView addHCustomView:imageView onRect:imageView.frame];
        UITapGestureRecognizer *recongnizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHoleView)];
        [self.holeView addGestureRecognizer:recongnizer];
        
        UIImageView *distanceView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kScreen_Height - 150, 250, 80)];
        [distanceView setImage:[UIImage imageNamed:@"beanDistance"]];
        [self.holeView addHCustomView:distanceView onRect:distanceView.frame];
        
        CGFloat rectX = 0;
        CGFloat rectY = 180 + 64;
        CGFloat rectW = 70;
        CGFloat rectH = 70;
        if ([[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6S Plus"] || [[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6 Plus"]) {
            rectX = 240;
        } else if ([[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6"] || [[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6S"]) {
            rectX = 211;
            rectY = 233;
        } else {
            rectX = 200;
        }
        [self.holeView addHoleRoundedRectOnRect:CGRectMake(rectX, rectY, rectW, rectH) withCornerRadius:rectW / 2];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(kScreen_Width - 100 - 10 , kScreen_Height - 60, 100, 40)];
        [btn setTitle:@"不再提示" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onClickNoGuide) forControlEvents:UIControlEventTouchUpInside];
        [self.holeView addSubview:btn];
        
        UIImageView *guideMaxImageView = [[UIImageView alloc] init];
        guideMaxImageView.image = [UIImage imageNamed:@"clickMax"];
        guideMaxImageView.frame = CGRectMake((kScreen_Width - 200)/2, 20, 200, 130);
        [self.holeView addSubview:guideMaxImageView];
        
        CGFloat guideMaxX = 0;
        if ([[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6S Plus"] || [[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6 Plus"]) {
            guideMaxX = 200;
        } else if ([[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6"] || [[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 6S"]) {
            guideMaxX = 160;
        } else {
            guideMaxX = 150;
        }
        [self.holeView addHoleRoundedRectOnRect:CGRectMake(guideMaxX, 155, 190, 35) withCornerRadius:8];
        
        
        
        [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:self.holeView];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
    
    /*监听三分钟测温完成*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishCheck:) name:@"FinishStickOnceCheck" object:nil];
    
    //监听调节音量
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    /*监听拔出耳机*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FinishStickOnceCheck" object:nil];

}

- (void)finishCheck:(NSNotification *)notification {
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    AddMedicalRecordViewController *vc = [board instantiateViewControllerWithIdentifier:@"AddMedicalRecordViewController"];
    [self presentViewController:vc animated:YES completion:nil];
}

/**
 *  设置Nav
 */
- (void)setupNav {
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
    
    MMDrawerBarButtonItem * rightDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(rightDrawerButtonPress:)];
    [self.navigationItem setRightBarButtonItem:rightDrawerButton animated:YES];
    
}

#pragma mark - Button Handlers
-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    [self.mm_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
}

-(void)rightDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
    [self.mm_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
}


#pragma mark -- 顶部下拉列表的tabelView的代理方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    // 此处可以写成自定义的cell,定义label 和 imageView
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.selected = NO;
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = @"               米开体温棒";
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"stick"]];
        imageView.frame = CGRectMake(10, 10, 60, 60);
        //放在cell的内容视图上显示
        [cell.contentView addSubview:imageView];
    }else if (indexPath.section == 0 && indexPath.row == 1){
        cell.textLabel.text = @"               米开温豆";
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bean"]];
        imageView.frame = CGRectMake(10, 10, 60, 60);
        //放在cell的内容视图上显示
        [cell.contentView addSubview:imageView];
    }
    return cell;
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self setUpStickScrollView];
        [self selectDevice];
    }else if (indexPath.section == 0 && indexPath.row == 1){
        [self SetUpBeanView];
        [self selectDevice];
    }
}

/** 这是原来的页面里的方法
 *  点击一次测温按钮
 */
- (IBAction)onClickOnceCheck {
    if ([self isHeadsetPluggedIn]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"UseHardwareCheckNavigationController"];
        [self presentViewController:vc animated:NO completion:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:@"请将体温棒连接手机！"];
    }
}
/**
 *	这是新的页面里的方法
 */
- (void)clickToOnceCheck{
    if ([self isHeadsetPluggedIn]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"UseHardwareCheckNavigationController"];
        [self presentViewController:vc animated:NO completion:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:@"请将体温棒连接手机！"];
    }
}

/**
 *	点击跳转温豆的测温页面
 */
- (void)clickToBeanView{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"UseBeanCheckViewController"];
//    [self presentViewController:vc animated:NO completion:nil];
    [self.navigationController pushViewController:vc animated:YES];
}
//轻拍响应的方法
- (void)tapGestureRecognizer:(UITapGestureRecognizer *)sender{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Third" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"UserNavigationController"];
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

/**
 *  判断耳机是否插入
 */
- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}


/**
 *  2015-09-23 SoulJa
 *  监听音量调节
 */
- (void)volumeChanged:(NSNotification *)notification {
    CGFloat volume = [notification.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (volume < 1.0) {
//        [SVProgressHUD showErrorWithStatus:@"请将音量调到最大！"];
    }
}

/**
 *  判断耳机是否被拔出
 */
-(void)routeChange:(NSNotification *)notification {
//    NSDictionary *dic=notification.userInfo;
//    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
//    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
//    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
//        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
//        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
//        //原设备为耳机则暂停
//        if ([portDescription.portType isEqualToString:@"Headphones"]) {
//            [SVProgressHUD showErrorWithStatus:@"体温棒已拔出，请重新测温！"];
//            return;
//        }
//    }
}


#pragma mark - JMHoleViewDelegate
- (void)holedView:(JMHoledView *)holedView didSelectHoleAtIndex:(NSUInteger)index {
    NSLog(@"%s %ld", __PRETTY_FUNCTION__,(long)index);
}
@end
