//
//  UseStickCheckViewController.m
//  MeecaaStickApp
//
//  Created by mciMac on 15/12/9.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "UseStickCheckViewController.h"
#import "LargerCircularProgressView.h"
#import "AddMedicalRecordViewController.h"
#import "MedicalRecordNavigationController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  控制音量所需库文件
 */
#import <MediaPlayer/MPVolumeView.h>
#import "TestDecoder.h"
#import "templib_ios_v531_151214.h"

#import "AddMedicalRecordViewController.h"

@interface UseStickCheckViewController ()<UIScrollViewDelegate> {
    UILabel *temperatureLabelOne;
    UILabel *temperatureLabelTwo;
    UILabel *temperatureLabelThree;
    
    UILabel *timeLabelOne;
    UILabel *timeLabelTwo;
    UILabel *timeLabelThree;
    
    LargerCircularProgressView *progressView;
    
    UIImageView *circularImageViewOne;
    UIImageView *circularImageViewTwo;
    UIImageView *circularImageViewThree;
    
    UIButton *startViewOne;
    UIButton *startViewTwo;
    UIButton *startViewThree;
    
    NSTimer *progressTimer;
    
    UIView           *maskViewOne;          //测温时段内的透明层，用于隔绝用户点击其他控件
    UIView           *maskViewTwo;
    //录音器
    AVAudioRecorder *recorder;
    //播放器
    AVAudioPlayer *player;
    //录音参数设置
    NSDictionary *recorderSettingsDict;
    
    //定时器
    NSTimer *timer;
    //图片组
    NSMutableArray *volumImages;
    double lowPassResults;
    
    //录音名字
    NSString *playName;
    //录音计数器
    int recordCount;
    //测温类型
    int checkType;
    
    NSTimer *timer2;
    //音频播放器
    AVAudioPlayer *avAudioPlayer;
    //播放计数器
    int playCount;
    
    NSTimer *timer3; //    定时采样
    
    // float  timercount3;
    //测温时间计数器
    int timercount3;
    //温度保存记录临时字符串
    NSString *strStoreTemp;
    
    //初始化的温度值，用于给新算法记录温度
    double temperature[11];
    
    BOOL press; //用于标记开始测温按钮是否被按下
    int flag;   //用于标记是哪种类型的测温，以便相应的控件去显示数据
}

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) MMDrawerController * drawerController;

@property (nonatomic,strong) AddMedicalRecordViewController *addMedicalVC;

@property (nonatomic,assign) int normalErrorCount;//常规测温错误次数
@property (nonatomic,assign) int myInteger;
@end

@implementation UseStickCheckViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    
    [self setUpView];
    press = NO;
    //计数次数
    progressView = [[LargerCircularProgressView alloc] initWithFrame:CGRectMake(8, 8, 184, 184)];
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(progressChanged) userInfo:nil repeats:NO];
    
    /*保持屏幕常亮*/
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending) {
        //7.0第一次运行会提示，是否允许使用麦克风
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];
    }
    
    //录音设置
    recorderSettingsDict =[[NSDictionary alloc] initWithObjectsAndKeys:
                           //                                         [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                           /*设置录音格式*/
                           [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,                           //                                         [NSNumber numberWithInt:1000.0],AVSampleRateKey,
                           /*设置录音采样率*/
                           [NSNumber numberWithInt:44100.0],AVSampleRateKey,
                           //                                         [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                           /*通道的数目,1单声道,2立体声*/
                           [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                           //                                         [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                           /*每个采样点位数,分为8、16、24、32*/
                           [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                           /*是否使用浮点数采样*/
                           [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                           /*音频质量*/
                           [NSNumber numberWithInt: AVAudioQualityMedium],AVEncoderAudioQualityKey,
                           nil];
    
    //不停止音乐播放
    NSString *string = [[NSBundle mainBundle] pathForResource:@"once_100ms_on_100ms_off" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:string];
    NSError *error = nil;
    avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    avAudioPlayer.volume = 1;//设置音量最大
    avAudioPlayer.numberOfLoops = 1;//设置循环次数
    [avAudioPlayer prepareToPlay];//准备播放
    
    if ([[[GlobalTool shared] deviceString] isEqualToString:@"iPhone 4S"]) { //如果是4S并且系统版本小于8.0调整音量为85%
        if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            [self setPhoneVolume:0.85f];
        } else {
            [self setPhoneVolume:1.0f];
        }
    } else {
        [self setPhoneVolume:1.0f];
    }
    

    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [avSession requestRecordPermission:^(BOOL available) {
            if(!available) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopCheck];
                    if (_myInteger == 1 || !_myInteger) {
                        [SVProgressHUD showInfoWithStatus:@"请在“设置-隐私-麦克风”选项中允许体温棒访问您的麦克风"];
                    }
                });
                return;
            }
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [avSession requestRecordPermission:^(BOOL available) {
            if(!available) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopCheck];
                    if (_myInteger == 1 || !_myInteger) {
                        [SVProgressHUD showInfoWithStatus:@"请在“设置-隐私-麦克风”选项中允许体温棒访问您的麦克风"];
                    }
                });
                return;
            }
        }];
    }

}

