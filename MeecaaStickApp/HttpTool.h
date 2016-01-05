//
//  HttpTool.h
//  MeecaaStickApp
//
//  Created by SoulJa on 15/11/18.
//  Copyright © 2015年 SoulJa. All rights reserved.
//  Http工具类

#import <UIKit/UIKit.h>

@interface HttpTool : UIViewController
/**
 *  单例对象
 */
+ (id)shared;
/**
 *  是否升级
 */
- (void)getVersion;
/**
 *  监测是否连上网络
 */
- (BOOL)isConnectInternet;
/**
 *  获取广告页的数据
 */
- (void)getAdvertisementDictionary;
/**
 *  监测最新的版本
 */
- (NSMutableDictionary *)getLastVersion;
/**
 *  手机号码以及密码登陆
 */
- (void)LoginWithPhoneNumber:(NSString *)phoneNumber Password:(NSString *)password;
/**
 *  修改密码接收验证码
 */
- (void)getResetPwdVerifyCode:(NSString *)phone;
/**
 *  修改用户密码
 */
- (void)resetAccountPasswordByPhoneNumber:(NSString *)phoneNumber NewPwd:(NSString *)newPwd Code:(NSString *)code;

/**
 *  第三方登陆
 */
- (void)loginThirdPartyWithOpenId:(NSString *)openId NickName:(NSString *)nickName PlatForm:(NSString *)platForm Avatar:(NSString *)avatar;

/**
 *  设置为选中的成员
 */
- (void)setDefaultMemberWithAcc_id:(NSString *)acc_id Mid:(NSString *)mid;

/**
 *  获取默认用户的所有测温记录
 */
- (void)getDefaultMemberDiaryInfo;

/**
 *  删除一个成员
 */
- (void)removeMember:(NSString *)mid;

/**
 *  添加一个成员的方法
 */
- (void)addMemberWithName:(NSString *)name Sex:(NSString *)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr Acc_id:(NSString *)acc_id;
/**
 *  添加带图像成员的方法
 */
- (void)addMemberWithName:(NSString *)name Sex:(NSString *)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr Acc_id:(NSString *)acc_id IconImage:(UIImage *)iconImage;

/**
 *  删除一条记录
 */
- (void)removeDiary:(NSString *)diaryId;

/**
 *	更新一个改变了头像的成员的方法
 */
- (void)updateMemberWithMid:(NSString *)mid Name:(NSString *)name Sex:(NSString *)sex Birth:(NSString *)birth City:(NSString *)city IconImage:(UIImage *)iconImage;
/**
 *	更新一个没有改变头像的成员的方法
 */
- (void)updateMemberWithMid:(NSString *)mid Name:(NSString *)name Sex:(NSString *)sex Birth:(NSString *)birth City:(NSString *)city;

/**
 *  发起添加记录的请求
 */
- (void)addDiaryWithDate:(NSString *)date Temperature:(NSString *)temperature Symptoms:(NSString *)symptoms Photo_count:(NSString *)photo_count Description:(NSString *)description Member_id:(NSString *)member_id Longitude:(NSString *)longitude Latitude:(NSString *)latitude;

/**
 *  发起修改记录的请求
 */
- (void)updateDiaryWithID:(NSString *)tid Temperature:(NSString *)temperature Date:(NSString *)date Symptoms:(NSString *)symptoms Photo_count:(NSString *)photo_count Description:(NSString *)description;

/**
 *  获取默认用户的所有测温记录 0 -- 棒子
 */
- (void)getDefaultMemberDiaryInfoByPage:(int)page;

/**
 *  注册用户
 */
- (void)registerAccountWithPhoneNumber:(NSString *)phoneNumber NickName:(NSString *)nickName Password:(NSString *)password registerCode:(NSString *)code;

/**
 *  接收验证码
 */
- (void)getRegistVerifyCode:(NSString *)phone;

/**
 *	12 / 18 改版，上传用户症状图片的接口
 */
- (void)uploadPicture:(UIImage *)image;
/**
 *	12 / 22 新接口 棒子测温完成和豆子测温完成后跳转界面，点保存走此接口，默认棒子，豆子 = 1，手动添加温度记录页面，点保存默认添加的是棒子测温
 */
- (void)addMedicalRecordWithType:(int )type Member_id:(NSString *)member_id Temperture:(NSString *)temperature Date:(NSString *)date StartTime:(int )startTime EndTime:(int )endTime Symptoms:(NSString *)symptoms Description:(NSString *)description Longitude:(NSString *)longitude Latitude:(NSString *)latitude Pic_ids:(NSString *)pic_ids;
/**
 *  获取默认用户的所有测温记录 1 -- 豆子
 */
- (void)getDefaultMemberBeanDiaryInfoByPage:(int)page;

/**
 *  进入主页后验证登陆
 */
- (void)validLogin;

/**
 *  删除一条记录
 */
- (void)removeBeanDiary:(NSString *)diaryId;

@end