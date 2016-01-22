//
//  ProblemViewController.m
//  MeecaaStickApp
//
//  Created by SoulJa on 15/12/3.
//  Copyright © 2015年 SoulJa. All rights reserved.
//

#import "ProblemViewController.h"

@interface ProblemViewController () <UITextViewDelegate>
@property (strong, nonatomic) UITextView *textView;
@property (nonatomic,strong) UILabel *placeholderLabel;
@end

@implementation ProblemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置Nav
    [self setupNav];
    
    [self.view setBackgroundColor:UIVIEW_BACKGROUND_COLOR];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 64, kScreen_Width, 200)];
    [self.textView becomeFirstResponder];
    self.textView.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:self.textView];
    
    self.textView.delegate = self;
    
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.frame = CGRectMake(0, 0, self.textView.bounds.size.width, 40);
    placeholderLabel.text = @"请输入你的问题，谢谢!";
    [placeholderLabel setTextColor:[UIColor grayColor]];
    self.placeholderLabel = placeholderLabel;
    [self.textView addSubview:placeholderLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(submitProblemSuccessNotification) name:@"SubmitProblemSuccessNotification" object:nil];
}

- (void)submitProblemSuccessNotification {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/**
 *  设置Nav
 */
- (void)setupNav {
    [self.navigationController.navigationBar setBackgroundImage:[[GlobalTool shared] createImageWithColor:NAVIGATIONBAR_BACKGROUND_COLOR] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationItem.title = @"问题反馈";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"message_back_icon"] style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"提交" style:UIBarButtonItemStyleDone target:self action:@selector(onClickSubmit)];
}

- (void)goBack {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.placeholderLabel.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        self.placeholderLabel.hidden = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - 提交反馈问题
- (void)onClickSubmit {
    //退出键盘
    [self.view endEditing:YES];
    if (self.textView.text.length > 200) { //判断输入字数
        [SVProgressHUD showErrorWithStatus:@"请输入少于200个字符!"];
        return;
    } else if (self.textView.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"请输入内容!"];
        return;
    } else {
        [SVProgressHUD show];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [[HttpTool shared] submitProblemWithText:self.textView.text];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
@end
