//
//  RightMenuViewController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 15/12/2.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "RightMenuViewController.h"
#import "UserNavigationController.h"
#import "UserUpdateViewController.h"
#import "MessageViewController.h"
#import "MessageNavigationController.h"

@interface RightMenuViewController ()
@property (nonatomic,strong) UIImageView *iconImageView;
@property (nonatomic,strong) UILabel *nicknameLabel;
@end

@implementation RightMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView setBackgroundColor:MENU_BACKGROUND_COLOR];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //设置头部
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 140)];
    //头像
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 40, 60, 60)];
    imageView.layer.cornerRadius = 30.0f;
    imageView.clipsToBounds = YES;
        [headerView addSubview:imageView];
    [imageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageView)];
    [imageView addGestureRecognizer:recognizer];
    self.iconImageView = imageView;
    //昵称
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(90, 50, 100, 40);
    [label setTextColor:[UIColor whiteColor]];
    [headerView addSubview:label];
    self.nicknameLabel = label;
    
    self.tableView.tableHeaderView = headerView;
    
    //尾部
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 140)];
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    logoutBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    logoutBtn.frame = CGRectMake(10, 50, 180, 40);
    logoutBtn.layer.borderWidth = 1.0f;
    logoutBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    logoutBtn.layer.cornerRadius = 8.0f;
    [logoutBtn setTitle:@"退出登录" forState:UIControlStateNormal];
    [logoutBtn addTarget:self action:@selector(onClickLogout) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:logoutBtn];
    self.tableView.tableFooterView = footerView;
}

/**
 *  退出登录
 */
- (void)onClickLogout {
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    [[DatabaseTool shared] emptyDataBase];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"First" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self presentViewController:vc animated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //获取默认成员头像
    if ([[DatabaseTool shared] getDefaultMember]) {
        self.nicknameLabel.text = [[[DatabaseTool shared] getDefaultMember] objectForKey:@"name"];
        if (![[[[DatabaseTool shared] getDefaultMember] objectForKey:@"avatar"] isEqualToString:@""]) {
            [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:[[[DatabaseTool shared] getDefaultMember] objectForKey:@"avatar"]] placeholderImage:[UIImage imageNamed:@"home_member_icon"]];
        } else {
            [self.iconImageView setImage:[UIImage imageNamed:@"home_member_icon"]];
        }
    } else {
        [self.iconImageView setImage:[UIImage imageNamed:@"home_member_icon"]];
        self.nicknameLabel.text = @"未登录";
    }

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identity = @"RightMenuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
        [cell.contentView setBackgroundColor:MENU_BACKGROUND_COLOR];
        [cell.textLabel setTextColor:[UIColor colorWithRed:22/255.0 green:155/255.0 blue:213/255.0 alpha:1.0]];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"我的信息";
            cell.imageView.image = [UIImage imageNamed:@"guanyumikai"];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"家庭成员";
            cell.imageView.image = [UIImage imageNamed:@"tiwenxiaochangshi"];
        }
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"问题反馈";
            cell.imageView.image = [UIImage imageNamed:@"synchro"];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"我的消息";
            cell.imageView.image = [UIImage imageNamed:@"set_about_icon"];
        }
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 1.0;
    } else {
        return 0.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Third" bundle:nil];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if (![[DatabaseTool shared] getDefaultMember]) {
                UIStoryboard *board = [UIStoryboard storyboardWithName:@"First" bundle:nil];
                UIViewController *loginVc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
                [self presentViewController:loginVc animated:NO completion:^{
                    [SVProgressHUD showErrorWithStatus:@"请您先登录!"];
                }];
            } else {
                UserUpdateViewController *userUpdateVc = [storyboard instantiateViewControllerWithIdentifier:@"UserUpdateViewController"];
                userUpdateVc.memberInfoDict = [[DatabaseTool shared] getDefaultMember];
                userUpdateVc.isFromMain = YES;
                UserNavigationController *userNav = [[UserNavigationController alloc] initWithRootViewController:userUpdateVc];
                [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
                [self presentViewController:userNav animated:NO completion:nil];
            }
            
        } else if (indexPath.row == 1) {
            if (![[DatabaseTool shared] getDefaultMember]) {
                UIStoryboard *board = [UIStoryboard storyboardWithName:@"First" bundle:nil];
                UIViewController *loginVc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
                [self presentViewController:loginVc animated:NO completion:^{
                    [SVProgressHUD showErrorWithStatus:@"请您先登录!"];
                }];
            } else {
                UserNavigationController *userNav = [storyboard instantiateViewControllerWithIdentifier:@"UserNavigationController"];
                [self presentViewController:userNav animated:NO completion:nil];
            }
        }
    } else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"First" bundle:nil];
            UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"ProblemNavigationController"];
            [self presentViewController:vc animated:NO completion:nil];
        } else if (indexPath.row == 1) {
            if (![[DatabaseTool shared] getDefaultMember]) {
                UIStoryboard *board = [UIStoryboard storyboardWithName:@"First" bundle:nil];
                UIViewController *loginVc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
                [self presentViewController:loginVc animated:NO completion:^{
                    [SVProgressHUD showErrorWithStatus:@"请您先登录!"];
                }];
            } else {
                MessageViewController *messageVc = [[MessageViewController alloc] init];
                MessageNavigationController *nav = [[MessageNavigationController alloc] initWithRootViewController:messageVc];
                [self presentViewController:nav animated:NO completion:nil];
            }
        }

    }
}

#pragma mark - 点击头像按钮
- (void)tapImageView {
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    if (![[DatabaseTool shared] getDefaultMember]) {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"First" bundle:nil];
        UIViewController *loginVc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self presentViewController:loginVc animated:NO completion:^{
            [SVProgressHUD showErrorWithStatus:@"请您先登录!"];
        }];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Third" bundle:nil];
        UserNavigationController *userNav = [storyboard instantiateViewControllerWithIdentifier:@"UserNavigationController"];
        [self presentViewController:userNav animated:NO completion:nil];
    }
}
@end
