//
//  LineChartCell.h
//  MeecaaStickApp
//
//  Created by mciMac on 15/12/17.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZX.h"
@interface LineChartCell : UITableViewCell
/**
 *	添加折线图
 */
@property (nonatomic,strong)ZX *lineChart;
@property (nonatomic,strong)UIScrollView *scrollView;    //显示可滑动折线图的scrollView
@end
