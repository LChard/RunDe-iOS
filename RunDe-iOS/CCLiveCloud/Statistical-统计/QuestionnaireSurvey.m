//
//  VoteView.m
//  CCLiveCloud
//
//  Created by MacBook Pro on 2018/12/20.
//  Copyright © 2018 MacBook Pro. All rights reserved.
//

#import "QuestionnaireSurvey.h"
#import "UIButton+UserInfo.h"
#import "UITextView+UserInfo.h"
#import "UIColor+RCColor.h"

@interface QuestionnaireSurvey()<UITextViewDelegate,UIScrollViewDelegate>

@property(nonatomic,strong)UIImageView              *topBgView;//头部背景视图
@property(nonatomic,strong)UILabel                  *titleLabel;//头部标题
@property(nonatomic,strong)UIButton                 *closeBtn;//关闭按钮

@property(nonatomic,strong)UIButton                 *submitBtn;//提交按钮
@property(nonatomic,strong)UIView                   *view;//背景父视图
@property(nonatomic,assign)BOOL                     isScreenLandScape;//判断是否是全屏
@property(nonatomic,assign)BOOL                     isStastic;//是否是统计
@property(nonatomic,copy)  CloseBlock               closeblock;//关闭按钮回调
@property(strong,nonatomic)UIScrollView             *scrollView;//用于盛放问题的ScrollView
//@property(strong,nonatomic)NSDictionary             *questionDic;
@property(nonatomic,assign)CGRect                   keyboardRect;//键盘的Rect
@property(nonatomic,strong)UITextView               *selectedTextView;//已经选择的textView
@property(nonatomic,strong)UILabel                  *msgLabel;//提示文字
@property(nonatomic,strong)NSMutableArray           *buttonIdArray;//选择buttonId数组
@property(nonatomic,strong)NSMutableArray           *correctLabelArray;//正确label数组
@property(nonatomic,strong)NSMutableArray           *buttonArray;//按钮数组
@property(nonatomic,strong)NSMutableArray           *textViewArray;//问答图数组
@property(nonatomic,assign)NSInteger                selectQuestionCount;
@property(nonatomic,strong)NSDictionary             *questionnaireDic;//问卷字典
@property(nonatomic,strong)NSDictionary             *selectDic;//选择后的字典
@property(nonatomic,assign)NSInteger                submitedAction;//是否显示答案1显示其他不显示
@property(nonatomic,assign)CGFloat                  submitAnswerViewerCount;//提交人数

@property(nonatomic,copy)  CommitBlock              commitblock;//提交回调
@property(nonatomic,strong)UILabel                  *correctLabel;//正确答案前面的提示
@property(nonatomic,assign)NSInteger                lastType;//
#pragma mark - 新加属性
@property(nonatomic, strong)UIView                  *referenceViewPreview;//初始参照视图Preview
@property(nonatomic, strong)UIView                  *referenceView;//参照视图view
@property(nonatomic, strong)UIView                  *lastView;//视图约束最后一个
@property(nonatomic,assign)CGFloat                  contentWidth;//按钮背景宽度
@property(nonatomic,assign)CGFloat                  contentHeight;//按钮背景宽度

@end

//答题
@implementation QuestionnaireSurvey
/**
 初始化方法
 
 @param closeblock 关闭视图回调
 @param commitblock 提交回调
 @param questionnaireDic 问卷字典
 @param isScreenLandScape 是否全屏
 @param isStastic 是否是统计
 @return self
 */
- (instancetype)initWithCloseBlock:(CloseBlock)closeblock CommitBlock:(CommitBlock)commitblock questionnaireDic:(NSDictionary *)questionnaireDic isScreenLandScape:(BOOL)isScreenLandScape isStastic:(BOOL)isStastic{
    
    self = [super init];
    if(self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.isScreenLandScape  = isScreenLandScape;
        self.isStastic          = isStastic;
        self.closeblock         = closeblock;
        self.commitblock        = commitblock;
        self.questionnaireDic   = questionnaireDic;
        self.submitedAction     = [questionnaireDic[@"submitedAction"] integerValue];//
        self.submitAnswerViewerCount = (CGFloat)[questionnaireDic[@"submitAnswerViewerCount"] integerValue];
        //        self.lastType = 2;
        //如果是强制答卷，隐藏关闭按钮
        //判断当前是否是强制答卷
        //        BOOL forcibly = NO;
        //        if([[questionnaireDic allKeys] containsObject:@"forcibly"]){
        //            forcibly = [questionnaireDic[@"forcibly"] boolValue];
        //        }
        //        if (forcibly) {//隐藏按钮
        //            self.closeBtn.hidden = YES;
        //        }
        [self setUpUI];
        [self addObserver];
    }
    return self;
}
#pragma mark - UI总布局
//UI布局
-(void)setUpUI{
    //初始化已经选择的问题的总数
    _selectQuestionCount = 0;
    
    //初始化背景视图
    [self addBgView];
    
    //添加其他基础视图
    [self addOtherViews];
    
    //添加问卷标题
    [self addTitle];
    
    //设置问题视图
    [self addQuestionView];
    
    //设置msgLabel和提交按钮
    [self addMsgLabelAndCommitBtn];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];

    
    //计算scrollView的contentSize
    self.scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, CGRectGetMaxY(self.lastView.frame) + 30);

//    self.scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, _submitBtn.frame.origin.y + CCGetRealFromPt(60) + CCGetRealFromPt(30));
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

}
#pragma mark - 设置msgLabel和提交按钮

/**
 添加提示信息label和提交按钮
 */
-(void)addMsgLabelAndCommitBtn{
    float textMaxWidth = CCGetRealFromPt(610);
    //初始化提交提示
    NSString *msgStr = COMMITSUCCESS;
    CGSize msgSizeNum = [self getSizeByStr:msgStr minFontHeight:CCGetRealFromPt(28) maxFontHeight:CCGetRealFromPt(28) UIFont:[UIFont boldSystemFontOfSize:FontSize_28] textMaxWidth:textMaxWidth lineSpacing:CCGetRealFromPt(0)];
    
    //初始化提交后的提示信息
    _msgLabel = [[UILabel alloc] init];
    _msgLabel.text = msgStr;
    _msgLabel.textColor = CCRGBColor(23,188,47);
    _msgLabel.textAlignment = NSTextAlignmentCenter;
    _msgLabel.font = [UIFont boldSystemFontOfSize:FontSize_28];
    _msgLabel.hidden = YES;//初始化时隐藏提示信息
    //设置提示信息约束
    [self.view addSubview:_msgLabel];
    float offset = self.isScreenLandScape?CCGetRealFromPt(37):CCGetRealFromPt(53);
    [_msgLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.scrollView);
        make.top.mas_equalTo(self.referenceViewPreview.mas_bottom).offset(offset);
        make.width.mas_equalTo(self.scrollView);
        make.height.mas_equalTo(msgSizeNum.height);
    }];
    
    //设置提交按钮约束
    [self.view addSubview:self.submitBtn];
    [_submitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.bottom.mas_offset(-10);
        make.width.offset(200);
        make.height.mas_equalTo(44);
    }];
    /*
    //设置提交按钮约束
    [_scrollView addSubview:self.submitBtn];
    [_submitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.scrollView);
        make.top.mas_equalTo(self.msgLabel.mas_bottom).offset(CCGetRealFromPt(30));
        //        make.left.equalTo(self.scrollView).offset(55);
        //        make.right.equalTo(self.scrollView).offset(-55);
        make.width.offset(200);
        make.height.mas_equalTo(44);
    }];
     */
}
#pragma mark - 设置问题视图-------------start----------

