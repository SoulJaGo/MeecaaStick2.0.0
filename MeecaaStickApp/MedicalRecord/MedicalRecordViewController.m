//
//  MedicalRecordViewController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 16/1/8.
//  Copyright © 2016年 SoulJa. All rights reserved.
//

#import "MedicalRecordViewController.h"
#import "MJRefresh.h"
#import "MedicalRecordCell.h"
#import "UpdateMedicalRecordTableViewController.h"
#import "AddBeanRecordViewController.h"
#import "CXPhotoBrowser.h"
#import "AddMedicalRecordViewController.h"
@interface MedicalRecordViewController () <UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,CXPhotoBrowserDataSource,CXPhotoBrowserDelegate>
@property (nonatomic,strong) UISegmentedControl *segmentControl;
@property (nonatomic,strong) UIScrollView *scorllView;
@property (nonatomic,strong) UITableView *stickTableView;
@property (nonatomic,strong) UITableView *beanTableView;
@property (nonatomic,assign) int stickPage;
@property (nonatomic,assign) int beanPage;
@property (nonatomic,strong) NSMutableArray *stickDiaryArray;
@property (nonatomic,strong) NSMutableArray *beanDiaryArray;
@property (retain, nonatomic) NSMutableArray *stickHistoryList;
@property (retain, nonatomic) NSMutableArray *beanHistoryList;
@property (nonatomic,strong) NSIndexPath *selectedIndexPath;
@property (nonatomic,strong) NSMutableDictionary *dayDetailInfo;
/**
 *  图片展示层
 */
@property (nonatomic, strong) CXPhotoBrowser *browser;
@property (nonatomic, strong) NSMutableArray *photoDataSource;
@property (nonatomic,strong) NSMutableArray *picsArray;

@end
@implementation MedicalRecordViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    /*创建segment*/
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"体温棒",@"温豆"]];
    CGFloat segmentControlW = 250;
    CGFloat segmentControlH = 30;
    CGFloat segmentControlX = (kScreen_Width - segmentControlW) / 2;
    CGFloat segmentControlY = 10;
    [segmentControl setFrame:CGRectMake(segmentControlX, segmentControlY, segmentControlW, segmentControlH)];
    [segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    [segmentControl setTintColor:NAVIGATIONBAR_BACKGROUND_COLOR];
    [segmentControl setSelectedSegmentIndex:0];
    [segmentControl addTarget:self action:@selector(switchTableView) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segmentControl];
    self.segmentControl = segmentControl;
    
    /*创建scrollView*/
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    CGFloat scrollViewX = 0;
    CGFloat scrollViewY = CGRectGetMaxY(segmentControl.frame) + 10;
    CGFloat scrollViewW = kScreen_Width;
    CGFloat scrollViewH = kScreen_Height - scrollViewY - 49;
    [scrollView setFrame:CGRectMake(scrollViewX, scrollViewY, scrollViewW, scrollViewH)];
    [scrollView setContentSize:CGSizeMake(2 * kScreen_Width, scrollViewH)];
    scrollView.showsVerticalScrollIndicator = NO;
    [scrollView setScrollEnabled:NO];
    [self.view addSubview:scrollView];
    self.scorllView = scrollView;
    
    /*添加体温棒TableView*/
    UITableView *stickTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, scrollViewW, scrollViewH - 49) style:UITableViewStyleGrouped];
    [self.scorllView addSubview:stickTableView];
    self.stickTableView = stickTableView;
    
    self.stickPage = 1;
    self.stickDiaryArray = [NSMutableArray array];
    
    /*添加温豆的TableView*/
    UITableView *beanTableView = [[UITableView alloc] initWithFrame:CGRectMake(kScreen_Width, 0, scrollViewW, scrollViewH - 49) style:UITableViewStyleGrouped];
    [self.scorllView addSubview:beanTableView];
    self.beanTableView = beanTableView;
    
    self.beanPage = 1;
    self.beanDiaryArray = [NSMutableArray array];
    
    /*添加温度按钮*/
    UIButton *addDiaryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat addDiaryBtnW = 100;
    CGFloat addDiaryBtnH = 100;
    CGFloat addDiaryBtnX = (kScreen_Width - 100) / 2;
    CGFloat addDiaryBtnY = kScreen_Height - addDiaryBtnH - 120;
    [addDiaryBtn setFrame:CGRectMake(addDiaryBtnX, addDiaryBtnY, addDiaryBtnW, addDiaryBtnH)];
    [addDiaryBtn setBackgroundImage:[UIImage imageNamed:@"medical_go_icon"] forState:UIControlStateNormal];
    [addDiaryBtn addTarget:self action:@selector(onClickAddDiary) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addDiaryBtn];
    
    
    //设置Nav
    [self setupNav];
    
    //异步加载数据
    if ([[DatabaseTool shared] getDefaultMember]) { //登陆状态
        if (![[DatabaseTool shared] getDefaultMemberLastDiary]) { //没有数据的时候（t_dairy 棒子）
            //请求网络读取数据
            [SVProgressHUD show];
            [[HttpTool shared] getDefaultMemberDiaryInfoByPage:1];//手动写了一个0类型传进去，把所有棒子的记录传回来
        } else { //数据库有数据的时候
            self.stickDiaryArray = [[DatabaseTool shared] getDefaultMemberDiaryFromPage:1];
        }
    }
    
    //上拉加载
    MJRefreshAutoNormalFooter *footer1 = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreOldData)];
    footer1.stateLabel.textColor = [UIColor colorWithRed:194/255.0 green:194/255.0 blue:194/255.0 alpha:1.0];
    self.stickTableView.footer = footer1;
    self.stickTableView.dataSource = self;
    self.stickTableView.delegate = self;
    
    MJRefreshAutoNormalFooter *footer2 = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreOldData)];
    footer2.stateLabel.textColor = [UIColor colorWithRed:194/255.0 green:194/255.0 blue:194/255.0 alpha:1.0];
    self.beanTableView.footer = footer2;
    self.beanTableView.dataSource = self;
    self.beanTableView.delegate = self;
    
}

