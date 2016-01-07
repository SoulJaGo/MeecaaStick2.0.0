 //
//  AddBeanRecordViewController.m
//  MeecaaStickApp
//
//  Created by mciMac on 15/12/18.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "AddBeanRecordViewController.h"

#import "TimeLabelCell.h"
#import "TemperatureLabelCell.h"
#import "SymptomCell.h"
#import "DescriptionLabelCell.h"
#import "PhotosCell.h"
#import "CollectionViewCell.h"
#import "LineChartCell.h"
#import "MainTabBarController.h"
#import "ZX.h"
#import "MMDrawerController.h"
@interface AddBeanRecordViewController()<UITextFieldDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) TimeLabelCell *timeLabelCell;
@property (nonatomic,strong) UIDatePicker *datePicker;
@property (nonatomic,strong) UIView *datePickerHeaderView;
@property (nonatomic,strong) TemperatureLabelCell *temperatureLabelCell;
@property (nonatomic,strong) SymptomCell *symptomCell;
/**
 *  症状视图
 */
@property (nonatomic,strong) UIView *SymptomButtonsView;
@property (nonatomic,strong) UIView *SymptomButtonsHeaderView;
@property (nonatomic,strong) NSMutableArray *symptomButtonsArray;
/**
 *  添加描述TextView
 */
@property (nonatomic,strong) UITextView *descriptionTextView;
@property (nonatomic,strong) UIView *descriptionHeaderView;
/**
 *  添加照片View
 */
@property (nonatomic,strong) UIView *photosView;
@property (nonatomic,strong) UIView *photosHeaderView;
@property (nonatomic,strong) NSMutableArray *photosArray;

@property (nonatomic,strong) UIImagePickerController *ipc;
@property (nonatomic,strong)UICollectionView *collectionView;
/**
 *	添加折线图
 */
@property (nonatomic,strong)ZX *lineChart;
@property (nonatomic,strong)UIScrollView *scrollView;    //显示可滑动折线图的scrollView
@property (nonatomic,strong) NSMutableArray *picturesIDArray;//用于存放用户选取图片后返回的id的数组
@property (nonatomic,strong) MMDrawerController * drawerController;
@end

@implementation AddBeanRecordViewController
-(void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //设置Nav
    [self setupNav];
    
    self.photosArray = [NSMutableArray array];
    self.picturesIDArray = [NSMutableArray array];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GlobalTool sharedSingleton].endTime = [[NSDate date] timeIntervalSince1970];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AddPictureSuccessNotification:) name:@"AddPictureSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addBeanDiarySuccessNotification) name:@"AddBeanDiarySuccessNotification" object:nil];
}

- (void)addBeanDiarySuccessNotification {
    [GlobalTool sharedSingleton].presentView = NO;
    [UIApplication sharedApplication].keyWindow.rootViewController = self.drawerController;
}

- (MMDrawerController *)drawerController {
    if (_drawerController == nil) {
        MainTabBarController *mainTabBarC = [[MainTabBarController alloc] init];
        [mainTabBarC setSelectedIndex:1];
        LeftMenuViewController *leftMenuVc = [[LeftMenuViewController alloc] init];
        RightMenuViewController *rightMenuVc = [[RightMenuViewController alloc] init];
        
        self.drawerController = [[MMDrawerController alloc] initWithCenterViewController:mainTabBarC leftDrawerViewController:leftMenuVc rightDrawerViewController:rightMenuVc];
        [self.drawerController setShowsShadow:NO];
        [self.drawerController setMaximumRightDrawerWidth:200];
        [self.drawerController setMaximumLeftDrawerWidth:200];
    }
    return _drawerController;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddPictureSuccessNotification" object:nil];
}

- (void)AddPictureSuccessNotification:(NSNotification *)notify {
    NSLog(@"notify.object %@",notify.object);
    [self.picturesIDArray addObject:notify.object];
}
/**
 *  设置Nav
 */