- (void)progressChanged{
    if (flag == 1) {
        progressView.progress += 0.001;
    } else if (flag == 2) {
        progressView.progress += 0.0025;
    }
    
    if (progressView.progress > 1.0f){
        progressView.progress = 0.0f;
    }
}

- (int)myInteger {
    if (!_myInteger) {
        self.myInteger = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"myInteger"];
    }
    return _myInteger;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    progressView.progress = 0;
    press = NO;
    self.scrollView.scrollEnabled = YES;
    [self stopCheck];
}



- (void)setUpView{
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 37, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 149)];
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 2, self.view.frame.size.height - 149);
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator= NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.delegate = self;
    
    /**
     *  SoulJa 2016-01-18
     *  快速测温页面
     */
    UIView *quickView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
    UIView *normalView = [[UIView alloc] initWithFrame:CGRectMake(kScreen_Width, 0, kScreen_Width, kScreen_Height)];
    
    [self.scrollView addSubview:quickView];
    [self.scrollView addSubview:normalView];
    
    //往滚动视图上添加一组图片
    UIImage *_image = [UIImage imageNamed:@"yuanquan"];
    circularImageViewOne = [[UIImageView alloc] initWithImage:_image];
    circularImageViewTwo = [[UIImageView alloc] initWithImage:_image];
    circularImageViewOne.frame = CGRectMake((self.view.frame.size.width - 200) / 2, 30, 200, 200);
    circularImageViewTwo.frame = CGRectMake((self.view.frame.size.width - 200) / 2, 30, 200, 200);
    [normalView addSubview:circularImageViewOne];
    [quickView addSubview:circularImageViewTwo];
    
    //添加时间label
    timeLabelOne = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100) / 2 + 130, 0, 100, 30)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100) / 2 + 130, 0, 100, 30)];
    [imageView setImage:[UIImage imageNamed:@"start_logo"]];
    timeLabelOne.textColor = timeLabelTwo.textColor = NAVIGATIONBAR_BACKGROUND_COLOR;
    timeLabelOne.text = timeLabelTwo.text = @"00:00";
    timeLabelOne.font = timeLabelTwo.font = [UIFont systemFontOfSize:30];
    [normalView addSubview:timeLabelOne];
    
    //添加温度label
    temperatureLabelOne = [[UILabel alloc] initWithFrame:CGRectMake((200 - 130) / 2, 70, 130, 40)];
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake((200 - 100) / 2, 40, 100, 70)];
    [logoImageView setImage:[UIImage imageNamed:@"start_logo"]];
    temperatureLabelOne.text = @"--.-℃";
    temperatureLabelOne.textAlignment = temperatureLabelTwo.textAlignment = NSTextAlignmentCenter;
    temperatureLabelOne.font = temperatureLabelTwo.font = [UIFont systemFontOfSize:36];
    temperatureLabelOne.textColor = temperatureLabelTwo.textColor =temperatureLabelThree.textColor = NAVIGATIONBAR_BACKGROUND_COLOR;
    [circularImageViewOne addSubview:temperatureLabelOne];
    [circularImageViewTwo addSubview:logoImageView];
    
    //添加测温类型label
    
    //添加开始按钮
    startViewOne = [UIButton buttonWithType:UIButtonTypeCustom];
    startViewTwo = [UIButton buttonWithType:UIButtonTypeCustom];
    startViewOne.frame = CGRectMake((kScreen_Width - 120) / 2, 260, 120, 120);
    startViewTwo.frame = CGRectMake((kScreen_Width - 120) / 2, 260, 120, 120);
    [startViewOne setBackgroundImage:[UIImage imageNamed:@"anniu"] forState:UIControlStateNormal];
    [startViewTwo setBackgroundImage:[UIImage imageNamed:@"anniu"] forState:UIControlStateNormal];
    [startViewOne addTarget:self action:@selector(clickToNormalCheck) forControlEvents:UIControlEventTouchUpInside];
    [startViewTwo addTarget:self action:@selector(clickToQuickCheck) forControlEvents:UIControlEventTouchUpInside];
    [normalView addSubview:startViewOne];
    [quickView addSubview:startViewTwo];
    
    for (int i = 0; i < 2; i++) {
        UILabel *typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreen_Width * i + (kScreen_Width - 80) / 2, 140, 80, 40)];
        typeLabel.tag  = 10000 + i;
        typeLabel.textAlignment = NSTextAlignmentCenter;
        typeLabel.textColor = NAVIGATIONBAR_BACKGROUND_COLOR;
        if (typeLabel.tag == 10000) {
            typeLabel.text = @"快速测温";
        }else if (typeLabel.tag == 10001){
            typeLabel.text = @"常规测温";
        }
        [self.scrollView addSubview:typeLabel];
    }
    

    [self.pageControl addTarget:self action:@selector(clickToChangePage:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.scrollView];
}
//实现clickToChangePage方法
- (void)clickToChangePage:(UIPageControl *)sender{
    [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width * sender.currentPage, 0) animated:YES];//带有动画效果
}