#pragma mark - 设置导航栏
- (void)setupNav {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_logo"]];
}

#pragma mark - 改变TableView
- (void)switchTableView {
    self.selectedIndexPath = nil;
    if (self.segmentControl.selectedSegmentIndex == 0) {
        [self.scorllView setContentOffset:CGPointMake(0, 0) animated:YES];
        self.stickPage = 1;
        //异步加载数据
        if ([[DatabaseTool shared] getDefaultMember]) { //登陆状态
            if (![[DatabaseTool shared] getDefaultMemberLastDiary]) { //没有数据的时候（t_dairy 棒子）
                //请求网络读取数据
                [SVProgressHUD show];
                [[HttpTool shared] getDefaultMemberDiaryInfoByPage:1];//手动写了一个0类型传进去，把所有棒子的记录传回来
            } else { //数据库有数据的时候
                self.stickDiaryArray = [[DatabaseTool shared] getDefaultMemberDiaryFromPage:1];
                [self.stickTableView reloadData];
            }
        }
    } else if (self.segmentControl.selectedSegmentIndex == 1) {
        [self.scorllView setContentOffset:CGPointMake(kScreen_Width, 0) animated:YES];
        //异步加载数据
        if ([[DatabaseTool shared] getDefaultMember]) { //登陆状态
            if (![[DatabaseTool shared] getDefaultMemberLastBeanDiary]) { //没有数据的时候（豆子）
                [SVProgressHUD show];
                //请求网络读取数据
                [[HttpTool shared] getDefaultMemberBeanDiaryInfoByPage:1];//手动写了一个1类型传进去，把所有豆子的记录传回来
            } else {
                self.beanDiaryArray = [[DatabaseTool shared] getDefaultMemberBeanDiaryFromPage:1];
                [self.beanTableView reloadData];
            }
        }
    }
}