- (void)setupNav {
    self.navigationItem.title = @"添加记录";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"medical_back_icon"] style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(onClickSave)];
}
/**
 *  保存
 */
- (void)onClickSave {
    //取出默认用户
    NSDictionary *defaultMember = [[DatabaseTool shared]  getDefaultMember];
    if (defaultMember == nil) {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"First" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self presentViewController:vc animated:NO completion:^{
            [SVProgressHUD showErrorWithStatus:@"请您先登录"];
        }];
        
        return;
    }
    
    //取出默认用户的id
    NSString *defaultMemberId = [NSString stringWithFormat:@"%@",defaultMember[@"id"]];
    
    //获取填写的时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate *date = [formatter dateFromString:self.timeLabelCell.timeLabel.text];
    NSTimeInterval time = [date timeIntervalSince1970];
    
    NSString *timeStr = [NSString stringWithFormat:@"%d",(int)time];
    //描述
    NSString *desc = [NSString string];
    if ([self.descriptionTextView.text isEqualToString:@""]) {
        desc = @"未描述";
    } else {
        desc = self.descriptionTextView.text;
    }
    
    //温度值
    if ([self.temperatureLabelCell.temperatureTextField.text isEqualToString:@""] || self.temperatureLabelCell.temperatureTextField.text == nil) {
        [SVProgressHUD showErrorWithStatus:@"请填写温度！"];
        return;
    }
    
    float temperatureFloat = [self.temperatureLabelCell.temperatureTextField.text floatValue];
    if (temperatureFloat > 44.0 || temperatureFloat < 32.0) {
        [SVProgressHUD showErrorWithStatus:@"超出体温范围！（请填写32.0~44.0）"];
        return;
    }
    
    int symptomInt = 0;
    for (UIButton *btn in self.symptomButtonsArray) {
        symptomInt += [self count2N:(int)btn.tag];
    }
    
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    /**
     *	12 / 22 Temperature:self.temperatureLabelCell.temperatureTextField.text 修改
     *	切换到新接口
     */
    NSString *pic_ids;
    if (self.picturesIDArray.count > 0) {
        pic_ids = [self.picturesIDArray componentsJoinedByString:@","];
    }
    [[HttpTool shared] addMedicalRecordWithType:1 Member_id:defaultMemberId Temperture:[[GlobalTool sharedSingleton].lineChartArray componentsJoinedByString:@","] Date:timeStr StartTime:[GlobalTool sharedSingleton].startTime EndTime:[GlobalTool sharedSingleton].endTime Symptoms:[NSString stringWithFormat:@"%d",symptomInt] Description:desc Longitude:[NSString stringWithFormat:@"%f",[[GlobalTool shared] longitude]] Latitude:[NSString stringWithFormat:@"%f",[[GlobalTool shared] latitude]] Pic_ids:pic_ids];
}

/**
 *  计算2的N次方
 */
- (int)count2N:(int)n {
    int result = 2;
    for (int i=1; i<n; i++) {
        result = result * 2;
    }
    return result;
}

/**
 *  返回上级
 */
