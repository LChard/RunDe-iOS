//
//  CCAlertView.m
//  CCLiveCloud
//
//  Created by 何龙 on 2019/1/25.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCAlertView.h"

@interface CCAlertView ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView * alertTableView;//提示列表

@property (nonatomic, strong) NSMutableArray * titleArr;//盛放内容的数组

@property (nonatomic, assign) CCAlertStyle  alertStyle;//弹窗的样式

@property (nonatomic, strong) UIView       * alertBgView;//提示框背景视图

@property (nonatomic, strong) UILabel      * titleLabel;//提示label
@property (nonatomic, strong) UIImageView      * titleimageView;//提示图片

@property (nonatomic, strong) UIButton     * cancelButton;//取消按钮
@property (nonatomic, copy)   NSString     * cancelText;//取消

@property (nonatomic, strong) UIButton     * sureButton;//确认按钮
@property (nonatomic, copy)   NSString     * sureText;//确认

@property (nonatomic, copy)   SureActionBlock sureBlock;//确认按钮回调

@end

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define CELLHEIGHT 50
#define ALERTWIDTH 285
#define ALERTHEIGHT 165
@implementation CCAlertView

//初始化方法
-(instancetype)initWithTitle:(NSString *)title
                  alertStyle:(CCAlertStyle)alertStyle
                   actionArr:(NSArray *)arr{
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.titleLabel.text = title;
        self.alertStyle = alertStyle;
        [self.titleArr addObjectsFromArray:arr];
        [self setUI];
    }
    return self;
}
//弹窗初始化方法
-(instancetype)initWithAlertTitle:(NSString *)title
                       sureAction:(NSString *)sure
                     cancelAction:(NSString *)cancel
                        sureBlock:(SureActionBlock)block{
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.titleLabel.text = title;
        self.alertStyle = CCAlertStyleActionAlert;
        if (sure != nil) {
            self.sureText = sure;//初始化确认字样
        }
        if (cancel != nil) {
            self.cancelText = cancel;//初始化取消字样
        }
        self.sureBlock = block;
        [self setUI];
    }
    return self;
}
//弹窗初始化方法
-(instancetype)initRunDeWithAlertTitle:(NSString *)title
                                  mode:(NSInteger)mode{
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        [self setRunDeUI:mode];
    }
    return self;
}
-(instancetype)initAnnouncementAlertTitle:(NSString *)title
                       sureAction:(NSString *)sure
                        sureBlock:(SureActionBlock)block{
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        if (sure != nil) {
            self.sureText = sure;//初始化确认字样
        }
        self.alertStyle = CCAlertStyleActionAlert;
        self.sureBlock = block;
        [self setAnnouncementUI:title];
    }
    return self;
}
#pragma mark - setUI
-(void)setUI{
    if (self.alertStyle == CCAlertStyleActionSheet) {
        //加载样式表样式
        [self createUIWithSheetStyle];
    }else if (self.alertStyle == CCAlertStyleActionAlert){
        //加载弹窗样式
        [self createUIWithAlertStyle];
    }
}
- (void)setAnnouncementUI:(NSString *)mode {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.alertBgView.alpha = 1.f;
    //添加提示框背景
    [self addSubview:self.alertBgView];
    [self.alertBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(200);
    }];

    //添加提示文字
    self.titleLabel.text = @"系统公告";
    [self.alertBgView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.alertBgView);
        make.top.equalTo(self.alertBgView).offset(30);
    }];
   UILabel *label = [[UILabel alloc] init];
   label.numberOfLines = 0;
   [self addSubview:label];

   NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:mode attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 15],NSForegroundColorAttributeName: [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]}];

   label.attributedText = string;
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.alertBgView);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(15);
        make.left.equalTo(self.alertBgView).offset(15);
        make.right.equalTo(self.alertBgView).offset(-15);
    }];
    
    
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.alertBgView);
        make.height.mas_equalTo(50);
    }];
    [btn setTitle:@"知道了" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0] forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:54/255.0 green:54/255.0 blue:54/255.0 alpha:1.0]]];
    btn.layer.cornerRadius = 8;
    [btn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithHexString:@"#D2D3D5" alpha:1.0f];
    [self addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.alertBgView);
        make.bottom.equalTo(btn.mas_top);
        make.height.mas_equalTo(1);
    }];

}
- (void)btnClicked {
     if (_sureBlock) {
               _sureBlock();
           }
}
- (void)setRunDeUI:(NSInteger)mode {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.alertBgView.alpha = 1.f;
    //添加提示框背景
    [self addSubview:self.alertBgView];
    [self.alertBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.height.mas_equalTo(150);
    }];
    
    [self addSubview:self.titleimageView];
    [self.titleimageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.alertBgView);
        make.top.equalTo(self.alertBgView).offset(15);
        make.width.height.mas_equalTo(43);
    }];
    UILabel *label = [[UILabel alloc] init];
    if (mode == 1) {
        self.titleimageView.image = [UIImage imageNamed:@"Forbidden"];
        self.titleLabel.text = @"全体禁言";
        label.text = @"讲师已开启全体禁言";
    } else {
         self.titleimageView.image = [UIImage imageNamed:@"Relieve"];
        self.titleLabel.text = @"解除全体禁言";
        label.text = @"讲师已解除全体禁言";
    }
    
    //添加提示文字
    [self.alertBgView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.titleimageView);
        make.top.equalTo(self.titleimageView.mas_bottom).offset(15);
    }];
    
    label.numberOfLines = 0;
    [self addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.alertBgView);
        make.bottom.equalTo(self.alertBgView.mas_bottom).offset(-20);
    }];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:label.text attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 15],NSForegroundColorAttributeName: [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]}];

    label.attributedText = string;

}
#pragma mark - 设置sheet样式
-(void)createUIWithSheetStyle{
    [self.titleArr addObject:@""];
    [self.titleArr addObject:@"取消"];
    //初始化tableView
    [self addSubview:self.alertTableView];
    self.alertTableView.frame = CGRectMake(0, SCREENHEIGHT, SCREENWIDTH, [self.titleArr count] * CELLHEIGHT);
    //加载动画效果
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        self.alertTableView.frame = CGRectMake(0, SCREENHEIGHT - [self.titleArr count] * CELLHEIGHT + 30, SCREENWIDTH, [self.titleArr count] * CELLHEIGHT - 40);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alertTableView.frame = CGRectMake(0, SCREENHEIGHT - [self.titleArr count] * CELLHEIGHT + 40, SCREENWIDTH, [self.titleArr count] * CELLHEIGHT - 40);
        } completion:nil];
    }];
}
#pragma mark - 设置alert样式
-(void)createUIWithAlertStyle{
    
    //添加提示框背景
    [self addSubview:self.alertBgView];
    
    //添加提示文字
    [self.alertBgView addSubview:self.titleLabel];
    
    //添加取消按钮
    if (_cancelText != nil) {
        [self.alertBgView addSubview:self.cancelButton];
    }
    
    //添加确定按钮
    if (_sureText != nil) {
        [self.alertBgView addSubview:self.sureButton];
    }
    
    //加载动画效果
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        self.alertBgView.alpha = 1.f;
        self.alertBgView.frame = CGRectMake((SCREENWIDTH - ALERTWIDTH * 0.7) / 2, (SCREENHEIGHT - ALERTHEIGHT * 0.7) / 2, ALERTWIDTH * 0.7, ALERTHEIGHT * 0.7);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alertBgView.frame = CGRectMake((SCREENWIDTH - ALERTWIDTH) / 2, (SCREENHEIGHT - ALERTHEIGHT) / 2, ALERTWIDTH, ALERTHEIGHT);
        } completion:^(BOOL finished) {
            [self updateBtnsFrame];
        }];
    }];
}
//设置btn的样式
-(void)updateBtnsFrame{
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(ALERTWIDTH - CELLHEIGHT * 2, MAXFLOAT)];
    self.titleLabel.frame = CGRectMake((ALERTWIDTH - size.width) / 2, 65 - size.height, size.width, size.height);
    if (_sureText != nil && _cancelText != nil) {
        self.cancelButton.frame = CGRectMake(30, 105, 105, 40);
        self.sureButton.frame = CGRectMake(150, 105, 105, 40);
        return;
    }
    CGRect btnFrame = CGRectMake((ALERTWIDTH - 105) / 2, 105, 105, 40);
    if (_sureText != nil && _cancelText == nil) {
        self.sureButton.frame = btnFrame;
    }else{
        self.cancelButton.frame = btnFrame;
    }
}
#pragma mark - 懒加载
-(UITableView *)alertTableView{
    if (!_alertTableView) {
        _alertTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _alertTableView.backgroundColor = [UIColor clearColor];
        _alertTableView.scrollEnabled = NO;
        _alertTableView.delegate = self;
        _alertTableView.dataSource = self;
        _alertTableView.showsVerticalScrollIndicator = NO;
        _alertTableView.estimatedRowHeight = 0;
        _alertTableView.estimatedSectionHeaderHeight = 0;
        _alertTableView.estimatedSectionFooterHeight = 0;
    }
    return _alertTableView;
}
//公聊数组
-(NSMutableArray *)titleArr {
    if(!_titleArr) {
        _titleArr = [[NSMutableArray alloc] init];
    }
    return _titleArr;
}
//alertBgView
-(UIView *)alertBgView{
    if (!_alertBgView) {
        _alertBgView = [[UIView alloc] init];
        _alertBgView.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithHexString:@"#363636" alpha:1.0f]];
        _alertBgView.layer.masksToBounds = YES;
        _alertBgView.layer.cornerRadius = 8;
        _alertBgView.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
        _alertBgView.alpha = 0.0;
    }
    return _alertBgView;
}
//titleLabel
-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor colorWithLight:[UIColor colorWithHexString:@"#333333" alpha:1.0f] Dark:[UIColor whiteColor]];
        _titleLabel.backgroundColor = [UIColor clearColor];