#pragma mark - 加载更多的数据
- (void)loadMoreOldData {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        self.stickPage++;
        NSMutableArray *array = [[DatabaseTool shared] getDefaultMemberDiaryFromPage:self.stickPage];
        if (array == nil || array.count == 0) { //本地没有更多的数据了
            [[HttpTool shared] getDefaultMemberDiaryInfoByPage:self.stickPage];
        } else { //本地有更多的数据
            [self.stickDiaryArray addObjectsFromArray:array];
            [self.stickTableView reloadData];
            [self.stickTableView.footer endRefreshing];
        }
    } else if (self.segmentControl.selectedSegmentIndex == 1) {
        self.beanPage++;
        NSMutableArray *array = [[DatabaseTool shared] getDefaultMemberBeanDiaryFromPage:self.beanPage];
        if (array == nil || array.count == 0) { //本地没有更多的数据了
            [[HttpTool shared] getDefaultMemberBeanDiaryInfoByPage:self.beanPage];
        } else { //本地有更多的数据
            [self.beanDiaryArray addObjectsFromArray:array];
            [self.beanTableView reloadData];
            [self.beanTableView.footer endRefreshing];
        }

    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeDiarySuccessNotification) name:@"RemoveDiarySuccessNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeBeanDiarySuccessNotification) name:@"RemoveBeanDiarySuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initDiaryDataSuccessNotification) name:@"InitDiaryDataSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initDiaryDataEndSuccessNotification) name:@"InitDiaryDataEndSuccessNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initBeanDiaryDataSuccessNotification) name:@"InitBeanDiaryDataSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initBeanDiaryDataEndSuccessNotification) name:@"InitBeanDiaryDataEndSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNewDiarySuccessNotification) name:@"UpdateNewDiarySuccessNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveDiarySuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveBeanDiarySuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitDiaryDataSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitBeanDiaryDataSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitDiaryDataEndSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitBeanDiaryDataEndSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateNewDiarySuccessNotification" object:nil];
}

#pragma mark - 棒子数据刷新页面
- (void)initDiaryDataSuccessNotification {
    NSMutableArray *array = [[DatabaseTool shared] getDefaultMemberDiaryFromPage:self.stickPage];
    if (array != nil || array.count != 0) { //没有数据
        [self.stickDiaryArray addObjectsFromArray:array];
        [self.stickTableView reloadData];
    }
    [self.stickTableView.footer endRefreshing];
}

//豆子数据刷新页面
- (void)initBeanDiaryDataSuccessNotification {
    NSMutableArray *array = [[DatabaseTool shared] getDefaultMemberBeanDiaryFromPage:self.beanPage];
    if (array != nil || array.count != 0) {
        [self.beanDiaryArray addObjectsFromArray:array];
        [self.beanTableView reloadData];
    }
    [self.beanTableView.footer endRefreshing];
}

- (void)initDiaryDataEndSuccessNotification {
    [self.stickTableView.footer endRefreshing];
}

- (void)initBeanDiaryDataEndSuccessNotification {
    [self.beanTableView.footer endRefreshing];
}

//删除棒子测温
- (void)removeDiarySuccessNotification {
    self.stickDiaryArray = [[DatabaseTool shared] getDefaultMemberDiaryFromPage:1];
    self.stickPage = 1;
    self.selectedIndexPath = nil;
    [self.stickTableView reloadData];
    [SVProgressHUD showSuccessWithStatus:@"记录删除成功!"];
}
//删除豆子测温
- (void)removeBeanDiarySuccessNotification {
    self.beanDiaryArray = [[DatabaseTool shared] getDefaultMemberBeanDiaryFromPage:1];
    self.beanPage = 1;
    self.selectedIndexPath = nil;
    [self.beanTableView reloadData];
    [SVProgressHUD showSuccessWithStatus:@"记录删除成功!"];
}