/**
 设置问题视图
 */
-(void)addQuestionView{
    float textMaxWidth = CCGetRealFromPt(610);
    NSMutableArray *subjectsArray = _questionnaireDic[@"subjects"];
    
    //遍历所有问题,设置显示样式
    for(int i = 0;i < [subjectsArray count];i++) {
        //得到每个问题的字典
        NSDictionary *opthionsDic = subjectsArray[i];
        if([opthionsDic[@"type"] intValue] == 2) return;
        //设置leftLabel
        [self addleftLabel:i textMaxWidth:textMaxWidth subjectsArray:subjectsArray];
        
        //设置centerLabel
        //        [self addCenterLabel:subjectsArray label:self.lastView index:i];
        //
        //        //添加分隔符
        [self addCenterImage:self.lastView];
        
        //添加问题内容
        [self addQuestionLabel:opthionsDic lastView:self.lastView];
        //设置问题选项视图
        NSArray *optionsArray = opthionsDic[@"options"];
        //如果是单选或者多选
        if(([opthionsDic[@"type"] intValue] == 0 || [opthionsDic[@"type"] intValue] == 1) && optionsArray) {
            //设置单选和多选
            for(int j = 0;j < [optionsArray count];j++) {
                NSDictionary *optionDic = optionsArray[j];
                //设置选项文本
                [self addOptionLabel:optionDic lastView:self.lastView j:j selectedBtn:opthionsDic optionsArray:optionsArray index:i];
                
            }
        }
        //        else if([opthionsDic[@"type"] intValue] == 2){//设置问答视图
        //            //添加简介视图
        //            [self addTextView:i opthionsDic:opthionsDic];
        //        }
    }
}
#pragma mark - 设置选项视图

/**
 添加条形统计图
 
 @param optionsArray 选项数组
 @param j j
 @param selectButton 选择btn
 */
-(void)addStasticView:(NSArray *)optionsArray
                    j:(int)j
         selectButton:(UIButton *)selectButton
{
    //添加统计条形图
    if (self.isStastic) {
        CGFloat  submitCount;//如果回答的人数为0，直接将百分比至为零
        if (self.submitAnswerViewerCount == 0) {
            submitCount = 0;
        }else{
            submitCount = (CGFloat)([optionsArray[j][@"selectedCount"] integerValue] / self.submitAnswerViewerCount);
        }
        selectButton.userInteractionEnabled = NO;
        //背景
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectZero];
        bgView.backgroundColor = [UIColor colorWithHexString:@"#edf5ff" alpha:1.0f];
        //                    bgView.backgroundColor = [UIColor brownColor];
        [_scrollView addSubview:bgView];
        [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(selectButton);
            //                        make.right.equalTo(self).offset(-100);
            make.width.mas_equalTo(CCGetRealFromPt(400));
            make.top.mas_equalTo(self.referenceView.mas_bottom).offset(10);
            make.height.mas_equalTo(15);
        }];
        //数据
        UIView *dataView = [[UIView alloc] initWithFrame:CGRectZero];
        dataView.backgroundColor = [UIColor colorWithHexString:@"#43b50f" alpha:1.0f];
        [_scrollView addSubview:dataView];
        [dataView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(selectButton);
            make.width.mas_equalTo(bgView).multipliedBy(submitCount);
            make.top.mas_equalTo(self.referenceView.mas_bottom).offset(10);
            make.height.mas_equalTo(15);
        }];
        
        //百分比
        UILabel *percent = [[UILabel alloc] init];
        percent.text = [NSString stringWithFormat:@"%ld人(%.1f%%)",(long)[optionsArray[j][@"selectedCount"] integerValue],submitCount*100];
        percent.textAlignment = NSTextAlignmentCenter;
        [percent setTextColor:[UIColor darkGrayColor]];
        percent.font = [UIFont systemFontOfSize:12];
        [_scrollView addSubview:percent];
        [percent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(bgView);
            make.left.equalTo(bgView.mas_right).offset(2);
        }];
    }
}
/**
 选项文本
 
 @param optionDic optionDic description
 @param ALabel ALabel description
 */
-(void)addOptionLabel:(NSDictionary *)optionDic
             lastView:(UIView *)ALabel
                    j:(int)j
          selectedBtn:(NSDictionary *)opthionsDic
         optionsArray:(NSArray *)optionsArray
                index:(int)i
{
    //计算选项内容的size
    CGFloat maxOptionContentWidth = self.isScreenLandScape ? SCREEN_WIDTH-150 : CCGetRealFromPt(501);
    NSString *str = [NSString stringWithFormat:@"   %@",optionDic[@"content"]];
    NSMutableAttributedString *textAttriOption = [[NSMutableAttributedString alloc] initWithString:str];
    [textAttriOption addAttribute:NSForegroundColorAttributeName value:CCRGBColor(102,102,102) range:NSMakeRange(0, textAttriOption.length)];
    NSMutableParagraphStyle *styleOption = [[NSMutableParagraphStyle alloc] init];
    //                styleOption.minimumLineHeight = CCGetRealFromPt(26);
    styleOption.lineSpacing = CCGetRealFromPt(5);
    styleOption.alignment = NSTextAlignmentLeft;
    styleOption.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *dictOption = @{NSFontAttributeName:[UIFont systemFontOfSize:FontSize_26],NSParagraphStyleAttributeName:styleOption};
    [textAttriOption addAttributes:dictOption range:NSMakeRange(0, textAttriOption.length)];
    
    CGSize textSizeOption = [textAttriOption boundingRectWithSize:CGSizeMake(maxOptionContentWidth, CGFLOAT_MAX)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                          context:nil].size;
    textSizeOption.width = ceilf(textSizeOption.width);
    textSizeOption.height = ceilf(textSizeOption.height);
    self.contentWidth = textSizeOption.width;
    self.contentHeight = textSizeOption.height;
    //初始化选项内容文本,占位用 内容在btn上显示
    UILabel *contentLabelOption = [[UILabel alloc] init];
    contentLabelOption.numberOfLines = 0;
    contentLabelOption.backgroundColor = CCClearColor;
    contentLabelOption.textColor = CCRGBColor(51,51,51);
    contentLabelOption.textAlignment = NSTextAlignmentLeft;
    contentLabelOption.userInteractionEnabled = NO;
    //    contentLabelOption.attributedText = textAttriOption;
    [_scrollView addSubview:contentLabelOption];
    [contentLabelOption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(ALabel.mas_right).offset(-CCGetRealFromPt(20));
        if(j == 0) {
            make.top.mas_equalTo(self.referenceView.mas_bottom).offset(CCGetRealFromPt(10));
        } else {
            make.top.mas_equalTo(self.referenceView.mas_bottom).offset(CCGetRealFromPt(58));
        }
        make.width.mas_equalTo(textSizeOption.width);
        make.height.mas_equalTo(textSizeOption.height);
    }];
    
    self.referenceView = contentLabelOption;
    
    self.referenceViewPreview = contentLabelOption;
    //设置选择btn
    UIButton *selecteBtn = [self addSelectedBtn:opthionsDic optionsArray:optionsArray optionDic:optionDic index:i j:j lastView:self.lastView contentLabelOption:textAttriOption];
    selecteBtn.tag = 1000 + j;
    //判断是否正确
    //     [self addCorrectLabel:self.lastView optionsArray:optionsArray j:j];
    
    //初始化问题序号
    [self addALabel:self.lastView j:j];
    
    
    //添加条形统计图
    [self addStasticView:optionsArray j:j selectButton:selecteBtn];
}
/**
 选项序号
 
 @param selectButton selectButton description
 @param j j description
 */