- (void)goBack {
    MainTabBarController *mainTabBarC = [[MainTabBarController alloc] init];
    [mainTabBarC setSelectedIndex:1];
    LeftMenuViewController *leftMenuVc = [[LeftMenuViewController alloc] init];
    RightMenuViewController *rightMenuVc = [[RightMenuViewController alloc] init];
    self.drawerController = [[MMDrawerController alloc] initWithCenterViewController:mainTabBarC leftDrawerViewController:leftMenuVc rightDrawerViewController:rightMenuVc];
    [self.drawerController setShowsShadow:NO];
    [self.drawerController setMaximumRightDrawerWidth:200];
    [self.drawerController setMaximumLeftDrawerWidth:200];
    [self presentViewController:self.drawerController animated:NO completion:^{
        [GlobalTool sharedSingleton].fromBeanPresentView = NO;
    }];
    //    if ([GlobalTool sharedSingleton].fromBeanPresentView == 1) {
    //    }else {
    //        [self.navigationController popToRootViewControllerAnimated:YES];
    //    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isFromUpdateBtn == NO) {
        if (indexPath.section == 0) {
            LineChartCell *lineChartCell = [tableView dequeueReusableCellWithIdentifier:@"LineChartCell"];
            [lineChartCell.contentView addSubview:self.setUpScrollView];
            [self.lineChart setArray:[GlobalTool sharedSingleton].lineChartArray];
            [self.lineChart setNeedsDisplay];
            return lineChartCell;
        } else if (indexPath.section == 1) {
            TimeLabelCell *timeLabelcell = [tableView dequeueReusableCellWithIdentifier:@"TimeLabelCell"];
            timeLabelcell.addMedicalRecordVc = self;
            self.timeLabelCell = timeLabelcell;
            return timeLabelcell;
        } else if (indexPath.section == 2) {
            TemperatureLabelCell *temperatureLabelCell = [tableView dequeueReusableCellWithIdentifier:@"TemperatureLabelCell"];
            temperatureLabelCell.temperatureTextField.delegate = self;
            self.temperatureLabelCell = temperatureLabelCell;
            self.temperatureLabelCell.temperatureTextField.text = [GlobalTool sharedSingleton].beanCheckTempStr;

            return temperatureLabelCell;
        } else if (indexPath.section == 3) {
            SymptomCell *symptomCell = [tableView dequeueReusableCellWithIdentifier:@"SymptomCell"];
            self.symptomButtonsArray = [NSMutableArray array];
            self.symptomCell = symptomCell;
            return symptomCell;
        } else if (indexPath.section == 4) {
            DescriptionLabelCell *descCell = [tableView dequeueReusableCellWithIdentifier:@"DescriptionLabelCell"];
            return descCell;
        } else if (indexPath.section == 5) {
            PhotosCell *photosCell = [tableView dequeueReusableCellWithIdentifier:@"PhotosCell"];
            return photosCell;
        }
    }else if (self.isFromUpdateBtn == YES) {
        if (indexPath.section == 0) {
            LineChartCell *lineChartCell = [tableView dequeueReusableCellWithIdentifier:@"LineChartCell"];
            [lineChartCell.contentView addSubview:self.setUpScrollView];
            NSArray *valueArray = [self.receivedTempStr componentsSeparatedByString:@","];
            [self.lineChart setArray:[valueArray mutableCopy]];
            [self.lineChart setNeedsDisplay];
            return lineChartCell;
        } else if (indexPath.section == 1) {
            TimeLabelCell *timeLabelcell = [tableView dequeueReusableCellWithIdentifier:@"TimeLabelCell"];
            timeLabelcell.addMedicalRecordVc = self;
            self.timeLabelCell = timeLabelcell;
            self.timeLabelCell.timeLabel.text = self.receivedTimeStr;
            return timeLabelcell;
        } else if (indexPath.section == 2) {
            TemperatureLabelCell *temperatureLabelCell = [tableView dequeueReusableCellWithIdentifier:@"TemperatureLabelCell"];
            temperatureLabelCell.temperatureTextField.delegate = self;
            self.temperatureLabelCell = temperatureLabelCell;
            self.temperatureLabelCell.temperatureTextField.text = self.receivedTempStr;
            //        if ([GlobalTool sharedSingleton].fromBeanPresentView == 0) {
            //            self.temperatureLabelCell.temperatureTextField.text = nil;
            //        }
            return temperatureLabelCell;
        } else if (indexPath.section == 3) {
            SymptomCell *symptomCell = [tableView dequeueReusableCellWithIdentifier:@"SymptomCell"];
            self.symptomButtonsArray = [NSMutableArray array];
            self.symptomCell = symptomCell;
            self.symptomCell.symptomLabel.text = self.receivedSymptomStr;
            return symptomCell;
        } else if (indexPath.section == 4) {
            DescriptionLabelCell *descCell = [tableView dequeueReusableCellWithIdentifier:@"DescriptionLabelCell"];
            self.descriptionTextView.text = self.receivedDescriptStr;
            return descCell;
        } else if (indexPath.section == 5) {
            PhotosCell *photosCell = [tableView dequeueReusableCellWithIdentifier:@"PhotosCell"];
            return photosCell;
        }

    }
    
    TimeLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeLabelCell"];
    return cell;
}
- (UIScrollView *)setUpScrollView {
    if (_scrollView == nil) {
        self.scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 230)];
        self.scrollView.bounces=NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        [self.scrollView setContentSize:CGSizeMake(2000, 230)];
        
        self.lineChart = [[ZX alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width,230)];
        [self.lineChart setBackgroundColor:[UIColor clearColor]];
        [self.scrollView addSubview:self.lineChart];
    }
    return _scrollView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 230;
    }else {
        return 60;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        //去除键盘
        [self.view endEditing:YES];
        
        [self.SymptomButtonsView removeFromSuperview];
        [self.SymptomButtonsHeaderView removeFromSuperview];
        [self.descriptionTextView removeFromSuperview];
        [self.descriptionHeaderView removeFromSuperview];
        [self.photosView removeFromSuperview];
        [self.photosHeaderView removeFromSuperview];
        [self.view addSubview:self.datePickerHeaderView];
        self.datePicker.frame = CGRectMake(0, self.view.frame.size.height - 216, self.view.frame.size.width, 216);
        [self.view addSubview:self.datePicker];
    } else if (indexPath.section == 3) {
        [self.datePickerHeaderView removeFromSuperview];
        [self.datePicker removeFromSuperview];
        [self.descriptionTextView removeFromSuperview];
        [self.descriptionHeaderView removeFromSuperview];
        [self.photosView removeFromSuperview];
        [self.photosHeaderView removeFromSuperview];
        [self.view addSubview:self.SymptomButtonsView];
        [self.view addSubview:self.SymptomButtonsHeaderView];
    } else if (indexPath.section == 4) {
        [self.datePickerHeaderView removeFromSuperview];
        [self.datePicker removeFromSuperview];
        [self.SymptomButtonsView removeFromSuperview];
        [self.SymptomButtonsHeaderView removeFromSuperview];
        [self.photosView removeFromSuperview];
        [self.photosHeaderView removeFromSuperview];
        [self.descriptionTextView becomeFirstResponder];
        [self.view addSubview:self.descriptionTextView];
        [self.view addSubview:self.descriptionHeaderView];
    } else if (indexPath.section == 5) {
        [self.datePickerHeaderView removeFromSuperview];
        [self.datePicker removeFromSuperview];
        [self.SymptomButtonsView removeFromSuperview];
        [self.SymptomButtonsHeaderView removeFromSuperview];
        [self.descriptionTextView removeFromSuperview];
        [self.descriptionHeaderView removeFromSuperview];
        [self.view addSubview:self.photosView];
        [self.view addSubview:self.photosHeaderView];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSArray *points = [textField.text componentsSeparatedByString:@"."];
    if (points.count>=2&&[string isEqualToString:@"."]) {
        return NO;
    }
    // Check for total length
    NSUInteger proposedNewLength = textField.text.length - range.length + string.length;
    //限制温度输入长度
    if (proposedNewLength > 5){
        return NO;//限制长度
    }
    return [self validateNumber:string];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)validateNumber:(NSString*)number {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    int i = 0;
    while (i< number.length) {
        NSString * string = [number substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}



/**
 *  添加照片View
 */
- (UIView *)photosView {
    if (_photosView == nil) {
        self.photosView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 216, self.view.bounds.size.width, 216)];
        [self.photosView setBackgroundColor:[UIColor whiteColor]];
        
        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        addBtn.frame = CGRectMake(10, 78, 60, 60);
        [addBtn setBackgroundImage:[UIImage imageNamed:@"medical_add_icon"] forState:UIControlStateNormal];
        [addBtn addTarget:self action:@selector(onClickAddPhoto) forControlEvents:UIControlEventTouchUpInside];
        [self.photosView addSubview:addBtn];
        
        UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(80, 78, self.view.bounds.size.width - 10 - 60 - 10, 60) collectionViewLayout:flowLayout];
        [self.collectionView setBackgroundColor:[UIColor whiteColor]];
        //设置代理
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [self.photosView addSubview:self.collectionView];
        
        [self.collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    }
    return _photosView;
}