//当scrollView上的视图已经减速完成时触发该方法(该方法不一定触发) *****
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    //得到分页数的下标
    self.pageControl.currentPage = scrollView.contentOffset.x / self.view.frame.size.width;
}


#pragma mark - 下面是体温棒测温的方法
- (void)clickToNormalCheck{
    //常规测温错误次数
    self.normalErrorCount = 0;
    
    if (![self canRecord]) {
        return;
    }
    
    if (press == NO) {
        progressView.progress = 0;
    }
    if ([self isHeadsetPluggedIn]) {
        if (press == YES) {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提醒" message:@"是否结束测温？" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopCheck];
                    press = NO;
                    self.scrollView.scrollEnabled = YES;
                });
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertVC addAction:okAction];
            [alertVC addAction:cancelAction];
            [self presentViewController:alertVC animated:YES completion:nil];
            
        }else{
            [self onClickCheck];
            [circularImageViewOne addSubview:progressView];
            progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1818181818 target:self selector:@selector(progressChanged) userInfo:nil repeats:YES];
            timeLabelOne.text = @"00:00";
            self.scrollView.scrollEnabled = NO;
            
            press = YES;
            flag = 1;
            [self addMaskView];
        }
    } else {
        if (_myInteger == 1 || !_myInteger) {
            [SVProgressHUD showErrorWithStatus:@"请将体温棒连接手机！"];
        }
    }
}


#pragma mark - 点击快速测温按钮
- (void)clickToQuickCheck {
    for (int i = 0; i < 11; i++) {
        temperature[i] = -55.0f;
    }
    
    if (![self canRecord]) {
        return;
    }
    
    if ([self isHeadsetPluggedIn]) {
        if (press == YES) {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提醒" message:@"是否结束测温？" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopCheck];
                    press = NO;
                    self.scrollView.scrollEnabled = YES;
                });
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertVC addAction:okAction];
            [alertVC addAction:cancelAction];
            [self presentViewController:alertVC animated:YES completion:nil];
            
        }else{
            [self onClickCheck];
            [circularImageViewTwo addSubview:progressView];
            progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progressChanged) userInfo:nil repeats:YES];
            timeLabelOne.text = @"00:00";
            self.scrollView.scrollEnabled = NO;
            press = YES;
            flag = 2;
            [self addMaskView];
        }
    } else {
        if (_myInteger == 1 || !_myInteger) {
            [SVProgressHUD showErrorWithStatus:@"请将体温棒连接手机！"];
        }
    }
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
 *  设置音量
 */