-(void)addALabel:(UIView *)selectButton
               j:(int)j{
    NSString *AStr = @"A. ";
    CGSize ASize = [self getSizeByStr:AStr minFontHeight:CCGetRealFromPt(26) maxFontHeight:CCGetRealFromPt(26) UIFont:[UIFont boldSystemFontOfSize:FontSize_26] textMaxWidth:CCGetRealFromPt(610) lineSpacing:CCGetRealFromPt(0)];
    //初始化选项序号   A: B: C: D:
    UILabel *ALabel = [[UILabel alloc] init];
    ALabel.text = [NSString stringWithFormat:@"%c.",'A' + j];
    ALabel.textColor = CCRGBColor(102,102,102);
    ALabel.textAlignment = NSTextAlignmentLeft;
    ALabel.font = [UIFont boldSystemFontOfSize:FontSize_26];
    ALabel.tag = 10000 + j;
    //添加选项序号约束
    [_scrollView addSubview:ALabel];
    [ALabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.scrollView.mas_left).offset(CCGetRealFromPt(40));
        //        make.centerY.mas_equalTo(selectButton.mas_centerY);
        make.top.mas_equalTo(selectButton).offset(6);
        make.width.mas_equalTo(ASize.width);
        make.height.mas_equalTo(ASize.height);
    }];
    self.lastView = ALabel;
}
/**
 添加正确答案提示
 
 @param selectButton 选择的btn
 @param optionsArray 选项数组
 @param j 下标
 */
-(void)addCorrectLabel:(UIView *)selectButton
          optionsArray:(NSArray *)optionsArray
                     j:(int)j{
    //需要判断是否正确
    if ([optionsArray[j][@"correct"] integerValue] == 1) {
        
        UILabel * correctLabel = [[UILabel alloc] init];
        _correctLabel = correctLabel;
        correctLabel.text = @"正确";
        correctLabel.textColor = CCRGBColor(67,181,15);
        correctLabel.textAlignment = NSTextAlignmentLeft;
        correctLabel.font = [UIFont boldSystemFontOfSize:FontSize_24];
        correctLabel.hidden = self.isStastic ? NO : YES;
        [_scrollView addSubview:correctLabel];
        [correctLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(selectButton);
            make.right.mas_equalTo(selectButton.mas_left).offset(-5);
        }];
        [self.correctLabelArray addObject:correctLabel];
    }
}
- (UIImage *)imageWithColor:(UIColor *)color {
    
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}
/**
 设置选择的btn
 
 @param opthionsDic 问题总字典
 @param optionsArray 问题总数组
 @param optionDic 单个问题字典
 @param i 问题下标
 @param j 答案下标
 */
-(UIButton *)addSelectedBtn:(NSDictionary *)opthionsDic
               optionsArray:(NSArray *)optionsArray
                  optionDic:(NSDictionary *)optionDic
                      index:(int)i
                          j:(int)j
                   lastView:(UIView *)ALabel
         contentLabelOption:(NSMutableAttributedString *)contentLabelOption
{
    NSString  *string =  contentLabelOption.string;
    
    NSMutableAttributedString  *att1 = [[NSMutableAttributedString alloc]initWithString:string];
    
    NSMutableParagraphStyle *styleOption = [[NSMutableParagraphStyle alloc] init];
    //                styleOption.minimumLineHeight = CCGetRealFromPt(26);
    styleOption.lineSpacing = CCGetRealFromPt(5);
    styleOption.alignment = NSTextAlignmentLeft;
    styleOption.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *dictOption = @{NSFontAttributeName:[UIFont systemFontOfSize:FontSize_26],NSParagraphStyleAttributeName:styleOption,NSForegroundColorAttributeName:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]};
    [att1 addAttributes:dictOption range:NSMakeRange(0, string.length)];
    //    [att1 addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0] range:NSMakeRange(0,string.length)];
    //设置选项按钮的图片样式
    UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    selectButton.hidden = self.isStastic? YES: NO;
    [selectButton addTarget:self action:@selector(selectBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    //    if([opthionsDic[@"type"] intValue] == 0) {
    selectButton.layer.cornerRadius = 4.0f;
    selectButton.clipsToBounds = YES;
    [selectButton setBackgroundImage:[self imageWithColor:[UIColor colorWithLight:[UIColor colorWithRed:245/255.0 green:241/255.0 blue:246/255.0 alpha:1.0] Dark:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]]] forState:UIControlStateNormal];
    selectButton.titleLabel.numberOfLines = 0;
    selectButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [selectButton setTitleEdgeInsets:UIEdgeInsetsMake(6,10,5,5)];
    //    NSString * str = [NSString stringWithFormat:@"%@",contentLabelOption];
    //    [contentLabelOption addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0] range:NSMakeRange(0,contentLabelOption.length)];
    [selectButton setAttributedTitle:contentLabelOption forState:UIControlStateNormal];
    
    //    [selectButton setTitle:str forState:UIControlStateNormal];
    //    NSMutableAttributedString * str = contentLabelOption;
    //    [str addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0] range:NSMakeRange(0,str.length)];
    //    [selectButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    //    [selectButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [selectButton setAttributedTitle:att1 forState:UIControlStateSelected];
    selectButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    //题号-类型（0：单选，1:多选）-选项个数-选项索引值-题目ID-选项ID
    NSString *buttonId = [NSString stringWithFormat:@"%d-%d-%d-%d-%@-%@",i,[opthionsDic[@"type"] intValue],(int)[optionsArray count],j,opthionsDic[@"id"],optionDic[@"id"]];
    selectButton.userid = buttonId;
    selectButton.correct  = optionsArray[j][@"correct"];
    [self.buttonArray addObject:selectButton];
    [self.buttonIdArray addObject:buttonId];
    
    [_scrollView addSubview:selectButton];
    
    [selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(CCGetRealFromPt(34));
        make.top.mas_equalTo(self.referenceView);
        //        make.width.mas_equalTo(270);
        make.height.mas_equalTo(self.contentHeight+10);
        make.right.equalTo(self.view).offset(-CCGetRealFromPt(34));
    }];
    
    self.lastView = selectButton;
    return selectButton;
}
#pragma mark - 设置简答视图