#pragma mark -- UICollectionViewDataSource
//定义展示的UICollectionViewCell的个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photosArray.count;
}
//定义展示的Section的个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
//每个UICollectionView展示的内容
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identify = @"cell";
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
    [cell.imageView setImage:self.photosArray[indexPath.row]];
    [cell.delBtn setTag:indexPath.row];
    [cell.delBtn addTarget:self action:@selector(onClickDelPhoto:) forControlEvents:UIControlEventTouchUpInside];
    [cell sizeToFit];
    if (!cell) {
        NSLog(@"无法创建CollectionViewCell时打印，自定义的cell就不可能进来了。");
    }
    
    return cell;
}

- (void)onClickDelPhoto:(UIButton *)btn {
    [self.photosArray removeObjectAtIndex:btn.tag];
    [self.picturesIDArray removeObjectAtIndex:btn.tag];
    [self.collectionView reloadData];
}

#pragma mark --UICollectionViewDelegateFlowLayout
//定义每个UICollectionView 的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //边距占5*4=20 ，2个
    //图片为正方形，边长：(fDeviceWidth-20)/2-5-5 所以总高(fDeviceWidth-20)/2-5-5 +20+30+5+5 label高20 btn高30 边
    return CGSizeMake(60, 60);
}
//定义每个UICollectionView 的间距
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 5, 5, 5);
}