- (void)updateNewDiarySuccessNotification {
    self.stickDiaryArray = [[DatabaseTool shared] getDefaultMemberDiaryFromPage:1];
    self.stickPage = 1;
    self.selectedIndexPath = nil;
    [self.stickTableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        return self.stickHistoryList.count;
    } else {
        return self.beanHistoryList.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        NSDictionary *detailInfo = [self.stickHistoryList objectAtIndex:section];
        NSArray *infoList = [detailInfo objectForKey:@"detail"];
        return infoList.count;
    } else {
        NSDictionary *detailInfo = [self.beanHistoryList objectAtIndex:section];
        NSArray *infoList = [detailInfo objectForKey:@"detail"];
        return infoList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    if (self.segmentControl.selectedSegmentIndex == 0) {
        NSDictionary *detailInfo = [self.stickHistoryList objectAtIndex:section];
        NSArray *infoList = [detailInfo objectForKey:@"detail"];
        NSMutableDictionary *dayDetailInfo = [infoList objectAtIndex:(row)];
        MedicalRecordCell *cell = [[MedicalRecordCell alloc] initWithInfoDict:dayDetailInfo];
        return cell;
    } else {
        NSDictionary *detailInfo = [self.beanHistoryList objectAtIndex:section];
        NSArray *infoList = [detailInfo objectForKey:@"detail"];
        NSMutableDictionary *dayDetailInfo = [infoList objectAtIndex:(row)];
        MedicalRecordCell *cell = [[MedicalRecordCell alloc] initWithInfoDict:dayDetailInfo];
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.segmentControl.selectedSegmentIndex == 0) {
        NSDictionary *detailInfo = [self.stickHistoryList objectAtIndex:section];
        NSString *dayInfo = [detailInfo objectForKey:@"day"];
        return dayInfo;
    } else {
        NSDictionary *detailInfo = [self.beanHistoryList objectAtIndex:section];
        NSString *dayInfo = [detailInfo objectForKey:@"day"];
        return dayInfo;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath == self.selectedIndexPath) {
        return 263;
    } else {
        return 103;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.selectedIndexPath == nil) { //一开始没有选择过Cell
        self.selectedIndexPath = indexPath;
        NSUInteger section = [indexPath section];
        NSInteger row = [indexPath row];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        /*数据*/
        NSDictionary *detailInfo = [NSDictionary dictionary];
        if (self.segmentControl.selectedSegmentIndex == 0) {
            detailInfo = [self.stickHistoryList objectAtIndex:section];
        } else if (self.segmentControl.selectedSegmentIndex == 1) {
            detailInfo = [self.beanHistoryList objectAtIndex:section];
        }
        NSArray *infoList = [detailInfo objectForKey:@"detail"];
        NSMutableDictionary *dayDetailInfo = [infoList objectAtIndex:(row)];
        self.dayDetailInfo = dayDetailInfo;
        self.picsArray = dayDetailInfo[@"pics"];
        MedicalRecordCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self createDetailViewWithInfoDict:self.dayDetailInfo Cell:cell];
    } else {
        if (self.selectedIndexPath == indexPath) {
            MedicalRecordCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            for (UIView *subview in cell.contentView.subviews) {
                if (subview.frame.origin.y == 103) {
                    [subview removeFromSuperview];
                    break;
                }
            }
            self.selectedIndexPath = nil;
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            NSIndexPath *oldIndexPath = self.selectedIndexPath;
            self.selectedIndexPath = indexPath;
            NSUInteger section = [indexPath section];
            NSInteger row = [indexPath row];
            [tableView reloadRowsAtIndexPaths:@[oldIndexPath,indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            /*数据*/
            NSDictionary *detailInfo = [NSDictionary dictionary];
            if (self.segmentControl.selectedSegmentIndex == 0) {
                detailInfo = [self.stickHistoryList objectAtIndex:section];
            } else if (self.segmentControl.selectedSegmentIndex == 1) {
                detailInfo = [self.beanHistoryList objectAtIndex:section];
            }
            NSArray *infoList = [detailInfo objectForKey:@"detail"];
            NSMutableDictionary *dayDetailInfo = [infoList objectAtIndex:(row)];
            self.dayDetailInfo = dayDetailInfo;
            self.picsArray = dayDetailInfo[@"pics"];
            MedicalRecordCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            MedicalRecordCell *selectedCell = [tableView cellForRowAtIndexPath:oldIndexPath];
            for (UIView *subview in selectedCell.contentView.subviews) {
                if (subview.frame.origin.y == 103) {
                    [subview removeFromSuperview];
                    break;
                }
            }
            [self createDetailViewWithInfoDict:self.dayDetailInfo Cell:cell];
        }
    }
    
}

#pragma mark - 详细信息
- (void)createDetailViewWithInfoDict:(NSMutableDictionary *)infoDict Cell:(MedicalRecordCell *)cell{
    UIView *detailView = [[UIView alloc] initWithFrame:CGRectMake(0, 103, kScreen_Width, 160)];
    
    UILabel *descLabel = [[UILabel alloc] init];
    CGFloat descLabelX = 10;
    CGFloat descLabelY = 10;
    CGFloat descLabelW = kScreen_Width;
    CGFloat descLabelH = 30;
    [descLabel setFrame:CGRectMake(descLabelX, descLabelY, descLabelW, descLabelH)];
    [descLabel setText:[infoDict objectForKey:@"desc"]];
    [descLabel setTextColor:[UIColor lightGrayColor]];
    [descLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [detailView addSubview:descLabel];
    
    if ([[infoDict objectForKey:@"pics"] count] > 0 && ![[[infoDict objectForKey:@"pics"] objectAtIndex:0]  isEqual: @""]) {
        for (int i = 0; i < [[infoDict objectForKey:@"pics"] count]; i++) {
            UIImageView *imageView = [[UIImageView alloc] init];
            CGFloat imageViewW = 60;
            CGFloat imageViewH = 60;
            CGFloat imageViewX = 10 * (i+1) + imageViewW * i;
            CGFloat imageViewY = CGRectGetMaxY(descLabel.frame) + 10;
            [imageView setFrame:CGRectMake(imageViewX, imageViewY, imageViewW, imageViewH)];
            [imageView sd_setImageWithURL:[NSURL URLWithString:[[infoDict objectForKey:@"pics"] objectAtIndex:i]]];
            imageView.userInteractionEnabled = YES;
            [imageView setTag:i];
            UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageView:)];
            [imageView addGestureRecognizer:recognizer];
            [detailView addSubview:imageView];
        }
    }
    
    UIButton *updateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat updateBtnX = 10;
    CGFloat updateBtnY = 120;
    CGFloat updateBtnW = 50;
    CGFloat updateBtnH = 30;
    [updateBtn setFrame:CGRectMake(updateBtnX, updateBtnY, updateBtnW, updateBtnH)];
    [updateBtn setTitleColor:NAVIGATIONBAR_BACKGROUND_COLOR forState:UIControlStateNormal];
    [updateBtn setTitle:@"修改" forState:UIControlStateNormal];
    [updateBtn addTarget:self action:@selector(onClickUpdateBtn) forControlEvents:UIControlEventTouchUpInside];
    [detailView addSubview:updateBtn];
    
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat deleteBtnW = 50;
    CGFloat deleteBtnH = 30;
    CGFloat deleteBtnX = kScreen_Width - deleteBtnW - 10;
    CGFloat deleteBtnY = 120;
    [deleteBtn setFrame:CGRectMake(deleteBtnX, deleteBtnY, deleteBtnW, deleteBtnH)];
    [deleteBtn setTitleColor:NAVIGATIONBAR_BACKGROUND_COLOR forState:UIControlStateNormal];
    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [deleteBtn addTarget:self action:@selector(onClickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
    [detailView addSubview:deleteBtn];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [cell.contentView addSubview:detailView];
    });
}

/**
 *  点击修改按钮
 */
- (void)onClickUpdateBtn {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    if (self.segmentControl.selectedSegmentIndex == 0) {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        UpdateMedicalRecordTableViewController *vc = [board instantiateViewControllerWithIdentifier:@"UpdateMedicalRecordTableViewController"];
        [vc setHidesBottomBarWhenPushed:YES];
        
        NSString *string = [self.dayDetailInfo objectForKey:@"date"];
        NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [formatter setTimeZone:timeZone];
        NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:[string intValue] + 28800];
        NSString *confromTimespStr = [formatter stringFromDate:confromTimesp];
        vc.receivedTimeStr = confromTimespStr;
        vc.receivedTempStr = [self.dayDetailInfo objectForKey:@"value"];
        vc.receivedSymptomStr = [self.dayDetailInfo objectForKey:@"symbton"];
        vc.receivedDescriptStr = [self.dayDetailInfo objectForKey:@"desc"];
        vc.detailMedicalRecordInfo = self.dayDetailInfo;
        [self.navigationController pushViewController:vc animated:YES];
    }else if ( self.segmentControl.selectedSegmentIndex == 1) {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
        AddBeanRecordViewController *vc = [board instantiateViewControllerWithIdentifier:@"AddBeanRecordViewController"];
        [vc setHidesBottomBarWhenPushed:YES];
        
        NSString *string = [self.dayDetailInfo objectForKey:@"date"];
        NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [formatter setTimeZone:timeZone];
        NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:[string intValue] + 28800];
        NSString *confromTimespStr = [formatter stringFromDate:confromTimesp];
        vc.receivedTimeStr = confromTimespStr;
        vc.receivedTempStr = [self.dayDetailInfo objectForKey:@"value"];
        vc.receivedSymptomStr = [self.dayDetailInfo objectForKey:@"symbton"];
        vc.receivedDescriptStr = [self.dayDetailInfo objectForKey:@"desc"];
        vc.isFromUpdateBtn = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

/**
 *  点击删除按钮
 */
- (void)onClickDeleteBtn {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"您确认要删除么?" message:@"您确认要删除么?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    } else {
        if (self.segmentControl.selectedSegmentIndex == 0) {
            [SVProgressHUD show];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            NSString *diaryId = [NSString stringWithFormat:@"%@",[self.dayDetailInfo objectForKey:@"tid"]];
            [[HttpTool shared] removeDiary:diaryId];
        }else if (self.segmentControl.selectedSegmentIndex == 1) {
            [SVProgressHUD show];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            NSString *diaryId = [NSString stringWithFormat:@"%@",[self.dayDetailInfo objectForKey:@"tid"]];
            [[HttpTool shared] removeBeanDiary:diaryId];
        }
    }
}