/**
 添加简答视图
 
 @param i 题号
 @param opthionsDic 简答题字典
 */
-(void)addTextView:(int)i
       opthionsDic:(NSDictionary *)opthionsDic{
    //初始化简答背景视图
    UIView *viewBG = [[UIView alloc] init];
    viewBG.backgroundColor = CCRGBColor(250,250,250);
    viewBG.hidden = self.isStastic? YES: NO;//如果是统计隐藏视图
    [_scrollView addSubview:viewBG];
    float width = self.isScreenLandScape?CCGetRealFromPt(550):CCGetRealFromPt(599);
    [viewBG mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.scrollView.mas_left).offset(CCGetRealFromPt(70));
        make.top.mas_equalTo(self.referenceView.mas_bottom).offset(CCGetRealFromPt(40));
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(CCGetRealFromPt(self.isStastic?1:143));
    }];
    
    viewBG.layer.borderColor = CCRGBColor(221,221,221).CGColor;
    viewBG.layer.borderWidth = 1;
    viewBG.tag = i + 1 + 100;
    self.referenceView.tag = viewBG.tag + 100;
    
    //添加问答题输入视图
    UITextView *uiTextView = [[UITextView alloc] init];
    uiTextView.backgroundColor = CCClearColor;
    uiTextView.font = [UIFont systemFontOfSize:FontSize_26];
    uiTextView.textColor = CCRGBColor(102,102,102);
    uiTextView.textAlignment = NSTextAlignmentLeft;
    uiTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    uiTextView.keyboardType = UIKeyboardTypeDefault;
    uiTextView.returnKeyType = UIReturnKeyDone;
    uiTextView.scrollEnabled = YES;
    uiTextView.userid = opthionsDic[@"id"];
    uiTextView.delegate = self;
    uiTextView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    if (!self.isStastic) {
        //如果不是统计，将视图添加至textView数组
        [self.textViewArray addObject:uiTextView];
        [viewBG addSubview:uiTextView];
        [uiTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(viewBG).offset(CCGetRealFromPt(20));
            make.top.mas_equalTo(viewBG).offset(CCGetRealFromPt(20));
            make.bottom.mas_equalTo(viewBG).offset(-CCGetRealFromPt(20));
            make.right.mas_equalTo(viewBG).offset(-CCGetRealFromPt(20));
        }];
    }
    self.referenceViewPreview = viewBG;
}
/**
 问题内容
 
 @param opthionsDic 问题字典
 @param leftLabel lastView
 */
-(void)addQuestionLabel:(NSDictionary *)opthionsDic
               lastView:(UIView *)leftLabel{
    //计算问题内容文本大小
    CGFloat maxContentWidth = self.isScreenLandScape ? self.scrollView.frame.size.width- 40 : SCREEN_WIDTH- 100;
    NSMutableAttributedString *textAttri = [[NSMutableAttributedString alloc] initWithString:opthionsDic[@"content"]];
    [textAttri addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0]] range:NSMakeRange(0, textAttri.length)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = CCGetRealFromPt(20);
    style.alignment = NSTextAlignmentLeft;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *dict = @{NSFontAttributeName:[UIFont systemFontOfSize:FontSize_28],NSParagraphStyleAttributeName:style};
    [textAttri addAttributes:dict range:NSMakeRange(0, textAttri.length)];
    
    CGSize textSize = [textAttri boundingRectWithSize:CGSizeMake(maxContentWidth, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                              context:nil].size;
    textSize.width = ceilf(textSize.width);
    textSize.height = ceilf(textSize.height);
    
    //初始化问题内容
    UILabel *contentLabelQue = [[UILabel alloc] init];
    contentLabelQue.numberOfLines = 0;
    contentLabelQue.backgroundColor = CCClearColor;
    contentLabelQue.textColor = CCRGBColor(51,51,51);
    contentLabelQue.textAlignment = NSTextAlignmentLeft;
    contentLabelQue.userInteractionEnabled = NO;
    contentLabelQue.attributedText = textAttri;
    //添加问题内容
    [_scrollView addSubview:contentLabelQue];
    [contentLabelQue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(leftLabel.mas_right).offset(-CCGetRealFromPt(10) + 1);
        //        make.right.mas_equalTo(self.scrollView.mas_right).offset(CCGetRealFromPt(10));
        make.top.mas_equalTo(leftLabel.mas_top).offset(-8);
        make.width.mas_equalTo(textSize.width);
        make.height.mas_equalTo(textSize.height);
    }];
    
    self.referenceView = contentLabelQue;
}
/**
 分隔符
 
 @param leftLabel 左侧视图
 */
-(void)addCenterImage:(UIView *)leftLabel{
    //添加分隔符视图
    UIImageView *centerImageView = [[UIImageView alloc]initWithImage:[self imageWithColor:[UIColor clearColor]]];
    [_scrollView addSubview:centerImageView];
    [centerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(leftLabel.mas_right).offset(CCGetRealFromPt(10));
        make.centerY.mas_equalTo(leftLabel.mas_centerY);
        make.width.mas_equalTo(CCGetRealFromPt(8));
        make.height.mas_equalTo(CCGetRealFromPt(8));
    }];
    self.lastView = centerImageView;
}
/**
 单选,多选，简答
 
 @param subjectsArray 问题数组
 @param leftLabel 左侧label
 @param i 位置
 */