//        _titleLabel.layer.shadowOffset = CGSizeMake(0, -3);
        _titleLabel.layer.shadowColor = [UIColor grayColor].CGColor;
        _titleLabel.layer.shadowRadius = 20;
        _titleLabel.layer.masksToBounds = YES;
        _titleLabel.layer.shadowOpacity = 0.7f;
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}
- (UIImageView *)titleimageView {
    if (!_titleimageView) {
        _titleimageView = [[UIImageView alloc] init];
        
    }
    return _titleimageView;
}
//cancelBtn
-(UIButton *)cancelButton{
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self createBtn:_cancelButton title:_cancelText];
    }
    return _cancelButton;
}
//sureBtn
-(UIButton *)sureButton{
    if (!_sureButton) {
        _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self createBtn:_sureButton title:_sureText];
        [_sureButton setBackgroundColor:[UIColor orangeColor]];
        [_sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _sureButton.layer.borderWidth = 0;
        _sureButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    return _sureButton;
}
//创建btn
-(void)createBtn:(UIButton *)btn title:(NSString *)title{
    [btn setTitle:title forState:UIControlStateNormal];
    btn.layer.masksToBounds = YES;
    btn.layer.cornerRadius = 20;
    btn.layer.borderColor = [UIColor grayColor].CGColor;
    btn.layer.borderWidth = 1.f;
    btn.backgroundColor = [UIColor clearColor];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)buttonClicked:(UIButton *)btn{
    [self removeAlertView];
    if (btn == self.sureButton) {
        if (_sureBlock) {
            _sureBlock();
        }
    }
}
#pragma mark - tableViewDelegate And DataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellId = @"DefaultBaseCellIdentifier";
    //TODO
//    if ([self.titleArr count] - 1 < (long)indexPath.row) {
//        return nil;//防止数组越界
//    }
    NSString *title = [self.titleArr objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    if (indexPath.row == [self.titleArr count] - 2) {
        cell.backgroundColor = [UIColor grayColor];
        cell.alpha = 0.7f;
        return cell;
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = title;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == [self.titleArr count] - 2) {
        return 10;//添加一个分割线
    }
    return 50;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.titleArr count];
}

//选中某一个cell
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ((long)indexPath.row == [self.titleArr count] - 1) {
//        NSLog(@"点击了取消按钮");
        [self removeSheetView];
        if (_cancelActionBlock) {
            _cancelActionBlock();
        }
    }else{
        if (_actionBlock) {
            _actionBlock((long)indexPath.row);
        }
        [self removeSheetView];
    }
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (_alertStyle == CCAlertStyleActionSheet) {
        [self removeSheetView];
    }
}
#pragma mark - 移除视图
//移除样式表视图
-(void)removeSheetView{
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.3 animations:^{
        self.alertTableView.frame = CGRectMake(0, SCREENHEIGHT, SCREENWIDTH, self.alertTableView.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
//移除提示框视图
-(void)removeAlertView{
    for (UIView *view in self.alertBgView.subviews) {
        [view removeFromSuperview];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor clearColor];
        self.alertBgView.alpha = 0.0f;
        self.alertBgView.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
    }completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
-(void)dealloc{
//    NSLog(@"移除视图");
}
@end
