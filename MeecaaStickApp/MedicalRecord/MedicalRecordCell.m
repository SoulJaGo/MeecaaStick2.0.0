//
//  MedicalRecordCell.m
//  MeecaaStickApp
//
//  Created by SoulJa on 16/1/8.
//  Copyright © 2016年 SoulJa. All rights reserved.
//

#import "MedicalRecordCell.h"

@implementation MedicalRecordCell
- (instancetype)initWithInfoDict:(NSMutableDictionary *)infoDict {
    self = [super init];
    if (self) {
        UIImageView *iconImageView = [[UIImageView alloc] init];
        CGFloat iconImageViewX = 10;
        CGFloat iconImageViewW = 10;
        CGFloat iconImageViewH = 10;
        CGFloat iconImageViewY = (103 - iconImageViewH) / 2;
        [iconImageView setFrame:CGRectMake(iconImageViewX, iconImageViewY, iconImageViewW, iconImageViewH)];
        [iconImageView setImage:[UIImage imageNamed:@"medical_point_icon0"]];
        [self.contentView addSubview:iconImageView];
        
        UILabel *timeLabel = [[UILabel alloc] init];
        CGFloat timeLabelX = CGRectGetMaxX(iconImageView.frame)+ 10;
        CGFloat timeLabelY = 10;
        CGFloat timeLabelW = 150;
        CGFloat timeLabelH = 30;
        [timeLabel setFrame:CGRectMake(timeLabelX, timeLabelY, timeLabelW, timeLabelH)];
        [timeLabel setTextColor:[UIColor lightGrayColor]];
        [timeLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [timeLabel setText:[infoDict objectForKey:@"time"]];
        [self.contentView addSubview:timeLabel];
        
        UILabel *symbtonLabel = [[UILabel alloc] init];
        CGFloat symbtonLabelX = timeLabelX;
        CGFloat symbtonLabelW = 300;
        CGFloat symbtonLabelH = 30;
        CGFloat symbtonLabelY = 103 - symbtonLabelH - 10;
        [symbtonLabel setFrame:CGRectMake(symbtonLabelX, symbtonLabelY, symbtonLabelW, symbtonLabelH)];
        [symbtonLabel setTextColor:[UIColor lightGrayColor]];
        [symbtonLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [symbtonLabel setText:[infoDict objectForKey:@"symbton"]];
        [self.contentView addSubview:symbtonLabel];
        
        UILabel *temperatureLabel = [[UILabel alloc] init];
        CGFloat temperatureLabelW = 130;
        CGFloat temperatureLabelH = 40;
        CGFloat temperatureLabelY = (103 - temperatureLabelH) / 2;
        CGFloat temperatureLabelX = kScreen_Width - temperatureLabelW - 15;
        [temperatureLabel setFrame:CGRectMake(temperatureLabelX, temperatureLabelY, temperatureLabelW, temperatureLabelH)];
        [temperatureLabel setTextColor:NAVIGATIONBAR_BACKGROUND_COLOR];
        [temperatureLabel setFont:[UIFont systemFontOfSize:33]];
        [temperatureLabel setText:[[infoDict objectForKey:@"value"] stringByAppendingString:@"℃"]];
        [temperatureLabel setTextAlignment:NSTextAlignmentRight];
        
        [self.contentView addSubview:temperatureLabel];
    }
    return self;
}
@end