-(void)addCenterLabel:(NSMutableArray *)subjectsArray
                label:(UIView *)leftLabel
                index:(int)i
{
    float textMaxWidth = CCGetRealFromPt(610);
    //得到每个问题的字典
    NSDictionary *opthionsDic = subjectsArray[i];
    //判断问题的类型
    NSString *centerStr = nil;
    if([opthionsDic[@"type"] intValue] == 0) {
        centerStr = @"单选";
        _selectQuestionCount ++;
    } else if([opthionsDic[@"type"] intValue] == 1) {
        centerStr = @"多选";
        _selectQuestionCount ++;
    } else if([opthionsDic[@"type"] intValue] == 2) {
        centerStr = @"问答";
    } else{
        centerStr = @"UNKNOW";
    }
    
    //初始化问题类型label
    UILabel *centerLabel = [[UILabel alloc] init];
    centerLabel.text = centerStr;
    centerLabel.textColor = CCRGBColor(252,81,43);
    centerLabel.textAlignment = NSTextAlignmentLeft;
    centerLabel.font = [UIFont boldSystemFontOfSize:FontSize_26];
    
    //添加问题类型,设置约束
    [_scrollView addSubview:centerLabel];
    CGSize centerSizeNum = [self getSizeByStr:centerStr minFontHeight:CCGetRealFromPt(26) maxFontHeight:CCGetRealFromPt(26) UIFont:[UIFont boldSystemFontOfSize:FontSize_26] textMaxWidth:textMaxWidth lineSpacing:CCGetRealFromPt(0)];
    //设置centerLabel的约束
    [centerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(leftLabel.mas_right).offset(CCGetRealFromPt(15));
        make.top.mas_equalTo(leftLabel.mas_top);
        make.width.mas_equalTo(centerSizeNum.width);
        make.height.mas_equalTo(centerSizeNum.height);
    }];
    self.lastView = centerLabel;
}
/**
 添加问题序号
 
 @param i 位置
 @param textMaxWidth 最大宽度
 @param subjectsArray 问题数组
 */
-(void)addleftLabel:(int)i
       textMaxWidth:(float)textMaxWidth
      subjectsArray:(NSMutableArray *)subjectsArray
{
    NSString *leftStr = [NSString stringWithFormat:@"%d.",i+1];
    
    //计算leftStr的大小
    CGSize leftSizeNum = [self getSizeByStr:leftStr minFontHeight:CCGetRealFromPt(26) maxFontHeight:CCGetRealFromPt(26) UIFont:[UIFont boldSystemFontOfSize:FontSize_26] textMaxWidth:textMaxWidth lineSpacing:CCGetRealFromPt(0)];
    
    //得到每个问题的字典
    NSDictionary *opthionsDic = subjectsArray[i];
    
    //初始化左侧问题序号
    UILabel *leftLabel = [[UILabel alloc] init];
    leftLabel.text = leftStr;
    leftLabel.textColor = CCRGBColor(102,102,102);
    leftLabel.textAlignment = NSTextAlignmentLeft;
    leftLabel.font = [UIFont boldSystemFontOfSize:FontSize_26];
    
    //设置左侧问题序号
    [_scrollView addSubview:leftLabel];
    [leftLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.scrollView.mas_left).offset(CCGetRealFromPt(30));
        if(i == 0) {//设置第一行时,leftLabel的高位置
//            make.top.mas_equalTo(self.referenceViewPreview.mas_bottom).offset(10);
            make.top.mas_equalTo(10);

        } else {
            if ([opthionsDic[@"type"] intValue] == 2 && self.isStastic) {//统计问答时
                if (self.lastType == 1 || self.lastType == 0) {
//                    make.top.mas_equalTo(self.referenceViewPreview.mas_bottom).offset(CCGetRealFromPt(58+2));
                    make.top.mas_equalTo(58+2);

                } else {//统计选择题
//                    make.top.mas_equalTo(self.referenceViewPreview.mas_bottom).offset(CCGetRealFromPt(1));
                    make.top.mas_equalTo(1);

                }
            } else {//不是第一行
//                make.top.mas_equalTo(self.referenceViewPreview.mas_bottom).offset(CCGetRealFromPt(58+2));
                make.top.mas_equalTo(58+2);

            }
        }
        self.lastType = [opthionsDic[@"type"] intValue];
        make.width.mas_equalTo(leftSizeNum.width);
        make.height.mas_equalTo(leftSizeNum.height);
    }];
    self.lastView = leftLabel;
}
#pragma mark - 设置问题视图 -------------end--------
//添加问卷标题
-(void)addTitle{
    //计算问卷标题高度
    float textMaxWidth = CCGetRealFromPt(610);
    //    NSMutableAttributedString *textAttri = [[NSMutableAttributedString alloc] initWithString:@"请选择正确答案"];
    //    [textAttri addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#ff454b" alpha:1.0f] range:NSMakeRange(0, textAttri.length)];
    //    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    //    style.lineSpacing = CCGetRealFromPt(20);
    //    style.alignment = NSTextAlignmentCenter;
    //    style.lineBreakMode = NSLineBreakByWordWrapping;
    //    NSDictionary *dict = @{NSFontAttributeName:[UIFont systemFontOfSize:FontSize_36],NSParagraphStyleAttributeName:style};
    //    [textAttri addAttributes:dict range:NSMakeRange(0, textAttri.length)];
    //
    //    CGSize textSize = [textAttri boundingRectWithSize:CGSizeMake(textMaxWidth, CGFLOAT_MAX)
    //                                              options:NSStringDrawingUsesLineFragmentOrigin
    //                                              context:nil].size;
    //    textSize.width = ceilf(textSize.width);
    //    textSize.height = ceilf(textSize.height);
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"请选择正确答案" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 18],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]}];
    
    //问卷的标题
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.textAlignment = NSTextAlignmentCenter;
    contentLabel.attributedText = string;
    //设置问卷标题约束
    [self.view addSubview:contentLabel];
    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(textMaxWidth);
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(CCGetRealFromPt(60));
        make.height.mas_equalTo(30);
    }];
    self.referenceViewPreview = contentLabel;
    
    /*
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"请选择正确答案" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 18],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]}];
    CGSize textSize = [string boundingRectWithSize:CGSizeMake(textMaxWidth, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                           context:nil].size;
    textSize.width = ceilf(textSize.width);
    textSize.height = ceilf(textSize.height);
    
    
    //问卷的标题
    UILabel *contentLabel = [[UILabel alloc] init];
    //    contentLabel.numberOfLines = 0;
    //    contentLabel.backgroundColor = CCClearColor;
    contentLabel.textAlignment = NSTextAlignmentCenter;
    //    contentLabel.userInteractionEnabled = NO;
    contentLabel.attributedText = string;
    //    contentLabel.textColor = [UIColor colorWithHexString:@"#ff454b" alpha:1.f];
    //设置问卷标题约束
    [_scrollView addSubview:contentLabel];
    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(textMaxWidth);
        make.centerX.mas_equalTo(self.scrollView);
        make.top.mas_equalTo(self.scrollView);
        make.height.mas_equalTo(textSize.height);
    }];
    self.referenceViewPreview = contentLabel;
     */
}
//设置基础视图
-(void)addOtherViews{
    //添加顶部视图
    [self.view addSubview:self.topBgView];
    [_topBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view);
        make.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view);
        make.height.mas_equalTo(CCGetRealFromPt(60));
    }];
    
    //添加关闭视图按钮
    [self.topBgView addSubview:self.closeBtn];
    [_closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.topBgView).offset(-CCGetRealFromPt(20));
        make.centerY.mas_equalTo(self.topBgView);
        make.size.mas_equalTo(CGSizeMake(CCGetRealFromPt(56),CCGetRealFromPt(56)));
    }];
    
    //    //添加标题文本
    //    [self.topBgView addSubview:self.titleLabel];
    //    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(self.topBgView);
    //    }];
    
    //添加scrollView,用于盛放问卷内容
    [self.view addSubview:self.scrollView];
    
