//
//  MainTabBarController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 15/11/18.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "MainTabBarController.h"
#import "HomeNavigationController.h"
#import "HomeViewController.h"
#import "MedicalRecordNavigationController.h"
#import "MedicalRecordViewController.h"
#import "LeftMenuViewController.h"
#import "DoctorNavigationController.h"
#import "DoctorViewController.h"
#import "MapNavigationController.h"
#import "MapViewController.h"
#import <CoreLocation/CoreLocation.h>


@interface MainTabBarController () <CLLocationManagerDelegate,UIAlertViewDelegate>
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLGeocoder *geocoder;


@end
@implementation MainTabBarController
+ (void)initialize {
    //判断是否有网络
    BOOL isConnectInternet = [[HttpTool shared] isConnectInternet];
    if (isConnectInternet) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /*验证登陆*/
            [[HttpTool shared] validLogin];
        });
    } else {
        return;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.tabBar.bounds];
    [backgroundView setBackgroundColor:TABBAR_BACKGROUND_COLOR];
    [self.tabBar insertSubview:backgroundView atIndex:0];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor redColor]} forState:UIControlStateSelected];
    
    //地理定位
    _locationManager = [[CLLocationManager alloc] init];
    
    if (![CLLocationManager locationServicesEnabled]) { //不允许地理定位
        [[GlobalTool shared] setCity:@""];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [_locationManager requestWhenInUseAuthorization];
    } else if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedWhenInUse) {
        //设置代理
        _locationManager.delegate=self;
        //设置定位精度
        _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        //定位频率,每隔多少米定位一次
        CLLocationDistance distance=10.0;//十米定位一次
        _locationManager.distanceFilter=distance;
        //启动跟踪定位
        [_locationManager startUpdatingLocation];
    } else {
        [[GlobalTool shared] setCity:@""];
    }
    
    
    //加载Home
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    HomeNavigationController *homeNav = [storyboard instantiateViewControllerWithIdentifier:@"HomeNavigationController"];
    
    
    //加载病历
    MedicalRecordNavigationController *medicalRecordNav = [storyboard instantiateViewControllerWithIdentifier:@"MedicalRecordNavigationController"];
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"记录" image:[[UIImage imageNamed:@"jilu"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:@"jiluxuanzhong"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    medicalRecordNav.tabBarItem = tabBarItem;
    
    //加载医生
    DoctorViewController *doctorVc = [[DoctorViewController alloc] init];
    DoctorNavigationController *doctorNav = [[DoctorNavigationController alloc] initWithRootViewController:doctorVc];
    
    //加载地图
    MapViewController *mapVc = [[MapViewController alloc] init];
    MapNavigationController *mapNav = [[MapNavigationController alloc] initWithRootViewController:mapVc];
    
    self.viewControllers = @[homeNav,medicalRecordNav,doctorNav,mapNav];
            self.selectedViewController = homeNav;
    
    //检查更新
    [[HttpTool shared] getVersion];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getVersionSuccessNotification:) name:@"GetVersionSuccessNotification" object:nil];
}

- (void)getVersionSuccessNotification:(NSNotification *)note {
    int NoNeedUpdate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NoNeedUpdate"] intValue];
    if ([[HttpTool shared] isConnectInternet] && NoNeedUpdate==0) {
        NSString *currentVersion = VERSION;
        NSDictionary *versionInfoDict = note.userInfo;
        if ([versionInfoDict[@"status"] isEqual:@0]) {
            return;
        } else {
            NSDictionary *data = [versionInfoDict objectForKey:@"data"];
            if (![currentVersion isEqualToString:[NSString stringWithFormat:@"%@",data[@"version"]]]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@",data[@"title"]] message:[NSString stringWithFormat:@"%@",data[@"message"]] delegate:self cancelButtonTitle:nil otherButtonTitles:@"前往更新",@"忽略此次更新", nil];
                [alertView show];
            } else {
                return;
            }
        }
        
    } else {
        return;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GetVersionSuccessNotification" object:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations  {
    CLLocation *location=[locations firstObject];//取出第一个位置
    _geocoder = [[CLGeocoder alloc] init];
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark = [placemarks firstObject];
        [[GlobalTool shared] setCity:[placemark.addressDictionary objectForKey:@"City"]];
    }];
    CLLocationCoordinate2D coordinate = location.coordinate;
    [[GlobalTool shared] setLatitude:coordinate.latitude];
    [[GlobalTool shared] setLongitude:coordinate.longitude];
    
    //如果不需要实时定位，使用完即使关闭定位服务
    [_locationManager stopUpdatingLocation];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/cn/app/ti-wen-bang/id993497682?l=en&mt=8"]];
    } else if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"NoNeedUpdate"];
        return;
    }
}



- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