- (void)setPhoneVolume:(float)volume{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    // retrieve system volume
    //    float systemVolume = volumeViewSlider.value;
    
    // change system volume, the value is between 0.0f and 1.0f
    [volumeViewSlider setValue:volume animated:NO];
    
    // send UI control event to make the change effect right now.
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}


/**
 *	开始录音
 */
- (void)onClickCheck{
    /*删除原有的raw文件*/
    [self deleteTempFiles];
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    long long int date = (long long int)time;
    timercount3 = 0;
    strStoreTemp=@"";
    
    /*每隔一秒执行一次*/
    timer3 = [NSTimer scheduledTimerWithTimeInterval: 1
                                              target: self
                                            selector: @selector(handleTimer3:)
                                            userInfo: nil
                                             repeats: YES];
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    playName = [NSString stringWithFormat:@"%@/play_%lli.raw", docDir,date];//创建录音文件
    [self play];
    
    //记录开始测温时间
    [GlobalTool sharedSingleton].receivedStartTime = [[NSDate date] timeIntervalSince1970];
}


/**
 *  开始播放
 */
- (void)play{
    /*播放计数*/
    playCount = 0;
    
    /*每0.1秒执行一次*/
    timer2 = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playTimer:) userInfo:nil repeats:YES];
    /*播放音乐*/
    [avAudioPlayer play];
}

-(void)playTimer:(NSTimer*)timer_{
    /*播放计数*/
    playCount++;
    /*计数两次之后停止播放音乐开始录音*/
    if (playCount>=2) {   //这个是播放时间的 先不要改动
        playCount = 0;
        [timer2 invalidate];//移除定时器timer2
        timer2 = nil;
        [self downAction];
    }
}
/**
 *  按下录音按键
 */
- (void)downAction{
    //按下录音
    if ([self canRecord]) {
        
        NSError *error = nil;
        //必须真机上测试,模拟器上可能会崩溃
        recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
        
        if (recorder) {
            /*录音计数器*/
            recordCount = 0;
            /*是否启用音频测量*/
            recorder.meteringEnabled = YES;
            
            /*准备录音*/
            [recorder prepareToRecord];
            /*开始录音*/
            [recorder record];
            //启动定时器
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(levelTimer:) userInfo:nil repeats:YES];
            
        } else
        {
            NSLog(@"Error:[4.4s])");
            
        }
    }
}


//判断是否允许使用麦克风7.0新增的方法requestRecordPermission
-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }
                else {
                    bCanRecord = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"app需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风"
                                                   delegate:nil
                                          cancelButtonTitle:@"关闭"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    
    return bCanRecord;
}

/**
 *  处理录音时间
 */
-(void)levelTimer:(NSTimer*)timer_
{
    //call to refresh meter values刷新平均和峰值功率,此计数是以对数刻度计量的,-160表示完全安静，0表示最大输入值
    [recorder updateMeters];
    const double ALPHA = 0.05;
    double peakPowerForChannel = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
    
    //    NSLog(@"Average input: %f Peak input: %f Low pass results: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0], lowPassResults);
    /*录音计数大于2时*/
    if (recordCount>=2) {   //修改了此处加大了录音部分
        recordCount = 0;
        [self upAction];
    }
    recordCount++;
}


- (void)upAction{
    //松开 结束录音
    
    //录音停止
    [recorder stop];
    recorder = nil;
    //结束定时器
    [timer invalidate];
    timer = nil;
    
    [self onClickCut];
}

- (void)onClickCut{
    [self onClickRead];
}