- (void)onClickAddPhoto {
    if (self.photosArray.count >= 5) {
        [SVProgressHUD showErrorWithStatus:@"最多上传5张照片!"];
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"请选择" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"相册" otherButtonTitles:@"拍照", nil];
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //相册
    if (buttonIndex == 0) {
        [self showPhoto];
    }
    //拍照
    if (buttonIndex == 1) {
        [self showCamera];
    }
}

/**
 *  从相册中选取
 */
- (void)showPhoto
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    ipc.navigationBar.tintColor = [UIColor blackColor];
    ipc.delegate = self;
    self.ipc = ipc;
    [self presentViewController:self.ipc animated:YES completion:nil];
}

/**
 *  从照相机选取
 */
- (void)showCamera
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    ipc.allowsEditing = YES;
    ipc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    ipc.delegate = self;
    ;
    self.ipc = ipc;
    [self presentViewController:self.ipc animated:YES completion:nil];
    
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        [[HttpTool shared] uploadPicture:image];
    }];
    [self.photosArray addObject:info[UIImagePickerControllerOriginalImage]];
    [self.collectionView reloadData];
}




- (UIView *)photosHeaderView {
    if (_photosHeaderView == nil) {
        self.photosHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 260, self.view.bounds.size.width, 44)];
        [self.photosHeaderView setBackgroundColor:NAVIGATIONBAR_BACKGROUND_COLOR];
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, 0, 100, 44);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [cancelBtn addTarget:self action:@selector(cancelSelectPhoto) forControlEvents:UIControlEventTouchUpInside];
        [self.photosHeaderView addSubview:cancelBtn];
        UIButton *completeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        completeBtn.frame = CGRectMake(self.photosHeaderView.frame.size.width - 100, 0, 100, 44);
        [completeBtn setTitle:@"完成" forState:UIControlStateNormal];
        completeBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [completeBtn addTarget:self action:@selector(completePhotos) forControlEvents:UIControlEventTouchUpInside];
        [self.photosHeaderView addSubview:completeBtn];
        
    }
    return _photosHeaderView;
}