//    UITapGestureRecognizer *singleTap2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dealSingleTap:)];
//    [_scrollView addGestureRecognizer:singleTap2];
//    _scrollView.alwaysBounceVertical = YES;
//    _scrollView.userInteractionEnabled = YES;
    
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.mas_equalTo(self.view);
//        make.right.mas_equalTo(self.view);
//        make.top.mas_equalTo(self.topBgView.mas_bottom).offset(30);
//        make.bottom.mas_equalTo(-80);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.topBgView.mas_bottom).offset(30);
        make.bottom.equalTo(@(-80));
    }];
    
    /*
    //添加scrollView,用于盛放问卷内容
    [self addSubview:self.scrollView];
    UITapGestureRecognizer *singleTap2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dealSingleTap:)];
    [_scrollView addGestureRecognizer:singleTap2];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.userInteractionEnabled = YES;
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view);
        make.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(CCGetRealFromPt(60));
        make.bottom.mas_equalTo(self.view);
    }];
     */
}
//设置背景视图
-(void)addBgView{
    self.backgroundColor = CCRGBAColor(0, 0, 0, 0.5);
    
    //添加手势，结束编辑
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dealSingleTap:)];
    [self addGestureRecognizer:singleTap];
    _view = [[UIView alloc]init];
    _view.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:54/255.0 green:54/255.0 blue:54/255.0 alpha:1.0]];
    _view.layer.cornerRadius = CCGetRealFromPt(10);
    
    //添加手势,结束编辑
    UITapGestureRecognizer *singleTap1 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dealSingleTap:)];
    [_view addGestureRecognizer:singleTap1];
    [self addSubview:_view];
    if(!self.isScreenLandScape) {//竖屏约束
        [_view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self).offset(CCGetRealFromPt(66));
            make.right.mas_equalTo(self).offset(-CCGetRealFromPt(66));
            //            make.top.mas_equalTo(self).offset(CCGetRealFromPt(288));
            //            make.bottom.mas_equalTo(self).offset(-CCGetRealFromPt(334));
            make.centerY.mas_equalTo(self);
            make.height.mas_equalTo(420);
        }];
    } else {//横屏约束
        [_view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.mas_equalTo(self);
            make.left.mas_equalTo(self).offset(CCGetRealFromPt(236));
            make.right.mas_equalTo(self).offset(-CCGetRealFromPt(236));
            make.top.mas_equalTo(self).offset(CCGetRealFromPt(26));
            make.bottom.mas_equalTo(self).offset(-CCGetRealFromPt(26));
        }];
    }
}

#pragma mark - 自定义方法

- (BOOL) textView: (UITextView *) textView  shouldChangeTextInRange: (NSRange) range replacementText: (NSString *)text {
    if( [ @"\n" isEqualToString: text]){
        [_scrollView endEditing:YES];
        return NO;
    }
    return YES;
}
//结束编辑
- (void)dealSingleTap:(UITapGestureRecognizer *)tap {
    [_scrollView endEditing:YES];
}

//提交成功或失败,修改提示信息文本
-(void)commitSuccess:(BOOL)success {
    _msgLabel.hidden = YES;
    [self commitResult:success];
    //    if(success) {
    ////        _msgLabel.text = COMMITSUCCESS;
    //        _msgLabel.hidden = YES;
    ////        _msgLabel.textColor = CCRGBColor(23,188,47);
    //    } else {
    ////        _msgLabel.text = COMMITFAILURE;
    //        _msgLabel.hidden = YES;
    ////        _msgLabel.textColor = CCRGBColor(224,58,58);
    //    }
}
-(void)commitResult:(BOOL)success {
    
    UIView *bgview = [[UIView alloc] init];
    bgview.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:54/255.0 green:54/255.0 blue:54/255.0 alpha:1.0]];
    [self addSubview:bgview];
    [bgview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.centerY.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(240, 165));
    }];
    
    
    UIImageView * imageView = [[UIImageView alloc] init];
    imageView.image = [UIImage imageNamed:@"pop_top_icon_success"];
    NSString *result = @"恭喜您，提交成功！";
    if (!success) {
        imageView.image = [UIImage imageNamed:@"pop_top_icon_fail"];
        result = @"抱歉，签到失败！";
    }
    [bgview addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bgview);
        make.centerY.equalTo(bgview.mas_top).offset(20);
        make.size.mas_equalTo(CGSizeMake(140, 140));
    }];
    UILabel * punchLabel = [[UILabel alloc] init];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:result attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 18],NSForegroundColorAttributeName: [UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0]]}];
    
    punchLabel.attributedText = string;
    punchLabel.numberOfLines = 0;
    punchLabel.textAlignment = NSTextAlignmentCenter;
    [bgview addSubview:punchLabel];
    [punchLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bgview).offset(20);
        make.right.equalTo(bgview).offset(-20);
        make.top.equalTo(bgview).offset(106.5);
        make.height.mas_equalTo(20);
    }];
    WS(weakSelf)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [bgview removeFromSuperview];
        weakSelf.view.hidden = NO;
        self.scrollView.hidden = NO;
        
    });
    
}

/**
 内容发生改变编辑 自定义文本框placeholder
 有时候我们要控件自适应输入的文本的内容的高度，只要在textViewDidChange的代理方法中加入调整控件大小的代理即可
 @param textView textView
 */