- (void)onClickRead{
    NSMutableDictionary *resultDict = [[TestDecoder sharedTestDecoder] TestDecoderWithPath:playName];
    
    int resultINT = [[resultDict objectForKey:@"returnINT"] intValue];
    int itemp = [[resultDict objectForKey:@"temperature"] intValue];
    float ftemp = (float)(itemp /100.00f);
    
    if (resultINT == 0) { //解码成功
        if (self.normalErrorCount > 0) {
            self.normalErrorCount = 0;
        } else {
            if (itemp == 9999 || itemp == - 9999) {
                [self stopCheck];
                if (_myInteger == 1 || !_myInteger) {
                    [SVProgressHUD showErrorWithStatus:@"超出测温范围!"];
                }
                return;
            } else if (itemp == 7777) {
                [self stopCheck];
                if (_myInteger == 1 || !_myInteger) {
                    [SVProgressHUD showErrorWithStatus:@"请联系客服!"];
                }
                return;
            } else {
                if (flag == 1) {
                    temperatureLabelOne.text = [NSString stringWithFormat:@"%.1f℃", ftemp];
                }else if (flag == 2){
                    temperatureLabelTwo.text = [NSString stringWithFormat:@"%.1f℃", ftemp];
                    for (int i = 0; i<10; i++) {
                        temperature[i] = temperature[i+1];
                    }
                    temperature[10] = ftemp;
                    if (timercount3 >= 40) {
                        [self stopCheck];
                        if (_myInteger == 1 || !_myInteger) {
                            [SVProgressHUD showErrorWithStatus:@"体温棒放好了吗？请重新测温!"];
                        }
                    }
                    double resultTemp = judge(temperature);
                    NSLog(@"%f",resultTemp);
                    if (resultTemp == -66) {
                        return;
                    } else {
                        [self stopCheck];
                        timercount3 = 0;
                        double finalTemperature = resultTemp;
                        NSString *temperatureStr = [NSString stringWithFormat:@"%.1lf", finalTemperature];
                        [GlobalTool sharedSingleton].receivedTempStr = temperatureStr;
                        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
                        AddMedicalRecordViewController *vc = [board instantiateViewControllerWithIdentifier:@"AddMedicalRecordViewController"];
                        MedicalRecordNavigationController *nav = [[MedicalRecordNavigationController alloc] initWithRootViewController:vc];
                        [GlobalTool sharedSingleton].presentView = YES;//标记是体温棒测温页面跳转过去的
                        [UIApplication sharedApplication].keyWindow.rootViewController = nav;
                    }
                }else if (flag == 3){
                    temperatureLabelThree.text = [NSString stringWithFormat:@"%.1f℃", ftemp];
                }
                return;
            }
        }
    } else { //解码错误
        if (flag == 1) { //常规测温
            self.normalErrorCount++;
            if (self.normalErrorCount > 3) {
                [self stopCheck];
                if (_myInteger == 1 || !_myInteger) {
                    [SVProgressHUD showErrorWithStatus:@"请重新连接耳机孔，再次测温。"];
                }
                return;
            }
        } else if (flag == 2) {
            if (timercount3 < 3) {
                for (int i = 0; i<10; i++) {
                    temperature[i] = temperature[i+1];
                }
                temperature[10] = ftemp;
                return;
            } else {
                [self stopCheck];
                if (_myInteger == 1 || !_myInteger) {
                    [SVProgressHUD showErrorWithStatus:@"请重新连接耳机孔，再次测温。"];
                }
            }
        }
    }
}

/**
 *	跳转到主页面
 */
- (MMDrawerController *)drawerController{
    if (_drawerController == nil) {
        MainTabBarController *mainTabBarC = [[MainTabBarController alloc] init];
        LeftMenuViewController *leftMenuVc = [[LeftMenuViewController alloc] init];
        RightMenuViewController *rightMenuVc = [[RightMenuViewController alloc] init];
        self.drawerController = [[MMDrawerController alloc] initWithCenterViewController:mainTabBarC leftDrawerViewController:leftMenuVc rightDrawerViewController:rightMenuVc];
        [self.drawerController setShowsShadow:NO];
        [self.drawerController setMaximumRightDrawerWidth:200];
        [self.drawerController setMaximumLeftDrawerWidth:200];
        
    }
    return _drawerController;
}
/**
 *  停止检测
 */