- (void)completePhotos {
    [self.photosHeaderView removeFromSuperview];
    [self.photosView removeFromSuperview];
}
- (void)cancelSelectPhoto {
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
    [self.photosView removeFromSuperview];
    [self.photosHeaderView removeFromSuperview];
}
/**
 *  添加描述TextView
 */
- (UITextView *)descriptionTextView {
    if (_descriptionTextView == nil) {
        _descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 416, self.view.frame.size.width, 216)];
    }
    return _descriptionTextView;
}

/**
 *  添加描述TextView的Header
 */
- (UIView *)descriptionHeaderView {
    if (_descriptionHeaderView == nil) {
        self.descriptionHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 460, self.view.frame.size.width, 44)];
        [self.descriptionHeaderView setBackgroundColor:NAVIGATIONBAR_BACKGROUND_COLOR];
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, 0, 100, 44);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [cancelBtn addTarget:self action:@selector(cancelSelectDesc) forControlEvents:UIControlEventTouchUpInside];
        [self.descriptionHeaderView addSubview:cancelBtn];
        
        UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        selectBtn.frame = CGRectMake(self.descriptionHeaderView.frame.size.width-100, 0, 100, 44);
        [selectBtn setTitle:@"完成" forState:UIControlStateNormal];
        selectBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [selectBtn addTarget:self action:@selector(completeSelectDesc) forControlEvents:UIControlEventTouchUpInside];
        [self.descriptionHeaderView addSubview:selectBtn];
    }
    return _descriptionHeaderView;
}

/**
 *  取消描述
 */
- (void)cancelSelectDesc {
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
    [self.descriptionHeaderView removeFromSuperview];
    [self.descriptionTextView removeFromSuperview];
}

/**
 *  完成描述
 */
- (void)completeSelectDesc {
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
    [self.descriptionHeaderView removeFromSuperview];
    [self.descriptionTextView removeFromSuperview];
}



/**
 *  症状顶部视图
 */
- (UIView *)SymptomButtonsHeaderView {
    if (_SymptomButtonsHeaderView == nil) {
        self.SymptomButtonsHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 260, self.view.bounds.size.width, 44)];
        [self.SymptomButtonsHeaderView setBackgroundColor:NAVIGATIONBAR_BACKGROUND_COLOR];
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, 0, 100, 44);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [cancelBtn addTarget:self action:@selector(cancelSelectSymptom) forControlEvents:UIControlEventTouchUpInside];
        [self.SymptomButtonsHeaderView addSubview:cancelBtn];
        
        UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        selectBtn.frame = CGRectMake(self.SymptomButtonsHeaderView.bounds.size.width-100, 0, 100, 44);
        [selectBtn setTitle:@"完成" forState:UIControlStateNormal];
        selectBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [selectBtn addTarget:self action:@selector(completeSelectSymptom) forControlEvents:UIControlEventTouchUpInside];
        [self.SymptomButtonsHeaderView addSubview:selectBtn];
    }
    return _SymptomButtonsHeaderView;
}

/**
 *  点击取消
 */
- (void)cancelSelectSymptom {
    //    self.symptomButtonsArray = nil;
    //    for (UIView *subview in self.SymptomButtonsView.subviews) {
    //        if ([subview isKindOfClass:[UIButton class]]) {
    //            for (UIView *nextSubview in subview.subviews) {
    //                if ([nextSubview isKindOfClass:[UIImageView class]]) {
    //                    [nextSubview setHidden:YES];
    //                }
    //            }
    //        }
    //    }
    
    [self.SymptomButtonsView removeFromSuperview];
    [self.SymptomButtonsHeaderView removeFromSuperview];
}

/**
 *  点击完成
 */
- (void)completeSelectSymptom {
    NSString *str = [NSString string];
    for (UIButton *btn in self.symptomButtonsArray) {
        str = [str stringByAppendingString:btn.titleLabel.text];
        str = [str stringByAppendingString:@" "];
    }
    self.symptomCell.symptomLabel.text = str;
    [self.SymptomButtonsView removeFromSuperview];
    [self.SymptomButtonsHeaderView removeFromSuperview];
}