- (NSArray *)getSymptons:(NSNumber *)value{
    if (value==0) {
        return nil;
    }
    return [[GlobalTool shared] getFlagInIntergerPosition:value];
}

- (NSMutableArray *)stickHistoryList
{
    //先判断数据库中是否存在测温记录
    NSMutableArray *list = self.stickDiaryArray;
    NSMutableArray *showList = [NSMutableArray array];
    for (int i=0; i<list.count; i++) {
        NSDictionary *dayHistory = [list objectAtIndex:i];
        NSNumber *date = [dayHistory objectForKey:@"date"];
        NSNumber *tid = [dayHistory objectForKey:@"id"];
        NSNumber *member_id = [dayHistory objectForKey:@"member_id"];
        NSArray *pics = [dayHistory objectForKey:@"pics"];
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:[date longLongValue]];
        NSDateFormatter *dateFormater = [NSDateFormatter new];
        dateFormater.dateFormat = @"yyyy.M.d";
        NSString *dayStr = [dateFormater stringFromDate:dateValue];
        
        NSDateFormatter *timeFormater = [[NSDateFormatter alloc] init];
        timeFormater.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        [timeFormater setDateFormat:@"h:mm a"];
        NSString *timeStr = [timeFormater stringFromDate:dateValue];
        
        int photo_count = [[dayHistory objectForKey:@"photo_count"] intValue];
        
        NSMutableArray *dayDiary;
        for (int j=0; j<showList.count; j++) {
            NSDictionary *_dayDiary = [showList objectAtIndex:j];
            NSString *_dayStr = [_dayDiary objectForKey:@"day"];
            if ([_dayStr isEqualToString:dayStr]) {
                dayDiary = [_dayDiary objectForKey:@"detail"];
                break;
            }
        }
        if (dayDiary==nil) {
            dayDiary = [NSMutableArray array];
            NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
            [showDict setObject:dayStr forKey:@"day"];
            [showDict setObject:dayDiary forKey:@"detail"];
            [showList addObject:showDict];
        }
        
        NSMutableDictionary *timeDiary = [NSMutableDictionary dictionary];
        NSString *temperature = [dayHistory objectForKey:@"temperature"];
        [timeDiary setObject:temperature forKey:@"value"];
        
        NSString *description = [dayHistory objectForKey:@"description"];
        
        NSString *symptonStr = @"";
        NSArray *symptons = [self getSymptons:[dayHistory objectForKey:@"symptoms"]];
        if (symptons==nil||symptons.count==0) {
            symptonStr = @"";
        }
        else{
            for (int i=0; i<symptons.count; i++) {
                NSNumber *tag = [symptons objectAtIndex:i];
                NSString *name = [[GlobalTool shared] getSymptonNameByTag:tag];
                symptonStr = [symptonStr stringByAppendingString:[NSString stringWithFormat:@"%@",name]];
                symptonStr = [symptonStr stringByAppendingString:@" "];
            }
        }
        [timeDiary setObject:symptonStr forKey:@"symbton"];
        [timeDiary setObject:timeStr forKey:@"time"];
        [timeDiary setObject:date forKey:@"date"];
        [timeDiary setObject:[NSNumber numberWithInt:photo_count] forKey:@"photo_count"];
        [timeDiary setObject:tid forKey:@"tid"];
        [timeDiary setObject:description forKey:@"desc"];
        [timeDiary setObject:member_id forKey:@"member_id"];
        [timeDiary setObject:pics forKey:@"pics"];
        [dayDiary addObject:timeDiary];
    }
    
    _stickHistoryList = showList;
    return _stickHistoryList;
}