- (void)stopCheck {
    /*消除所有定时器*/
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if (timer2) {
        [timer2 invalidate];
        timer2 = nil;
    }
    
    if (timer3) {
        [timer3 setFireDate:[NSDate distantFuture]];
        [timer3 invalidate];
        timer3 = nil;
    }
    
    if ([avAudioPlayer isPlaying]) {
        [avAudioPlayer stop];
    }
    
    if (progressTimer) {
        [progressTimer setFireDate:[NSDate distantFuture]];
        [progressTimer invalidate];
        progressTimer = nil;
    }
    //结束测温把按钮状态置为no
    press = NO;
    [progressView setProgress:0.0f];
    [temperatureLabelOne setText:@"--.-"];
    [timeLabelOne setText:@"00:00"];
    [temperatureLabelTwo setText:@"--.-"];
    [timeLabelTwo setText:@"00:00"];
    self.scrollView.scrollEnabled = YES;
    [GlobalTool sharedSingleton].receivedEndTime = [[NSDate date] timeIntervalSince1970];
    [self removeMaskView];
}

/**
 *  处理定时器Timer3
 */
- (void) handleTimer3: (NSTimer *) timer3
{
    timercount3++;//时间计数自增
    if (timercount3 >= 180 && flag == 1) {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        AddMedicalRecordViewController *vc = [board instantiateViewControllerWithIdentifier:@"AddMedicalRecordViewController"];
        MedicalRecordNavigationController *nav = [[MedicalRecordNavigationController alloc] initWithRootViewController:vc];
        //开始传值
        if (flag == 1) {
            [GlobalTool sharedSingleton].receivedTempStr = [temperatureLabelOne.text substringToIndex:4];
        }
        [GlobalTool sharedSingleton].presentView = YES;//标记是体温棒测温页面跳转过去的
        [UIApplication sharedApplication].keyWindow.rootViewController = nav;
        [self stopCheck];
    }
    /*开始播放*/
    [self play];
    
    int min = timercount3%60;
    int sec = timercount3/60;
    if (flag == 1) {
        timeLabelOne.text = [NSString stringWithFormat:@"%@:%@",[self getTimeStr:sec], [self getTimeStr:min]];
    }else if (flag == 2){
        timeLabelTwo.text = [NSString stringWithFormat:@"%@:%@",[self getTimeStr:sec], [self getTimeStr:min]];
    }else if (flag == 3){
        timeLabelThree.text = [NSString stringWithFormat:@"%@:%@",[self getTimeStr:sec], [self getTimeStr:min]];
    }
}

- (NSString *)getTimeStr:(int)value
{
    if (value<10) {
        return [NSString stringWithFormat:@"0%i",value];
    }
    return [NSString stringWithFormat:@"%i",value];
}

/**
 *  删除录音文件
 */
- (void)deleteTempFiles{
    NSString *extension = @"raw";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];//获取到documents下所有文件及文件夹的数组
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension]) { //判断后缀是否为raw
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];//删除后缀为raw的文件
        }
    }
}




/**
 *	12 / 16 添加 / 移除透明层
 */
- (void)addMaskView {
    maskViewOne = [[UIView alloc] initWithFrame:CGRectMake(0, 20, kScreen_Width, 44)];
    maskViewTwo = [[UIView alloc] initWithFrame:CGRectMake(0, kScreen_Height - 49, kScreen_Width, 49)];
    maskViewOne.backgroundColor = maskViewTwo.backgroundColor = [UIColor clearColor ];
    [[UIApplication sharedApplication].keyWindow addSubview:maskViewOne];
    [[UIApplication sharedApplication].keyWindow addSubview:maskViewTwo];
}
-(void)removeMaskView {
    [maskViewOne removeFromSuperview];
    [maskViewTwo removeFromSuperview];
}
@end