/**
 *  症状视图
 */
- (UIView *)SymptomButtonsView {
    if (_SymptomButtonsView == nil) {
        self.SymptomButtonsView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width, 216)];
        [self.SymptomButtonsView setBackgroundColor:[UIColor whiteColor]];
        NSArray *symtonTemplateList = [[GlobalTool shared] symptonTemplateList];
        for (int i = 0; i < symtonTemplateList.count; i++) {
            NSDictionary *btnDict = symtonTemplateList[i];
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = [[btnDict objectForKey:@"tag"] intValue];
            [btn setTitle:[btnDict objectForKey:@"name"] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            CGFloat btnW = (self.view.bounds.size.width - 5*5) / 4;
            CGFloat btnH = (216 - 5*5)/4;
            CGFloat btnX = 5 + (btnW + 5) * (i%4);
            CGFloat btnY = 5 + (btnH + 5) * (i/4);
            
            btn.frame = CGRectMake(btnX, btnY, btnW, btnH);
            //添加选中图标
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.frame = CGRectMake(btnW - 20, btnH - 20, 20, 20);
            imageView.image = [UIImage imageNamed:@"medical_choose_icon"];
            [imageView setHidden:YES];
            [btn addSubview:imageView];
            
            [btn addTarget:self action:@selector(onClickSymptonBtn:) forControlEvents:UIControlEventTouchUpInside];
            [self.SymptomButtonsView addSubview:btn];
        }
    }
    return _SymptomButtonsView;
}

- (void)onClickSymptonBtn:(UIButton *)btn {
    for (UIView *subView in btn.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            if (subView.hidden == YES) {
                [self.symptomButtonsArray addObject:btn];
                [subView setHidden:NO];
            } else {
                [self.symptomButtonsArray removeObject:btn];
                [subView setHidden:YES];
            }
        }
    }
}


/**
 *  设置DatePicker
 */
- (UIDatePicker *)datePicker
{
    if (_datePicker == nil) {
        self.datePicker = [[UIDatePicker alloc] init];
        self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        self.datePicker.minimumDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
        [self.datePicker setBackgroundColor:[UIColor whiteColor]];
    }
    return _datePicker;
}

- (UIView *)datePickerHeaderView
{
    if (_datePickerHeaderView == nil) {
        _datePickerHeaderView = [[UIView alloc] init];
        _datePickerHeaderView.frame = CGRectMake(0, self.view.bounds.size.height - 260, self.view.bounds.size.width, 44);
        _datePickerHeaderView.backgroundColor = NAVIGATIONBAR_BACKGROUND_COLOR;
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, 0, 100, 44);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [cancelBtn addTarget:self action:@selector(cancelSelectBirth) forControlEvents:UIControlEventTouchUpInside];
        [_datePickerHeaderView addSubview:cancelBtn];
        
        UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        selectBtn.frame = CGRectMake(_datePickerHeaderView.bounds.size.width-100, 0, 100, 44);
        [selectBtn setTitle:@"完成" forState:UIControlStateNormal];
        selectBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [selectBtn addTarget:self action:@selector(dataChange) forControlEvents:UIControlEventTouchUpInside];
        [_datePickerHeaderView addSubview:selectBtn];
    }
    return _datePickerHeaderView;
}

/**
 *  点击取消按钮
 */
- (void)cancelSelectBirth
{
    [_datePicker removeFromSuperview];
    [_datePickerHeaderView removeFromSuperview];
}

- (void)dataChange
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm";
    NSString *birthStr = [formatter stringFromDate:[self.datePicker date]];
    self.timeLabelCell.timeLabel.text = birthStr;
    [self.datePicker removeFromSuperview];
    [self.datePickerHeaderView removeFromSuperview];
}

@end