- (NSMutableArray *)beanHistoryList {
    //先判断数据库中是否存在测温记录
    NSMutableArray *list = self.beanDiaryArray;
    NSMutableArray *showList = [NSMutableArray array];
    for (int i=0; i<list.count; i++) {
        NSDictionary *dayHistory = [list objectAtIndex:i];
        NSNumber *date = [dayHistory objectForKey:@"date"];
        NSNumber *tid = [dayHistory objectForKey:@"id"];
        NSNumber *member_id = [dayHistory objectForKey:@"member_id"];
        NSArray *pics = [dayHistory objectForKey:@"pics"];
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:[date longLongValue]];
        NSDateFormatter *dateFormater = [NSDateFormatter new];
        dateFormater.dateFormat = @"yyyy.M.d";
        NSString *dayStr = [dateFormater stringFromDate:dateValue];
        
        NSDateFormatter *timeFormater = [[NSDateFormatter alloc] init];
        timeFormater.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        [timeFormater setDateFormat:@"h:mm a"];
        NSString *timeStr = [timeFormater stringFromDate:dateValue];
        
        int photo_count = [[dayHistory objectForKey:@"photo_count"] intValue];
        
        NSMutableArray *dayDiary;
        for (int j=0; j<showList.count; j++) {
            NSDictionary *_dayDiary = [showList objectAtIndex:j];
            NSString *_dayStr = [_dayDiary objectForKey:@"day"];
            if ([_dayStr isEqualToString:dayStr]) {
                dayDiary = [_dayDiary objectForKey:@"detail"];
                break;
            }
        }
        if (dayDiary==nil) {
            dayDiary = [NSMutableArray array];
            NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
            [showDict setObject:dayStr forKey:@"day"];
            [showDict setObject:dayDiary forKey:@"detail"];
            [showList addObject:showDict];
        }
        
        NSMutableDictionary *timeDiary = [NSMutableDictionary dictionary];
        NSString *temperature = [dayHistory objectForKey:@"temperature"];
        [timeDiary setObject:temperature forKey:@"value"];
        
        NSString *description = [dayHistory objectForKey:@"description"];
        
        NSString *symptonStr = @"";
        NSArray *symptons = [self getSymptons:[dayHistory objectForKey:@"symptoms"]];
        if (symptons==nil||symptons.count==0) {
            symptonStr = @"";
        }
        else{
            for (int i=0; i<symptons.count; i++) {
                NSNumber *tag = [symptons objectAtIndex:i];
                NSString *name = [[GlobalTool shared] getSymptonNameByTag:tag];
                symptonStr = [symptonStr stringByAppendingString:[NSString stringWithFormat:@"%@",name]];
                symptonStr = [symptonStr stringByAppendingString:@" "];
            }
        }
        [timeDiary setObject:symptonStr forKey:@"symbton"];
        [timeDiary setObject:timeStr forKey:@"time"];
        [timeDiary setObject:date forKey:@"date"];
        [timeDiary setObject:[NSNumber numberWithInt:photo_count] forKey:@"photo_count"];
        [timeDiary setObject:tid forKey:@"tid"];
        [timeDiary setObject:description forKey:@"desc"];
        [timeDiary setObject:member_id forKey:@"member_id"];
        [timeDiary setObject:pics forKey:@"pics"];
        [dayDiary addObject:timeDiary];
    }
    
    _beanHistoryList = showList;
    return _beanHistoryList;
}

/**
 *  点击添加按钮
 */
- (void)onClickAddDiary {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Second" bundle:nil];
    AddMedicalRecordViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"AddMedicalRecordViewController"];
    [vc setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:vc animated:YES];
}

/**
 *  点击图片
 */
- (void)tapImageView:(UITapGestureRecognizer *)recognizer {
    UIImageView *imageView = (UIImageView *)[recognizer view];
    self.browser = [[CXPhotoBrowser alloc] initWithDataSource:self delegate:self];
    self.photoDataSource = [NSMutableArray array];
    
    for (int i = 0; i < self.picsArray.count; i++) {
        CXPhoto *photo = [[CXPhoto alloc] initWithURL:[NSURL URLWithString:self.picsArray[i]]];
        [self.photoDataSource addObject:photo];
    }
    [self.browser setInitialPageIndex:imageView.tag];
    [self presentViewController:self.browser animated:NO completion:nil];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(CXPhotoBrowser *)photoBrowser
{
    return [self.photoDataSource count];
}

- (id <CXPhotoProtocol>)photoBrowser:(CXPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < self.photoDataSource.count)
        return [self.photoDataSource objectAtIndex:index];
    return nil;
}

@end
