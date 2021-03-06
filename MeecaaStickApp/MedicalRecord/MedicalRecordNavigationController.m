//
//  MedicalRecordNavigationController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 15/11/19.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "MedicalRecordNavigationController.h"

@implementation MedicalRecordNavigationController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationBar setBackgroundImage:[[GlobalTool shared] createImageWithColor:NAVIGATIONBAR_BACKGROUND_COLOR]  forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    self.navigationBar.translucent = NO;
    
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