- (void)textViewDidChange:(UITextView *)textView
{
    
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.selectedTextView = textView;
    //    self.selectedTextView.backgroundColor = CCRGBColor(255, 0, 0);
    return YES;
}
#pragma mark - 添加通知
-(void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}
//移除通知
-(void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark keyboard notification
- (void)keyboardWillShow:(NSNotification *)notif {
    _msgLabel.hidden = YES;
    
    NSDictionary *userInfo = [notif userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    _keyboardRect = [aValue CGRectValue];
    CGFloat y = _keyboardRect.size.height;
    //    NSLog(@"y = %f",y);
    //    CGFloat x = _keyboardRect.size.width;
    //NSLog(@"键盘高度是  %d",(int)y);
    //NSLog(@"键盘宽度是  %d",(int)x);
    if ([self.selectedTextView isFirstResponder]) {
        WS(ws)
        UIView *view = self.selectedTextView.superview;
        //        CGPoint point = [self convertPoint:self.scrollView.frame.origin fromView:self.bgView];
        CGFloat scrollKeyboard = self.frame.size.height - (self.view.frame.origin.y + self.view.frame.size.height + y);
        //        NSLog(@"scrollKeyboard = %f",scrollKeyboard);
        //        self.selectedTextView.backgroundColor = CCRGBColor(255, 0, 0);
        CGFloat contentOffSize = view.frame.origin.y + view.frame.size.height - self.scrollView.frame.size.height - scrollKeyboard;
        
        [UIView animateWithDuration:0.25f animations:^{
            [ws.scrollView setContentOffset:CGPointMake(0, contentOffSize)];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notif {
    [self hideKeyboard];
}

-(void)hideKeyboard {
    //    WS(ws)
    //    [_contentView mas_updateConstraints:^(MASConstraintMaker *make) {
    //        make.right.and.left.and.bottom.mas_equalTo(ws);
    //        make.height.mas_equalTo(CCGetRealFromPt(110));
    //    }];
    //
    //    [_publicTableView mas_updateConstraints:^(MASConstraintMaker *make) {
    //        make.top.and.right.and.left.mas_equalTo(ws);
    //        make.bottom.mas_equalTo(ws.contentView.mas_top);
    //    }];
    //
    //    [UIView animateWithDuration:0.25f animations:^{
    //        [ws layoutIfNeeded];
    //    } completion:^(BOOL finished) {
    //
    //    }];
}


/**
 计算一个字符串的size
 
 @param str 传入一个字符串
 @param minFontHeight 最小FontHeight
 @param maxFontHeight 最大FontHeight
 @param font 字体大小
 @param textMaxWidth 最大宽度
 @param lineSpacing 行高
 @return 字符串大小
 */
-(CGSize)getSizeByStr:(NSString *)str minFontHeight:(NSInteger)minFontHeight maxFontHeight:(NSInteger)maxFontHeight UIFont:(UIFont *)font textMaxWidth:(CGFloat)textMaxWidth lineSpacing:(CGFloat)lineSpacing {
    NSMutableAttributedString *textAttri = [[NSMutableAttributedString alloc] initWithString:str];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    //    style.minimumLineHeight = CCGetRealFromPt(minFontHeight);
    //    style.maximumLineHeight = CCGetRealFromPt(maxFontHeight);
    style.lineSpacing = lineSpacing;
    style.alignment = NSTextAlignmentLeft;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *dict = @{NSFontAttributeName:font,NSParagraphStyleAttributeName:style};
    [textAttri addAttributes:dict range:NSMakeRange(0, textAttri.length)];
    CGSize textSize = [textAttri boundingRectWithSize:CGSizeMake(textMaxWidth, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                              context:nil].size;
    return CGSizeMake(ceilf(textSize.width),ceilf(textSize.height));
}
//关闭按钮
-(UIButton *)closeBtn {
    if(!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeBtn.backgroundColor = CCClearColor;
        _closeBtn.contentMode = UIViewContentModeScaleAspectFit;
        [_closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [_closeBtn setBackgroundImage:[UIImage imageNamed:@"popup_close"] forState:UIControlStateNormal];
    }
    return _closeBtn;
}
#pragma mark - 懒加载
-(UIScrollView *)scrollView {
    if(!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = CCClearColor;
//        _scrollView.bounces = NO;
        //        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.scrollEnabled = YES;
        _scrollView.delegate = self;

    }
    return _scrollView;
}
//提交按钮
-(UIButton *)submitBtn {
    if(_submitBtn == nil) {
        _submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _submitBtn.backgroundColor = CCRGBColor(255,102,51);
        if (self.isStastic) {
            _submitBtn.hidden = YES;
        } else {
            [_submitBtn setTitle:@"提交" forState:UIControlStateNormal];
        }
        _submitBtn.tag = 1;
        [_submitBtn.titleLabel setFont:[UIFont systemFontOfSize:FontSize_32]];
        [_submitBtn setTitleColor:CCRGBAColor(255, 255, 255, 1) forState:UIControlStateNormal];
        [_submitBtn.layer setMasksToBounds:YES];
        [_submitBtn.layer setCornerRadius:22.0f];
        [_submitBtn addTarget:self action:@selector(submitAction) forControlEvents:UIControlEventTouchUpInside];
        [_submitBtn setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]] forState:UIControlStateNormal];
    }
    return _submitBtn;
}
//提交按钮点击事件
-(void)submitAction {
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for(UIButton *button in self.buttonArray) {
        if(button.selected == YES) {
            NSArray *separatedArray = [button.userid componentsSeparatedByString:@"-"];
            NSString *subjectId = separatedArray[4];
            BOOL flag = NO;
            NSMutableDictionary *dicGet = nil;
            for(NSMutableDictionary *dic in array) {
                if([dic[@"subjectId"] isEqualToString:subjectId]) {
                    dicGet = dic;
                    flag = YES;
                    break;
                }
            }
            if(flag == NO) {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                dic[@"subjectId"] = subjectId;
                dicGet = dic;
                [array addObject:dic];
            }
            //题号-类型（0：单选，1:多选）-选项个数-选项索引值-题目ID-选项ID
            if([separatedArray[1] intValue] == 0) {
                NSString *str = dicGet[@"selectedOptionId"];
                if(StrNotEmpty(str)) {
                } else {
                    dicGet[@"selectedOptionId"] = separatedArray[5];
                }
            } else {
                NSString *str = dicGet[@"selectedOptionIds"];
                if(StrNotEmpty(str)) {
                    dicGet[@"selectedOptionIds"] = [NSString stringWithFormat:@"%@,%@",str,separatedArray[5]];
                } else {
                    dicGet[@"selectedOptionIds"] = separatedArray[5];
                }
            }
            
        }
    }
    //判断是否有问题没有回答
    if(array.count <= 0) {
        _msgLabel.text = STATISTICAL_COMMIT_FAILED;
        _msgLabel.hidden = NO;
        _msgLabel.textColor = CCRGBColor(224,58,58);
        return;
    }
    for(UIButton *button in self.buttonArray) {
        UILabel * ALabel = (UILabel *)[self.scrollView viewWithTag:10000 + button.tag - 1000];
        ALabel.textColor = CCRGBColor(102,102,102);
        
        button.userInteractionEnabled = NO;
        if ([button.correct integerValue] == 1) {
            [button setBackgroundImage:[self imageWithColor:[UIColor colorWithLight:[UIColor colorWithRed:207/255.0 green:255/255.0 blue:223/255.0 alpha:1.0] Dark:[UIColor colorWithRed:45/255.0 green:171/255.0 blue:87/255.0 alpha:1.0]]] forState:UIControlStateNormal];
            NSString *str = button.titleLabel.attributedText.string;
            NSMutableAttributedString *textAttriOption = [[NSMutableAttributedString alloc] initWithString:str];
            [textAttriOption addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0]] range:NSMakeRange(0, textAttriOption.length)];
            NSMutableParagraphStyle *styleOption = [[NSMutableParagraphStyle alloc] init];
            //                styleOption.minimumLineHeight = CCGetRealFromPt(26);
            styleOption.lineSpacing = CCGetRealFromPt(5);
            styleOption.alignment = NSTextAlignmentLeft;
            styleOption.lineBreakMode = NSLineBreakByWordWrapping;
            NSDictionary *dictOption = @{NSFontAttributeName:[UIFont systemFontOfSize:FontSize_26],NSParagraphStyleAttributeName:styleOption};
            [textAttriOption addAttributes:dictOption range:NSMakeRange(0, textAttriOption.length)];
            [button setAttributedTitle:textAttriOption forState:UIControlStateNormal];
        }
        if(button.selected == YES) {
            NSString *str = button.titleLabel.attributedText.string;
            NSMutableAttributedString *textAttriOption = [[NSMutableAttributedString alloc] initWithString:str];
            [textAttriOption addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0]] range:NSMakeRange(0, textAttriOption.length)];
            NSMutableParagraphStyle *styleOption = [[NSMutableParagraphStyle alloc] init];
            //                styleOption.minimumLineHeight = CCGetRealFromPt(26);
            styleOption.lineSpacing = CCGetRealFromPt(5);
            styleOption.alignment = NSTextAlignmentLeft;
            styleOption.lineBreakMode = NSLineBreakByWordWrapping;
            NSDictionary *dictOption = @{NSFontAttributeName:[UIFont systemFontOfSize:FontSize_26],NSParagraphStyleAttributeName:styleOption};
            [textAttriOption addAttributes:dictOption range:NSMakeRange(0, textAttriOption.length)];
            [button setAttributedTitle:textAttriOption forState:UIControlStateSelected];
            [button setBackgroundImage:[self imageWithColor:[UIColor colorWithLight:[UIColor colorWithRed:255/255.0 green:219/255.0 blue:220/255.0 alpha:1.0] Dark:[UIColor colorWithRed:196/255.0 green:48/255.0 blue:52/255.0 alpha:1.0]]] forState:UIControlStateSelected];
        }
    }
    //得到所有答案的字典
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    dic[@"subjectsAnswer"] = array;
    if(self.commitblock) {
        self.commitblock(dic);
        if (self.submitedAction == 1) {
            [_submitBtn setTitle:@"我知道了" forState:UIControlStateNormal];
            //            _submitBtn.userInteractionEnabled = NO;
            [_submitBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
            for(UILabel *correctLabel in self.correctLabelArray) {
                correctLabel.hidden = NO;
            }
        }
        
    }
    self.scrollView.hidden = YES;
    self.view.hidden = YES;
}

//选择按钮点击
-(void)selectBtnClicked:(UIButton *)sender {
    bool selected = sender.selected;
    
    if(selected == YES) {
        sender.selected = NO;
        UILabel * label = (UILabel *)[self.scrollView viewWithTag:10000 + sender.tag - 1000];
        label.textColor = CCRGBColor(102,102,102);
        return;
    }
    sender.selected = YES;
    _msgLabel.hidden = YES;
    NSString *str = sender.userid;
    [sender setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
    NSArray *strArr = [str componentsSeparatedByString:@"-"];
    
    UILabel * ALabel = (UILabel *)[self.scrollView viewWithTag:10000 + sender.tag - 1000];
    ALabel.textColor = [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0];
    
    if([strArr[1] intValue] == 0) {
        for(int i = 0;i < [strArr[2] intValue]; i++) {
            NSString *userId = [NSString stringWithFormat:@"%@-%@-%@-%d",strArr[0],strArr[1],strArr[2],i];
            if(![userId isEqualToString:[self separatedString:sender.userid]]) {
                for(UIButton *button in self.buttonArray) {
                    if([userId isEqualToString:[self separatedString:button.userid]]) {
                        button.selected = NO;
                        UILabel * label = (UILabel *)[self.scrollView viewWithTag:10000 + button.tag - 1000];
                        label.textColor = CCRGBColor(102,102,102);
                    }
                }
            }
        }
    }
}
//分离字符串
-(NSString *)separatedString:(NSString *)userInfoId {
    NSArray *strArr = [userInfoId componentsSeparatedByString:@"-"];
    return [NSString stringWithFormat:@"%@-%@-%@-%@",strArr[0],strArr[1],strArr[2],strArr[3]];
}

- (UIImage*)createImageWithColor:(UIColor*) color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}
//关闭按钮点击回调
-(void)closeBtnClicked {
    [self removeObserver];
    if(self.closeblock) {
        self.closeblock();
    }
}
//顶部title
-(UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = STATISTICAL_TITLE(self.isStastic);
        _titleLabel.textColor = [UIColor colorWithHexString:@"#38404b" alpha:1.f];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:FontSize_32];
    }
    return _titleLabel;
}
//- (UIImage *)imageWithColor:(UIColor *)color {
//
//    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetFillColorWithColor(context, [color CGColor]);
//    CGContextFillRect(context, rect);
//    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    return theImage;
//}
//顶部背景视图
-(UIImageView *)topBgView {
    if(!_topBgView) {
        _topBgView = [[UIImageView alloc] initWithImage:[self imageWithColor:[UIColor clearColor]]];
        _topBgView.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:54/255.0 green:54/255.0 blue:54/255.0 alpha:1.0]];;
        _topBgView.userInteractionEnabled = YES;
        //        _topBgView.layer.cornerRadius = CCGetRealFromPt(12);
        //        _topBgView.layer.masksToBounds = YES;
        //        // 阴影颜色
        //        _topBgView.layer.shadowColor = [UIColor grayColor].CGColor;
        //        // 阴影偏移，默认(0, -3)
        //        _topBgView.layer.shadowOffset = CGSizeMake(0, 3);
        //        // 阴影透明度，默认0.7
        //        _topBgView.layer.shadowOpacity = 0.2f;
        //        // 阴影半径，默认3
        _topBgView.layer.shadowRadius = 3;
        _topBgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _topBgView;
}
-(NSMutableArray *)buttonArray {
    if(!_buttonArray) {
        _buttonArray = [[NSMutableArray alloc]init];
    }
    return _buttonArray;
}

-(NSMutableArray *)textViewArray {
    if(!_textViewArray) {
        _textViewArray = [[NSMutableArray alloc]init];
    }
    return _textViewArray;
}

-(NSMutableArray *)buttonIdArray {
    if(!_buttonIdArray) {
        _buttonIdArray = [[NSMutableArray alloc]init];
    }
    return _buttonIdArray;
}
-(NSMutableArray *)correctLabelArray {
    if(!_correctLabelArray) {
        _correctLabelArray = [[NSMutableArray alloc]init];
    }
    return _correctLabelArray;
}
@end
