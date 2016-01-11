//
//  LeftMenuViewController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 15/12/2.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "LeftMenuViewController.h"
#import "KnowledgeNavigationController.h"
#import "HomeNavigationController.h"

@interface LeftMenuViewController ()

@end

@implementation LeftMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView setBackgroundColor:MENU_BACKGROUND_COLOR];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    //设置头部
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 141)];
    UIView *headerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 140, self.view.bounds.size.width, 1)];
    [headerLine setBackgroundColor:[UIColor grayColor]];
    [headerView addSubview:headerLine];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 40, 160, 60)];
    [imageView setImage:[UIImage imageNamed:@"aboutus_logo_icon"]];
    [headerView addSubview:imageView];
    self.tableView.tableHeaderView = headerView;
    //设置底部
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)];
    [footerView setBackgroundColor:[UIColor grayColor]];
    self.tableView.tableFooterView = footerView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identify = @"leftMenuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify];
    }
    
    NSArray *titles = @[@"关于米开",@"体温常识",@"消息推送"];
    NSArray *images = @[@"guanyumikai",@"tiwenxiaochangshi",@"set_about_icon"];
    [cell.contentView setBackgroundColor:MENU_BACKGROUND_COLOR];
    cell.textLabel.text = titles[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
    [cell.textLabel setTextColor:[UIColor colorWithRed:22/255.0 green:155/255.0 blue:213/255.0 alpha:1.0]];
    
    if (indexPath.row == 2) {
        BOOL isAllowedNotification = [[GlobalTool shared] isAllowedNotification]; //是否开启了推送通知
        UISwitch *notiSwitch = [[UISwitch alloc] init];
        [notiSwitch setUserInteractionEnabled:NO];
        if (isAllowedNotification) {
            [notiSwitch setOn:YES];
        } else {
            [notiSwitch setOn:NO];
        }
        notiSwitch.frame = CGRectMake(200 - 60, 10, 0, 0);
        [cell.contentView addSubview:notiSwitch];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    if (indexPath.row == 0) { //关于米开
        MainTabBarController *tabBarC = (MainTabBarController *)self.mm_drawerController.centerViewController;
        HomeNavigationController *homeNav = tabBarC.selectedViewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"AboutUsViewController"];
        [vc setHidesBottomBarWhenPushed:YES];
        [homeNav pushViewController:vc animated:YES];
        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    } else if (indexPath.row == 1) { //体温小常识
        MainTabBarController *tabBarC = (MainTabBarController *)self.mm_drawerController.centerViewController;
        HomeNavigationController *homeNav = tabBarC.selectedViewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"KnowledgeViewController"];
        [vc setHidesBottomBarWhenPushed:YES];
        [homeNav pushViewController:vc animated:YES];
        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    } else if (indexPath.row == 2) { //跳转到设置
        NSURL *url = [NSURL URLWithString:@"prefs:root=prefs:root=NOTIFICATIONS_ID"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
