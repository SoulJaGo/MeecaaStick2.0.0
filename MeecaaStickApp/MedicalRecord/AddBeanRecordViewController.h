//
//  AddBeanRecordViewController.h
//  MeecaaStickApp
//
//  Created by mciMac on 15/12/18.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddBeanRecordViewController : UIViewController
@property (nonatomic,retain)NSString *receivedTempStr;
@property (nonatomic,retain)NSString *receivedTimeStr;
@property (nonatomic,retain)NSString *receivedDescriptStr;
@property (nonatomic, retain) NSString *receivedSymptomStr;
@property (nonatomic,assign) BOOL isFromUpdateBtn;
@end
