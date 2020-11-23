//
//  CCPlayerController.m
//  CCLiveCloud
//
//  Created by MacBook Pro on 2018/10/22.
//  Copyright © 2018 MacBook Pro. All rights reserved.
//

#import "CCPlayerController.h"
#import "CCSDK/RequestData.h"//SDK
#import "CCSDK/SaveLogUtil.h"//日志
#import "LotteryView.h"//抽奖
#import "CCPlayerView.h"//视频
#import "CCPlayBack.h"//回放视频
#import "CCInteractionView.h"//互动视图
#import "QuestionNaire.h"//第三方调查问卷
#import "QuestionnaireSurvey.h"//问卷和问卷统计
#import "QuestionnaireSurveyPopUp.h"//问卷弹窗
#import "RollcallView.h"//签到
#import "VoteView.h"//答题卡
#import "VoteViewResult.h"//答题结果
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "AnnouncementView.h"//公告
#import "CCAlertView.h"//提示框
#import "CCProxy.h"
#import "CCClassTestView.h"//随堂测
#import "CCCupView.h"//奖杯
#import "Reachability.h"
#import "CCPublicInteractionView.h"
#import "CCGiftRewardPopView.h"
#import <HDMarqueeTool/HDMarqueeTool.h>
//#ifdef LockView
#import "CCLockView.h"//锁屏界面
//#endif
/*
*******************************************************
*      去除锁屏界面功能步骤如下：                          *
*  1。command+F搜索   #ifdef LockView                  *
*                                                     *
*  2.删除 #ifdef LockView 至 #endif之间的代码            *
*******************************************************
*/

#import "CCPlayBackController.h"
#import "CCPunchView.h"

@interface CCPlayerController ()<RequestDataDelegate,UIScrollViewDelegate,UITextFieldDelegate,CCPlayerViewDelegate,CCPlayBackDelegate>
#pragma mark - 房间相关参数
@property (nonatomic,copy)  NSString                 * viewerId;//观看者的id
@property (nonatomic,strong)NSTimer                  * userCountTimer;//计算观看人数
@property (nonatomic,strong)NSString                 * roomName;//房间名
@property (nonatomic,strong)RequestData              * requestData;//sdk
#pragma mark - UI初始化
@property (nonatomic,strong)CCPlayerView             * playerView;//视频视图
@property (nonatomic,strong)CCPlayBack               * playerView1;//回放视频视图

@property (nonatomic,strong)CCInteractionView        * contentView;//专题课
//@property(nonatomic,strong)CCPublicInteractionView * contentView;//直播课
#pragma mark - 抽奖
@property (nonatomic,strong)LotteryView              * lotteryView;//抽奖
#pragma mark - 问卷
@property (nonatomic,assign)NSInteger                submitedAction;//提交事件
@property (nonatomic,strong)QuestionNaire            * questionNaire;//第三方调查问卷
@property (nonatomic,strong)QuestionnaireSurvey      * questionnaireSurvey;//问卷视图
@property (nonatomic,strong)QuestionnaireSurveyPopUp * questionnaireSurveyPopUp;//问卷弹窗
#pragma mark - 签到
@property (nonatomic,weak)  RollcallView             * rollcallView;//签到
@property (nonatomic,assign)NSInteger                duration;//签到时间
#pragma mark - 答题卡
@property(nonatomic,weak)  VoteView                  * voteView;//答题卡
@property(nonatomic,weak)  VoteViewResult            * voteViewResult;//答题结果
@property(nonatomic,assign)NSInteger                 mySelectIndex;//答题单选答案
@property(nonatomic,strong)NSMutableArray            * mySelectIndexArray;//答题多选答案
#pragma mark - 公告
@property(nonatomic,copy)  NSString                  * gongGaoStr;//公告内容
@property(nonatomic,strong)AnnouncementView          * announcementView;//公告视图

#pragma mark - 随堂测
@property(nonatomic,weak)CCClassTestView           * testView;//随堂测
#pragma mark - 打卡视图
@property(nonatomic,strong)CCPunchView                 * punchView;//打卡

#pragma mark - 提示框
@property (nonatomic,strong)CCAlertView              * alertView;//消息弹窗

@property (nonatomic,assign)BOOL                     isScreenLandScape;//是否横屏
@property (nonatomic,assign)BOOL                     screenLandScape;//横屏
@property (nonatomic,assign)BOOL                     isHomeIndicatorHidden;//隐藏home条
@property (nonatomic,assign)NSInteger                firRoadNum;//房间线路
@property (nonatomic,strong)NSMutableArray           * secRoadKeyArray;//清晰度数组
@property (nonatomic,assign)BOOL                     firstUnStart;//第一次进入未开始直播
@property (nonatomic,assign)BOOL                     pauseInBackGround;//后台播放是否暂停

#pragma mark - 文档显示模式
@property (nonatomic,assign)BOOL                     isSmallDocView;//是否是文档小窗模式
@property (nonatomic,strong)UIView                   *onceDocView;//临时DocView(双击ppt进入横屏调用)
@property (nonatomic,strong)UIView                   *oncePlayerView;//临时playerView(双击ppt进入横屏调用)
@property (nonatomic,strong)UILabel                  *label;
@property (nonatomic,strong)MPVolumeView               *volumeView;

@property(nonatomic,strong)CCGiftRewardPopView * giftView;//礼物view
@property(nonatomic,strong)CCGiftRewardPopView * rewardView;//打赏view
@property (nonatomic,assign)BOOL                     changeGift;//换行显示打赏和礼物
//**************************** marquee ****************************
@property(nonatomic,strong)HDMarqueeView * marqueeView;
@property(nonatomic,strong)HDMarqueeView * marqueeView1;
@property(nonatomic,strong)NSDictionary * jsonDict;

//#ifdef LockView
#pragma make - 锁屏界面
@property (nonatomic,strong)CCLockView               * lockView;//锁屏视图
//#endif LockView


@end
@implementation CCPlayerController
//初始化
- (instancetype)initWithRoomName:(NSString *)roomName{
    self = [super init];
    if(self) {
        self.roomName = roomName;
    }
    return self;
}
//启动
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    /*  设置后台是否暂停 ps:后台支持播放时将会开启锁屏播放器 */
    _pauseInBackGround = NO;
    [self setupUI];//创建UI
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reach currentReachabilityStatus];
    [self.view bringSubviewToFront:self.playerView];
    if (status == ReachableViaWiFi || status == ReachableViaWWAN) {
        [self integrationSDK];//集成SDK
        [self addObserver];//添加通知
    } else {
        self.playerView.unWifiView.hidden = NO;
    }
//    [self giftView];
//    [self rewardView];


//    UIButton *btn = [[UIButton alloc] init];
//    [btn setBackgroundColor:[UIColor redColor]];
//    [self.view addSubview:btn];
//    btn.frame = CGRectMake(100, 100, 100, 100);
//    [btn addTarget:self action:@selector(changedoc) forControlEvents:UIControlEventTouchUpInside];
}
- (void)changedoc {
    [_requestData getPublishingQuestionnaire];

}
- (void)receivedMarqueeInfo:(NSDictionary *)dic {
    if (dic == nil) {
        return;
    }
    self.jsonDict = dic;
    {

        CGFloat width = 0.0;
        CGFloat height = 0.0;
        self.marqueeView = [[HDMarqueeView alloc]init];
        self.marqueeView1 = [[HDMarqueeView alloc]init];
        HDMarqueeViewStyle style = [[self.jsonDict objectForKey:@"type"] isEqualToString:@"text"] ? HDMarqueeViewStyleTitle : HDMarqueeViewStyleImage;
        self.marqueeView.style = style;
        self.marqueeView1.style = style;
        self.marqueeView.repeatCount = [[self.jsonDict objectForKey:@"loop"] integerValue];
        self.marqueeView1.repeatCount = [[self.jsonDict objectForKey:@"loop"] integerValue];
        if (style == HDMarqueeViewStyleTitle) {
            NSDictionary * textDict = [self.jsonDict objectForKey:@"text"];
            NSString * text = [textDict objectForKey:@"content"];
            UIColor * textColor = [UIColor colorWithHexString:[textDict objectForKey:@"color"] alpha:1.0f];
            UIFont * textFont = [UIFont systemFontOfSize:[[textDict objectForKey:@"font_size"] floatValue]];
            
            self.marqueeView.text = text;
            self.marqueeView1.text = text;
            self.marqueeView.textAttributed = @{NSFontAttributeName:textFont,NSForegroundColorAttributeName:textColor};
            self.marqueeView1.textAttributed = @{NSFontAttributeName:textFont,NSForegroundColorAttributeName:textColor};
            CGSize textSize = [self.marqueeView.text calculateRectWithSize:CGSizeMake(SCREEN_WIDTH, SCREENH_HEIGHT) Font:textFont WithLineSpace:0];
            width = textSize.width;
            height = textSize.height;
            
        }else{
            NSDictionary * imageDict = [self.jsonDict objectForKey:@"image"];
            NSURL * imageURL = [NSURL URLWithString:[imageDict objectForKey:@"image_url"]];
            self.marqueeView.imageURL = imageURL;
            self.marqueeView1.imageURL = imageURL;
            width = [[imageDict objectForKey:@"width"] floatValue];
            height = [[imageDict objectForKey:@"height"] floatValue];

        }
        self.marqueeView.frame = CGRectMake(0, 0, width, height);
        self.marqueeView1.frame = CGRectMake(0, 0, width, height);
        //处理action
        NSArray * setActionsArray = [self.jsonDict objectForKey:@"action"];
        
        NSMutableArray <HDMarqueeAction *> * actions = [NSMutableArray array];
        for (int i = 0; i < setActionsArray.count; i++) {
            NSDictionary * actionDict = [setActionsArray objectAtIndex:i];
            CGFloat duration = [[actionDict objectForKey:@"duration"] floatValue];
            NSDictionary * startDict = [actionDict objectForKey:@"start"];
            NSDictionary * endDict = [actionDict objectForKey:@"end"];

            HDMarqueeAction * marqueeAction = [[HDMarqueeAction alloc]init];
            marqueeAction.duration = duration;
            marqueeAction.startPostion.alpha = [[startDict objectForKey:@"alpha"] floatValue];
            marqueeAction.startPostion.pos = CGPointMake([[startDict objectForKey:@"xpos"] floatValue], [[startDict objectForKey:@"ypos"] floatValue]);
            marqueeAction.endPostion.alpha = [[endDict objectForKey:@"alpha"] floatValue];
            marqueeAction.endPostion.pos = CGPointMake([[endDict objectForKey:@"xpos"] floatValue], [[endDict objectForKey:@"ypos"] floatValue]);
            
            [actions addObject:marqueeAction];
        }
        
        self.marqueeView.actions = actions;
        self.marqueeView1.actions = actions;
        self.marqueeView.fatherView = self.playerView.smallVideoView;
        self.marqueeView1.fatherView = self.playerView;
        self.playerView.smallVideoView.layer.masksToBounds = YES;

        }
    
}

/**
 *    @brief    房间设置信息
 *    dic{
      "allow_chat" = true;//是否允许聊天
      "allow_question" = true;//是否允许问答
      "room_base_user_count" = 0;//房间基础在线人数
      "source_type" = 0;//对应receivedSwitchSource方法的source_type
}
 *ps:当房间类型没有聊天或者问答时,对应的字段默认为true
*/
-(void)roomSettingInfo:(NSDictionary *)dic {
    NSDictionary *dict = @{@"allowChat":dic[@"allow_chat"]};

    [[NSNotificationCenter defaultCenter] postNotificationName:@"allow_chat" object:nil userInfo:dict];


}

-(void)callOneAction
{
    [self sendChatMessageWithStr:SENDCALLONE];
}

-(void)callTwoAction
{
    [self sendChatMessageWithStr:SENDCALLTWO];
}
/**
 *    @brief    视频状态
 *    rseult    playing/paused/loading
 */
#warning 直播和回放注意切换playerView和playerView1
-(void)videoStateChangeWithString:(NSString *) result {
    if ([result isEqualToString:@"playing"]) {
            [self.playerView.smallVideoView bringSubviewToFront:self.playerView.smallVideoView.smallCloseBtn];
    }
}

#pragma -mark 礼物和打赏
-(void)sendGiftAction:(NSNotification *)noti {
    NSString * str = [NSString stringWithFormat:@"赠送给老师 老师心 %@http://static.csslcloud.net/img/em2/15.png]x%@",SENDGIFT,noti.object];
    [self sendChatMessageWithStr:str];
}

-(void)sendRewardAction:(NSNotification *)noti {
    [self sendChatMessageWithStr:[NSString stringWithFormat:@"打赏给老师%@https://github.wdapp.top/branches/demo-runde/runde-web/src/assets/images/gifts/gift3.png]￥%@",SENDGIFT,noti.object]];
//    [self sendChatMessageWithStr:[NSString stringWithFormat:@"打赏给老师 老师心 %@http://static.csslcloud.net/img/em2/15.png]￥%@",SENDGIFT,noti.object]];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObserver];//移除通知
}
/**
 创建UI
 */
- (void)setupUI {
    /*   设置文档显示类型    YES:表示文档小窗模式   NO:文档在下模式  */
    _isSmallDocView = YES;
    //视频视图
    [self.view addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(SCREEN_WIDTH *0.5625);
        make.top.equalTo(self.view).offset(SCREEN_STATUS);
    }];
    
    //添加互动视图
    [self.view addSubview:self.contentView];
}
/**
 集成sdk
 */
- (void)integrationSDK {
    UIView *docView = self.playerView.smallVideoView;
    PlayParameter *parameter = [[PlayParameter alloc] init];
    parameter.userId = GetFromUserDefaults(WATCH_USERID);//userId
    parameter.roomId = GetFromUserDefaults(WATCH_ROOMID);//roomId
    parameter.viewerName = GetFromUserDefaults(WATCH_USERNAME);//用户名
    parameter.token = GetFromUserDefaults(WATCH_PASSWORD);//密码
    parameter.playerParent = self.playerView;//视频视图
    parameter.playerFrame = CGRectMake(0,0,self.playerView.frame.size.width, self.playerView.frame.size.height);//视频位置,ps:起始位置为视频视图坐标
    parameter.docParent = docView;//文档小窗
    parameter.docFrame = CGRectMake(0,0,docView.frame.size.width, docView.frame.size.height);//文档位置,ps:起始位置为文档视图坐标
    parameter.security = YES;//是否开启https,建议开启
    parameter.PPTScalingMode = 4;//ppt展示模式,建议值为4
    parameter.defaultColor = [UIColor blackColor];//ppt默认底色，不写默认为白色
    parameter.scalingMode = 1;//屏幕适配方式
    parameter.pauseInBackGround = _pauseInBackGround;//后台是否暂停
    parameter.viewerCustomua = @"viewercustomua";//自定义参数,没有的话这么写就可以
    parameter.pptInteractionEnabled = !_isSmallDocView;//是否开启ppt滚动
    parameter.DocModeType = 0;//设置当前的文档模式
//    parameter.DocShowType = 1; 
//    parameter.groupid = _contentView.groupId;//用户的groupId
    _requestData = [[RequestData alloc] initWithParameter:parameter];
    _requestData.delegate = self;


}

- (void)docLoadCompleteWithIndex:(NSInteger)index {
    if (index == 0) {
//        [_requestData changeDocWebColor:@"000000"];
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [self.playerView.smallVideoView addSubview:self.marqueeView];
             [self.playerView addSubview:self.marqueeView1];
             [self.marqueeView startMarquee];
             [self.marqueeView1 startMarquee];
         });
    }
}
#pragma mark - 私有方法
/**
 发送聊天

 @param str 聊天内容
 */
- (void)sendChatMessageWithStr:(NSString *)str {
    [_requestData chatMessage:str];
}

/**
 旋转方向

 @return 是否允许转屏
 */
- (BOOL)shouldAutorotate {
    if (self.isScreenLandScape == YES) {
        return YES;
    }
    return NO;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
/**
 强制转屏

 @param orientation 旋转方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector  = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        // 从2开始是因为0 1 两个参数已经被selector和target占用
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}
#pragma mark - playViewDelegate 以及相关方法

/**
 点击切换视频/文档按钮

 @param tag 1为视频为主，2为文档为主
 */
-(void)changeBtnClicked:(NSInteger)tag{
    if (tag == 2) {
        [_requestData changeDocParent:self.playerView];
        [_requestData changePlayerParent:self.playerView.smallVideoView];
        [_requestData changeDocFrame:CGRectMake(0, 0,self.playerView.frame.size.width, self.playerView.frame.size.height)];
        [_requestData changePlayerFrame:CGRectMake(0, 0, self.playerView.smallVideoView.frame.size.width, self.playerView.smallVideoView.frame.size.height)];
        [self.playerView.smallVideoView bringSubviewToFront:self.playerView.smallVideoView.smallCloseBtn];
    }else{
        [_requestData changeDocParent:self.playerView.smallVideoView];
        [_requestData changePlayerParent:self.playerView];
        [_requestData changePlayerFrame:CGRectMake(0, 0,self.playerView.frame.size.width, self.playerView.frame.size.height)];
        [_requestData changeDocFrame:CGRectMake(0, 0, self.playerView.smallVideoView.frame.size.width, self.playerView.smallVideoView.frame.size.height)];
        [self.playerView.smallVideoView bringSubviewToFront:self.playerView.smallVideoView.smallCloseBtn];
    }
    [self.playerView.smallVideoView bringSubviewToFront:self.marqueeView];
    [self.playerView bringSubviewToFront:self.marqueeView1];
}

/**
 点击全屏按钮代理
 
 @param tag 1为视频为主，2为文档为主
 */
- (void)quanpingButtonClick:(NSInteger)tag {
    [self.view endEditing:YES];
    [APPDelegate.window endEditing:YES];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self.contentView.chatView resignFirstResponder];
    [self othersViewHidden:YES];
    if (tag == 1) {
        [_requestData changePlayerFrame:self.view.frame];
    } else {
        [_requestData changeDocFrame:self.view.frame];
    }
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     
     NSLog(@"%@ %@",self.marqueeView.fatherView,self.marqueeView1.fatherView);
     
     [self.marqueeView startMarquee];
     [self.marqueeView1 startMarquee];
 });
}
/**
 点击暂停/继续按钮

 @param isPause 是否暂停
 */
-(void)pauseButtonClicked:(BOOL)isPause {
    if (isPause == YES) {
        [self.requestData pausePlayer];
    } else {
        [self.requestData startPlayer];
    }
}
/**
非WiFi播放按钮点击代理
*/
- (void)unWifiplayBtnClick{
    [self integrationSDK];
    [self addObserver];
    [self.playerView.unWifiView removeFromSuperview];
}

/**
 点击退出按钮(返回竖屏或者结束直播)
 
 @param sender backBtn
 @param tag changeBtn的标记，1为视频为主，2为文档为主
 */
- (void)backButtonClick:(UIButton *)sender changeBtnTag:(NSInteger)tag{
    if (sender.tag == 2) {//横屏返回竖屏
        [self othersViewHidden:NO];
        if (tag == 1) {
            [_requestData changePlayerFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625)];
        } else {
            [_requestData changeDocFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625)];
        }
    }else if( sender.tag == 1){//结束直播
        [self creatAlertController_alert];
//        [self dismissViewControllerAnimated:YES completion:nil];

    }
}
//隐藏其他视图,当点击全屏和退出全屏时调用此方法
-(void)othersViewHidden:(BOOL)hidden{
    self.screenLandScape = hidden;//设置横竖屏
    self.contentView.chatView.ccPrivateChatView.hidden = hidden;//隐藏聊天视图
    self.isScreenLandScape = YES;//支持旋转
    [self interfaceOrientation:hidden? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait];
    self.isScreenLandScape = NO;//不支持旋转
    
    self.contentView.hidden = hidden;//隐藏互动视图
    if (hidden == NO) {
#warning - 公开课
//#ifdef 公开课
//        [self.contentView upDateHeaderViewConstraintIsClose:YES];
//#end
    }

    self.announcementView.hidden = hidden;//隐藏公告视图
}
//创建提示窗
-(void)creatAlertController_alert {
    //添加提示窗
    CCAlertView *alertView = [[CCAlertView alloc] initWithAlertTitle:ALERT_EXITPLAY sureAction:SURE cancelAction:CANCEL sureBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self exitPlayLive];
        });
    }];
    [APPDelegate.window addSubview:alertView];
}

/**
 退出直播
 */
-(void)exitPlayLive{
    [self stopTimer];
    [self.requestData requestCancel];
    self.requestData = nil;
    [self.playerView.smallVideoView removeFromSuperview];
    //移除聊天
    [self.contentView removeChatView];
    [_announcementView removeFromSuperview];
    
    [self.giftView stopAnimate];
    [self.rewardView stopAnimate];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)timerfunc {
    // (已废弃)获取在线房间人数，当登录成功后即可调用此接口，登录不成功或者退出登录后就不可以调用了，如果要求实时性比较强的话，可以写一个定时器，不断调用此接口，几秒钟发一次就可以，然后在代理回调函数中，处理返回的数据
    //最新注释:该接口默认最短响应时间为15秒,获取在线房间人数，当登录成功后即可调用此接口，登录不成功或者退出登录后就不可以调用了，如果要求实时性比较强的话，可以写一个定时器，不断调用此接口，然后在代理回调函数中，处理返回的数据
    [_requestData roomUserCount];
}

#pragma mark- SDK 必须实现的代理方法

/**
 *    @brief    请求成功
 */
-(void)requestSucceed {
//        NSLog(@"请求成功！");
    [self stopTimer];
    CCProxy *weakObject = [CCProxy proxyWithWeakObject:self];
    _userCountTimer = [NSTimer scheduledTimerWithTimeInterval:15.0f target:weakObject selector:@selector(timerfunc) userInfo:nil repeats:YES];
}

/**
 *    @brief    登录请求失败
 */
-(void)requestFailed:(NSError *)error reason:(NSString *)reason {
    NSString *message = nil;
    if (reason == nil) {
        message = [error localizedDescription];
    } else {
        message = reason;
    }
    // 添加提示窗,提示message
    [self addBanAlertView:message];
}

#pragma mark- 功能代理方法 用哪个实现哪个-----
/**
 *    @brief    收到在线人数
 */
- (void)onUserCount:(NSString *)count {
//    self.contentView.peopleCountLabel.text = [NSString stringWithFormat:@"%@人在看",count];
}
#pragma mark- 房间信息
/**
 *    @brief  获取房间信息，主要是要获取直播间模版来类型，根据直播间模版类型来确定界面布局
 *    房间简介：dic[@"desc"];
 *    房间名称：dic[@"name"];
 *    房间模版类型：[dic[@"templateType"] integerValue];
 *    模版类型为1: 聊天互动： 无 直播文档： 无 直播问答： 无
 *    模版类型为2: 聊天互动： 有 直播文档： 无 直播问答： 有
 *    模版类型为3: 聊天互动： 有 直播文档： 无 直播问答： 无
 *    模版类型为4: 聊天互动： 有 直播文档： 有 直播问答： 无
 *    模版类型为5: 聊天互动： 有 直播文档： 有 直播问答： 有
 *    模版类型为6: 聊天互动： 无 直播文档： 无 直播问答： 有
 */
-(void)roomInfo:(NSDictionary *)dic {
    _roomName = dic[@"name"];
    //添加更多菜单
//    [APPDelegate.window addSubview:self.menuView];
    NSInteger type = [dic[@"templateType"] integerValue];
    if (type == 4 || type == 5) {
        [self.playerView addSmallView];
    }else {
        //大屏模式显示跑马灯
        [self docLoadCompleteWithIndex:0];
    }
    //设置房间信息
    [_contentView roomInfo:dic withPlayView:self.playerView smallView:self.playerView.smallVideoView];
    _playerView.templateType = type;
}

#pragma mark - 打卡功能
/// 打卡功能
/// @param dic 打卡数据
- (void)hdReceivedStartPunchWithDict:(NSDictionary *)dic {
    
    if (_punchView) {
        [_punchView removeFromSuperview];
    }
    WS(weakSelf)
    self.punchView = [[CCPunchView alloc] initWithDict:dic punchBlock:^(NSString * punchid) {
        [weakSelf.requestData hdCommitPunchWithPunchId:punchid];
        NSLog(@"点击打卡");
    } isScreenLandScape:self.isScreenLandScape];
    self.punchView.commitSuccess = ^(BOOL success) {
        [weakSelf removePunchView];
    };
    [APPDelegate.window addSubview:self.punchView];
    _punchView.frame = [UIScreen mainScreen].bounds;
    [self showRollCallView];
}
/**
 *    @brief    收到结束打卡
 *    dic{
     "punchId": "punchId"
 }
 */
-(void)hdReceivedEndPunchWithDict:(NSDictionary *)dic{
    [self removePunchView];
}
/**
 *    @brief    收到打卡提交结果
 *    dic{
     "success": true,
     "data": {
         "isRepeat": false//是否重复提交打卡
     }
 }
 */
-(void)hdReceivedPunchResultWithDict:(NSDictionary *)dic{
    [self.punchView updateUIWithDic:dic];
}
//移除打卡视图
-(void)removePunchView {
    [_punchView removeFromSuperview];
    _punchView = nil;
}

#pragma mark- 获取直播开始时间和直播时长
/**
 *  @brief  获取直播开始时间和直播时长
 *  liveDuration 直播持续时间，单位（s），直播未开始返回-1"
 *  liveStartTime 新增开始直播时间（格式：yyyy-MM-dd HH:mm:ss），如果直播未开始，则返回空字符串
 */
- (void)startTimeAndDurationLiveBroadcast:(NSDictionary *)dataDic {
    SaveToUserDefaults(LIVE_STARTTIME, dataDic[@"liveStartTime"]);
    //当第一次进入时为未开始状态,设置此属性,在直播开始时给startTime赋值
    if ([dataDic[@"liveStartTime"] isEqualToString:@""] && !self.firstUnStart) {
        self.firstUnStart = YES;
    }
}

#pragma mark - 服务器端给自己设置的信息
/**
 *    @brief    服务器端给自己设置的信息(The new method)
 *    viewerId 服务器端给自己设置的UserId
 *    groupId 分组id
 *    name 用户名
 */
-(void)setMyViewerInfo:(NSDictionary *) infoDic{
    _viewerId = infoDic[@"viewerId"];
    [_contentView setMyViewerInfo:infoDic];
//        self.label = [[UILabel alloc] init];
//        [self.view addSubview:self.label];
//        self.label.frame = CGRectMake(30, 100, 400, 100);
//    self.label.text = infoDic[@"estimateStartTime"];
//    self.label.textColor = UIColor.blueColor;
//    NSLog(@"结果是%@",infoDic);
}
#pragma mark - 聊天管理
/**
 *    @brief    聊天管理(The new method)
 *    status    聊天消息的状态 0 显示 1 不显示
 *    chatIds   聊天消息的id列列表
 */
-(void)chatLogManage:(NSDictionary *) manageDic{
    [_contentView chatLogManage:manageDic];
}
#pragma mark- 聊天
/**
 *    @brief  历史聊天数据
 */
- (void)onChatLog:(NSArray *)chatLogArr {
    [_contentView onChatLog:chatLogArr];
}
/**
 *    @brief  收到公聊消息
 */
- (void)onPublicChatMessage:(NSDictionary *)dic {
    [_contentView onPublicChatMessage:dic];
    
    //判断是否是 礼物或打赏。
    //等后续内容确定了 再做修改
    NSString * msg = dic[@"msg"];
    NSString * result;
    NSMutableArray * urlArr = [self subStr:msg];
    for(NSValue *value in urlArr) {
                NSRange range=[value rangeValue];
               result = [msg substringWithRange:range];
               break;
            }
    if (urlArr.count >0 && [msg containsString:@"cem_"]) {
        NSArray *array = [msg componentsSeparatedByString:@"]"];
        NSArray *array1 = [msg componentsSeparatedByString:@"["];
        NSDictionary * animateDic = @{@"name":dic[@"username"],
                                      @"content":array1[0],
                                      @"num":array[1]};
        if (![array[1] hasPrefix:@"￥"]) {
            self.changeGift = NO;
//            self.giftView.name = dic[@"username"];
//            self.giftView.content = array1[0];
//            self.giftView.num  = array[1];
//            dispatch_async(dispatch_queue_create("useravatar", NULL), ^{
                
                //送礼物
                //            [self.giftView addAnimate:dic];
                if ([self.viewerId isEqualToString:[dic objectForKey:@"userid"]]) {
                    [self.giftView insertAnimate:animateDic];
                }else{
                    [self.giftView addAnimate:animateDic];
                }
                [self.giftView.imageView sd_setImageWithURL:[NSURL URLWithString:result]];
//            });
        } else {
            self.changeGift = YES;
//            self.rewardView.name = dic[@"username"];
//           self.rewardView.content = array1[0];
//           self.rewardView.num = array[1];
           [self.rewardView.imageView sd_setImageWithURL:[NSURL URLWithString:result]];
           //打赏
//           [self.rewardView addAnimate:dic];
            if ([self.viewerId isEqualToString:[dic objectForKey:@"userid"]]) {
                [self.rewardView insertAnimate:animateDic];
            }else{
                [self.rewardView addAnimate:animateDic];
            }
        }
    }
}

-(NSMutableArray*)subStr:(NSString *)string {
    NSError *error;
    //可以识别url的正则表达式
    NSString *regulaStr = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    NSMutableArray *rangeArr=[[NSMutableArray alloc]init];
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        NSString* substringForMatch = [string substringWithRange:match.range];
        [arr addObject:substringForMatch];
    }
    NSString *subStr=string;
    for (NSString *str in arr) {
        [rangeArr addObject:[self rangesOfString:str inString:subStr]];
    }
    return rangeArr;
//    UIFont *font = [UIFont systemFontOfSize:FontSize_28];
//    NSMutableAttributedString *attributedText;
//    attributedText=[[NSMutableAttributedString alloc]initWithString:subStr attributes:@{NSFontAttributeName :font}];
//    for(NSValue *value in rangeArr) {
//        NSInteger index=[rangeArr indexOfObject:value];
//        NSRange range=[value rangeValue];
//        [attributedText addAttribute:NSLinkAttributeName value:[NSURL URLWithString:[arr objectAtIndex:index]] range:range];
//        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
//
//    }
//    return attributedText;
}
//获取查找字符串在母串中的NSRange

- (NSValue *)rangesOfString:(NSString *)searchString inString:(NSString *)str {
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSRange range;
    if ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound) {
        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
        
    }
    return [NSValue valueWithRange:range];
}
/*
 *  @brief  收到自己的禁言消息，如果你被禁言了，你发出的消息只有你自己能看到，其他人看不到
 */
- (void)onSilenceUserChatMessage:(NSDictionary *)message {
    [_contentView onSilenceUserChatMessage:message];
}

/**
 *    @brief    当主讲全体禁言时，你再发消息，会出发此代理方法，information是禁言提示信息
 */
- (void)information:(NSString *)information {
    //添加提示窗
//    [self addBanAlertView:information];
    [self addRunDeBanAlertView:1];
}
/**
 *    @brief  收到踢出消息，停止推流并退出播放（被主播踢出）(change)
 kick_out_type
 10 在允许重复登录前提下，后进入者会登录会踢出先前登录者
 20 讲师、助教、主持人通过页面踢出按钮踢出用户
 */
- (void)onKickOut:(NSDictionary *)dictionary{
    if ([_viewerId isEqualToString:dictionary[@"viewerid"]]) {
        WS(weakSelf)
        CCAlertView *alert = [[CCAlertView alloc] initWithAlertTitle:ALERT_KICKOUT sureAction:SURE cancelAction:nil sureBlock:^{
            [weakSelf exitPlayLive];
        }];
        [APPDelegate.window addSubview:alert];
    }
}
#pragma mark- 直播未开始和开始
/**
 *    @brief  收到播放直播状态 0直播 1未直播
 */
- (void)getPlayStatue:(NSInteger)status {
    [_playerView getPlayStatue:status];
    if (status == 0 && self.firstUnStart) {
        NSDate *date = [NSDate date];// 获得时间对象
        NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
        [forMatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateStr = [forMatter stringFromDate:date];
        SaveToUserDefaults(LIVE_STARTTIME, dateStr);
    }
    if (status == 0) {
        if (!_punchView) {
                [_requestData hdInquirePunchInformation];
        }
    }
}

/**
 *    @brief  主讲开始推流
 */
- (void)onLiveStatusChangeStart {
    [_playerView onLiveStatusChangeStart];
}
/**
 *    @brief  停止直播，endNormal表示是否停止推流
 */
- (void)onLiveStatusChangeEnd:(BOOL)endNormal {
    if (self.punchView) {
        [self removePunchView];
    }
    [_playerView onLiveStatusChangeEnd:endNormal];
}
#pragma mark- 加载视频失败
/**
 *  @brief  加载视频失败
 */
- (void)play_loadVideoFail {
    [_playerView play_loadVideoFail];
}
#pragma mark- 聊天禁言
/**
 *    @brief    收到聊天禁言(The new method)
 *    mode 禁言类型 1：个人禁言  2：全员禁言
 */
-(void)onBanChat:(NSDictionary *) modeDic{
    NSInteger mode = [modeDic[@"mode"] integerValue];
    if (mode == 1) {
        return;
    } else {
        NSDictionary *dict = @{@"allowChat":@"false"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"allow_chat" object:nil userInfo:dict];
    }
//    NSString *str = ALERT_BANCHAT(mode == 1);
    //添加禁言弹窗
    [self addRunDeBanAlertView:1];
}
/**
 *    @brief    收到解除禁言事件(The new method)
 *    mode 禁言类型 1：个人禁言  2：全员禁言
 */
-(void)onUnBanChat:(NSDictionary *) modeDic{
    NSInteger mode = [modeDic[@"mode"] integerValue];
    if (mode == 1) {
        return;
    } else {
        NSDictionary *dict = @{@"allowChat":@"true"};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"allow_chat" object:nil userInfo:dict];
    }
//    NSString *str = ALERT_UNBANCHAT(mode == 1);
    //添加禁言弹窗
    [self addRunDeBanAlertView:2];
}
#pragma mark - 抽奖
/**
 *  @brief  开始抽奖
 */
- (void)start_lottery {
    if (_lotteryView) {
        [_lotteryView removeFromSuperview];
    }
    self.lotteryView = [[LotteryView alloc] initIsScreenLandScape:self.screenLandScape clearColor:NO];
    [APPDelegate.window addSubview:self.lotteryView];
    _lotteryView.frame = [UIScreen mainScreen].bounds;
    [self showRollCallView];
}
/**
 *  @brief  抽奖结果
 *  remainNum   剩余奖品数
 */
- (void)lottery_resultWithCode:(NSString *)code
                        myself:(BOOL)myself
                    winnerName:(NSString *)winnerName
                     remainNum:(NSInteger)remainNum {
    [_lotteryView lottery_resultWithCode:code myself:myself winnerName:winnerName remainNum:remainNum IsScreenLandScape:self.screenLandScape];
}
/**
 *  @brief  退出抽奖
 */
- (void)stop_lottery {
    [self.lotteryView remove];
}
#pragma mark - 问卷及问卷统计
/**
 *  @brief  问卷功能
 */
- (void)questionnaireWithTitle:(NSString *)title url:(NSString *)url {
//    //初始化第三方问卷视图
//        [self.questionNaire removeFromSuperview];
//        self.questionNaire = nil;
//        [self.view endEditing:YES];
//        self.questionNaire = [[QuestionNaire alloc] initWithTitle:title url:url isScreenLandScape:self.screenLandScape];
//    //添加第三方问卷视图
//        [self addAlerView:self.questionNaire];
}
/**
 *  @brief  提交问卷结果（成功，失败）
 */
- (void)commitQuestionnaireResult:(BOOL)success {
    WS(ws)
    [self.questionnaireSurvey commitSuccess:success];
    if(success &&self.submitedAction != 1) {
        [NSTimer scheduledTimerWithTimeInterval:3.0f target:ws selector:@selector(removeQuestionnaireSurvey) userInfo:nil repeats:NO];
    }
}
/**
 *  @brief  发布问卷
 */
- (void)questionnaire_publish {
    [self removeQuestionnaireSurvey];
}
/**
 *  @brief  获取问卷详细内容
 */
- (void)questionnaireDetailInformation:(NSDictionary *)detailDic {
    NSArray * arr = detailDic[@"subjects"];
    if (arr.count >1)return;
    NSDictionary * dict = arr[0];
    if([dict[@"type"] intValue] == 2) return;
    [self.view endEditing:YES];
    self.submitedAction     = [detailDic[@"submitedAction"] integerValue];
    //初始化问卷详情页面
    self.questionnaireSurvey = [[QuestionnaireSurvey alloc] initWithCloseBlock:^{
        [self removeQuestionnaireSurvey];
    } CommitBlock:^(NSDictionary *dic) {
        //提交问卷结果
        [self.requestData commitQuestionnaire:dic];
    } questionnaireDic:detailDic isScreenLandScape:self.screenLandScape isStastic:NO];
    //添加问卷详情
    [self addAlerView:self.questionnaireSurvey];
}
/**
 *  @brief  结束发布问卷
 */
- (void)questionnaire_publish_stop{
    WS(ws)
//    [self.questionnaireSurveyPopUp removeFromSuperview];
//    self.questionnaireSurveyPopUp = nil;
    if(self.questionnaireSurvey == nil) return;//如果已经结束发布问卷，不需要加载弹窗
    //结束编辑状态
    [self.view endEditing:YES];
    [self.questionnaireSurvey endEditing:YES];
//    //初始化结束问卷弹窗
//    self.questionnaireSurveyPopUp = [[QuestionnaireSurveyPopUp alloc] initIsScreenLandScape:self.screenLandScape SureBtnBlock:^{
        [ws removeQuestionnaireSurvey];
//    }];
    //添加问卷弹窗
    [self addAlerView:self.questionnaireSurveyPopUp];
}



#pragma mark - 随堂测
/**
 *    @brief    接收到随堂测(The new method)
 *    rseultDic    随堂测内容
 */
-(void)receivePracticeWithDic:(NSDictionary *) resultDic{
    if ([resultDic[@"isExist"] intValue] == 0) {
        return;//如果不存在随堂测，返回。
    }
    if (_testView) {
        [_testView removeFromSuperview];
        [_testView stopTimer];
    }
    [self.view endEditing:YES];
    [APPDelegate.window endEditing:YES];
    //初始化随堂测视图
    CCClassTestView *testView = [[CCClassTestView alloc] initWithTestDic:resultDic isScreenLandScape:self.screenLandScape];
    [APPDelegate.window addSubview:testView];
    self.testView = testView;
    WS(weakSelf)
    self.testView.CommitBlock = ^(NSArray * _Nonnull arr) {//提交答案回调
        [weakSelf.requestData commitPracticeWithPracticeId:resultDic[@"practice"][@"id"] options:arr];
    };
    _testView.StaticBlock = ^(NSString * _Nonnull practiceId) {//获取统计回调
        [weakSelf.requestData getPracticeStatisWithPracticeId:practiceId];
    };
}
/**
 *    @brief    随堂测提交结果(The new method)
 *    rseultDic    提交结果,调用commitPracticeWithPracticeId:(NSString *)practiceId options:(NSArray *)options后执行
 */
-(void)practiceSubmitResultsWithDic:(NSDictionary *) resultDic{
    [_testView practiceSubmitResultsWithDic:resultDic];
    
}
/**
 *    @brief    随堂测统计结果(The new method)
 *    rseultDic    统计结果,调用getPracticeStatisWithPracticeId:(NSString *)practiceId后执行
 */
-(void)practiceStatisResultsWithDic:(NSDictionary *) resultDic{
    if (_testView) {
        [self.view endEditing:YES];
        [APPDelegate.window endEditing:YES];
    }
    [_testView getPracticeStatisWithResultDic:resultDic isScreen:self.screenLandScape];
}
/**
 *    @brief    停止随堂测(The new method)
 *    rseultDic    结果
 */
-(void)practiceStopWithDic:(NSDictionary *) resultDic{
    [_testView stopTest];
}
/**
 *    @brief    关闭随堂测(The new method)
 *    rseultDic    结果
 */
-(void)practiceCloseWithDic:(NSDictionary *) resultDic{
    //移除随堂测视图
    [_testView removeFromSuperview];
    _testView = nil;
}
/**
 *    @brief    收到奖杯(The new method)
 *    dic       结果
 *    "type":  1 奖杯 2 其他
 */
-(void)prize_sendWithDict:(NSDictionary *)dic{
    NSString *name = @"";
    [self.view endEditing:YES];
    [APPDelegate.window endEditing:YES];
    if (![dic[@"viewerId"] isEqualToString:self.viewerId]) {
        name = dic[@"viewerName"];
    }
    CCCupView *cupView = [[CCCupView alloc] initWithWinnerName:name isScreen:self.screenLandScape];
    [APPDelegate.window addSubview:cupView];
}
//#ifdef LIANMAI_WEBRTC
#pragma mark - SDK连麦代理
/*
 *  @brief WebRTC连接成功，在此代理方法中主要做一些界面的更改
 */
- (void)connectWebRTCSuccess {
    [self.playerView connectWebRTCSuccess];
}
/*
 *  @brief 当前是否可以连麦
 */
- (void)whetherOrNotConnectWebRTCNow:(BOOL)connect {
    [self.playerView whetherOrNotConnectWebRTCNow:YES];
    if (connect) {
        /*
         * 当观看端主动申请连麦时，需要调用这个接口，并把本地连麦预览窗口传给SDK，SDK会在这个view上
         * 进行远程画面渲染
         * param localView:本地预览窗口，传入本地view，连麦准备时间将会自动绘制预览画面在此view上
         * param isAudioVideo:是否是音视频连麦，不是音视频即是纯音频连麦(YES表示音视频连麦，NO表示音频连麦)
         */
        [_requestData requestAVMessageWithLocalView:nil isAudioVideo:self.playerView.isAudioVideo];
    }
}
/**
 *  @brief 主播端接受连麦请求，在此代理方法中，要调用DequestData对象的
 *  - (void)saveUserInfo:(NSDictionary *)dict remoteView:(UIView *)remoteView;方法
 *  把收到的字典参数和远程连麦页面的view传进来，这个view需要自己设置并发给SDK，SDK将要在这个view上进行渲染
 */
- (void)acceptSpeak:(NSDictionary *)dict {
    [self.playerView acceptSpeak:dict];
    if(self.playerView.isAudioVideo) {
        /*
         * 当收到- (void)acceptSpeak:(NSDictionary *)dict;回调方法后，调用此方法
         * dict 正是- (void)acceptSpeak:(NSDictionary *)dict;接收到的的参数
         * remoteView 是远程连麦页面的view，需要自己设置并发给SDK，SDK将要在这个view上进行远程画面渲染
         */
        [_requestData saveUserInfo:dict remoteView:self.playerView.remoteView];
    } else {
        [_requestData saveUserInfo:dict remoteView:nil];
    }
}
/*
 *  @brief 主播端发送断开连麦的消息，收到此消息后做断开连麦操作
 */
-(void)speak_disconnect:(BOOL)isAllow {
    [self.playerView speak_disconnect:isAllow];
}
/*
 *  @brief 本房间为允许连麦的房间，会回调此方法，在此方法中主要设置UI的逻辑，
 *  在断开推流,登录进入直播间和改变房间是否允许连麦状态的时候，都会回调此方法
 */
- (void)allowSpeakInteraction:(BOOL)isAllow {
    [self.playerView allowSpeakInteraction:isAllow];
}
//#endif
#pragma mark - 添加通知
-(void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(information:) name:@"showBanChat" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self                  selector:@selector(moviePlayBackStateDidChange:)                                                name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieLoadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    
    //视频播放状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieNaturalSizeAvailableNotification:) name:IJKMPMovieNaturalSizeAvailableNotification object:nil];
    //新增扣1 扣2通知
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callOneAction) name:SENDCALLONE object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callTwoAction) name:SENDCALLTWO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendGiftAction:) name:SENDGIFT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendRewardAction:) name:SENDREWARD object:nil];


}
-(void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SENDREWARD object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:SENDGIFT object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:SENDCALLONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SENDCALLTWO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMovieNaturalSizeAvailableNotification
                                                  object:nil];

}
/**
 APP将要进入后台
 */
- (void)appWillEnterBackgroundNotification {
    //#ifdef LockView
        if (_pauseInBackGround == NO) {
            [_lockView updateLockView];
        }
    //#endif
}
/**
 APP将要进入前台
 */
- (void)appWillEnterForegroundNotification {
    if (_requestData.ijkPlayer.playbackState == IJKMPMoviePlaybackStatePaused && self.playerView.pauseButton.selected == NO) {
        [_requestData.ijkPlayer play];
    }
}
/**
 视频播放状态

 @param notification 接收到通知
 */
-(void)movieNaturalSizeAvailableNotification:(NSNotification *)notification {
    
}
/**
 视频状态改变

 @param notification 接收到通知
 */
- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    //    IJKMPMoviePlaybackStateStopped,
    //    IJKMPMoviePlaybackStatePlaying,
    //    IJKMPMoviePlaybackStatePaused,
    //    IJKMPMoviePlaybackStateInterrupted,
    //    IJKMPMoviePlaybackStateSeekingForward,
    //    IJKMPMoviePlaybackStateSeekingBackward
    //    NSLog(@"_requestData.ijkPlayer.playbackState = %ld",_requestData.ijkPlayer.playbackState);

    switch (_requestData.ijkPlayer.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            break;
        }
        case IJKMPMoviePlaybackStatePlaying:{
            [_playerView.loadingView removeFromSuperview];
            [[SaveLogUtil sharedInstance] saveLog:@"" action:SAVELOG_ALERT];
            //#ifdef LockView
                        if (_pauseInBackGround == NO) {//添加锁屏视图
                            if (!_lockView) {
                                _lockView = [[CCLockView alloc] initWithRoomName:_roomName duration:_requestData.ijkPlayer.duration];
                                /*     播放/暂停回调     */
                                WS(weakSelf)
                                _lockView.pauseCallBack = ^(BOOL pause) {
//                                    weakSelf.playerView.pauseButton.selected = pause;

                                    if (pause) {
//                                        [weakSelf.playerView stopTimer];
//                                        [weakSelf.requestDataPlayBack.ijkPlayer pause];
                                        weakSelf.playerView.pauseButton.selected = YES;
                                        weakSelf.playerView.centerButton.selected = YES;
                                        NSLog(@"走了这里");
                                    }else{
                                        weakSelf.playerView.pauseButton.selected = NO;
                                        weakSelf.playerView.centerButton.selected = NO;
//                                        [weakSelf.playerView startTimer];
//                                        [weakSelf.requestDataPlayBack.ijkPlayer play];
                                        NSLog(@"走了那里");

                                    }
                                    [weakSelf pauseButtonClicked:pause];
                                };
//                                [self.view addSubview:_lockView];
                                [[UIApplication sharedApplication].keyWindow addSubview:_lockView];

                            }else{
                                [_lockView updateLockView];
                            }
                        }
            //#endif
            break;
        }
        case IJKMPMoviePlaybackStatePaused:{
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            break;
        }
        default: {
            break;
        }
    }
}
/**
 视屏加载状态改变

 @param notification 接收到d通知
 */
-(void)movieLoadStateDidChange:(NSNotification*)notification
{
    switch (_requestData.ijkPlayer.loadState)
    {
        case IJKMPMovieLoadStateStalled:
            break;
        case IJKMPMovieLoadStatePlayable:
            break;
        case IJKMPMovieLoadStatePlaythroughOK:
            break;
        default:
            break;
    }
}
#pragma mark - 添加弹窗类事件
-(void)addAlerView:(UIView *)view{
    [APPDelegate.window addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [self showRollCallView];
}
#pragma mark - 禁言弹窗
-(void)addBanAlertView:(NSString *)str{
    [_alertView removeFromSuperview];
    _alertView = nil;
    _alertView = [[CCAlertView alloc] initWithAlertTitle:str sureAction:@"好的" cancelAction:nil sureBlock:nil];
    [APPDelegate.window addSubview:_alertView];
}
-(void)addRunDeBanAlertView:(NSInteger)mode{
    if (_alertView != nil) {
        [_alertView removeFromSuperview];
    }
    _alertView = [[CCAlertView alloc] initRunDeWithAlertTitle:@"" mode:mode];
    [APPDelegate.window addSubview:_alertView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_alertView removeFromSuperview];
    });
}
-(void)addAnnouncementAlertView:(NSString *)str{
    [_alertView removeFromSuperview];
    _alertView = nil;
    _alertView = [[CCAlertView alloc] initAnnouncementAlertTitle:str sureAction:@"知道了" sureBlock:^{
        [_alertView removeFromSuperview];
    }];
    [APPDelegate.window addSubview:_alertView];
}
#pragma mark - 懒加载
//playView
-(CCPlayerView *)playerView{
    if (!_playerView) {
        //视频视图
        _playerView = [[CCPlayerView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625) docViewType:_isSmallDocView];
        _playerView.delegate = self;
#warning 这里要输入房间类型
        _playerView.smallVideoView.isZhuanTiKe = YES;
        WS(weakSelf)
        //发送聊天
        _playerView.sendChatMessage = ^(NSString * sendChatMessage) {
            [weakSelf sendChatMessageWithStr:sendChatMessage];
        };
        //#ifdef LIANMAI_WEBRTC
        //是否是请求连麦
        _playerView.connectSpeak = ^(BOOL connect) {
            if (connect) {
                [weakSelf.requestData gotoConnectWebRTC];
            }else{
                [weakSelf.requestData disConnectSpeak];
            }
        };
        //设置连麦视图
        _playerView.setRemoteView = ^(CGRect frame) {
            [weakSelf.requestData setRemoteVideoFrameA:frame];
        };
        //#endif
  //#ifdef 公开课
//        _playerView.CCDocViewGestureRecognizerStateEndedBlock = ^(CGRect rect) {
//            [weakSelf upDateInteractionViewSubViewWith:rect];
//        };
//#endif
    }
    return _playerView;
}
//  //#ifdef 公开课
//- (void)upDateInteractionViewSubViewWith:(CGRect)rect{
//    if ((rect.origin.y>=SCREEN_WIDTH *0.5625)&&(rect.origin.y<SCREEN_WIDTH *0.5625+85)&&(rect.origin.x<CCGetRealFromPt(202)))
//    {
//        //要关闭
//        [self.contentView upDateHeaderViewConstraintIsClose:YES];
//    }else
//    {
//        //要打开
//        [self.contentView upDateHeaderViewConstraintIsClose:NO];
//    }
//
//}
//#endif


#pragma - 公开课
//-(CCPublicInteractionView *)contentView{
//    if (!_contentView) {
//        WS(ws)
////        CGRectMake(0, CCGetRealFromPt(462)+SCREEN_STATUS, SCREEN_WIDTH,IS_IPHONE_X ? CCGetRealFromPt(835) + 90:CCGetRealFromPt(835))
//        _contentView = [[CCPublicInteractionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.playerView.frame)+(IS_IPHONE_X? 40:20), SCREEN_WIDTH, SCREENH_HEIGHT - CGRectGetMaxY(self.playerView.frame)-(IS_IPHONE_X? 40:20)) hiddenMenuView:^{
////            [ws hiddenMenuView];
//        } chatBlock:^(NSString * _Nonnull msg) {
//            [ws.requestData chatMessage:msg];
//        } privateChatBlock:^(NSString * _Nonnull anteid, NSString * _Nonnull msg) {
//            [ws.requestData privateChatWithTouserid:anteid msg:msg];
//        } questionBlock:^(NSString * _Nonnull message) {
//            [ws.requestData question:message];
//        } docViewType:_isSmallDocView];
//        _contentView.playerView = self.playerView;
//    }
//    return _contentView;
//}
#pragma mark - 专题课
-(CCInteractionView *)contentView{
    if (!_contentView) {
        WS(ws)
        _contentView = [[CCInteractionView alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(self.playerView.frame)+(IS_IPHONE_X? 40:20), SCREEN_WIDTH,IS_IPHONE_X ? CCGetRealFromPt(835) + 90:CCGetRealFromPt(835)) hiddenMenuView:^{

        } chatBlock:^(NSString * _Nonnull msg) {
            [ws.requestData chatMessage:msg];
        } privateChatBlock:^(NSString * _Nonnull anteid, NSString * _Nonnull msg) {
            [ws.requestData privateChatWithTouserid:anteid msg:msg];
        } questionBlock:^(NSString * _Nonnull message) {
            [ws.requestData question:message];
        } docViewType:_isSmallDocView];
        _contentView.playerView = self.playerView;
        _contentView.actionBlock = ^(NSInteger btnTag) {
            [ws changepPlayAndRecoder:btnTag];
        };
    }
    return _contentView;
}
-(CCPlayBack *)playerView1{
    if (!_playerView1) {
        //视频视图
        _playerView1 = [[CCPlayBack alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625) docViewType:_isSmallDocView];
        _playerView1.delegate = self;
 #warning 这里要输入房间类型
        _playerView1.smallVideoView.isZhuanTiKe = YES;
    }
    return _playerView1;
}









-(CCGiftRewardPopView *)giftView
{
    if (!_giftView) {
        _giftView = [[CCGiftRewardPopView alloc]init];
        _giftView.frame = CGRectMake(-_giftView.frame.size.width, 320, _giftView.frame.size.width, _giftView.frame.size.height);
        _giftView.style = CCGiftRewardPopViewStyleGift;
        [[UIApplication sharedApplication].keyWindow addSubview:_giftView];
    }
    return _giftView;
}

-(CCGiftRewardPopView *)rewardView
{
    if (!_rewardView) {
        _rewardView = [[CCGiftRewardPopView alloc]init];
        _rewardView.frame = CGRectMake(-_rewardView.frame.size.width, 391, _rewardView.frame.size.width, _rewardView.frame.size.height);
        _rewardView.style = CCGiftRewardPopViewStyleReward;
        _rewardView.imageView.image = [UIImage imageNamed:@"live_chat_money.png"];
        [[UIApplication sharedApplication].keyWindow addSubview:_rewardView];
    }
    return _rewardView;
}
/**
 全屏按钮点击代理

 @param tag 1视频为主，2文档为主
 */
-(void)quanpingPlayBackBtnClicked:(NSInteger)tag {
    if (tag == 1) {
        [self.playerView1.requestDataPlayBack changePlayerFrame:self.view.frame];
    } else {
        [self.playerView1.requestDataPlayBack changeDocFrame:self.view.frame];
    }

}
- (void)changePlayBack:(NSInteger)btnTag {
    if (btnTag == 1) {
        self.isScreenLandScape = YES;
        [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        self.isScreenLandScape = NO;
        [UIApplication sharedApplication].statusBarHidden = YES;
        //隐藏互动视图
        self.contentView.hidden = YES;
    } else {
        self.isScreenLandScape = YES;
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        [UIApplication sharedApplication].statusBarHidden = NO;
        self.isScreenLandScape = NO;
        self.contentView.hidden = NO;
    }
    
}
#pragma mark - 切换直播和回放
- (void)changepPlayAndRecoder:(NSInteger)btnTag{
    if (btnTag == 2) {//直播切回放
        /**
         播回放时把参数存起来
         SaveToUserDefaults(PLAYBACK_USERID,_textFieldUserId.text);
         SaveToUserDefaults(PLAYBACK_ROOMID,_textFieldRoomId.text);
         SaveToUserDefaults(PLAYBACK_LIVEID,_textFieldLiveId.text);
         SaveToUserDefaults(PLAYBACK_RECORDID,_textFieldRecordId.text);
         SaveToUserDefaults(PLAYBACK_USERNAME,_textFieldUserName.text);
         SaveToUserDefaults(PLAYBACK_PASSWORD,_textFieldUserPassword.text);
         播直播是参数存储如下
         SaveToUserDefaults(WATCH_USERID,_textFieldUserId.text);
         SaveToUserDefaults(WATCH_ROOMID,_textFieldRoomId.text);
         SaveToUserDefaults(WATCH_USERNAME,_textFieldUserName.text);
         SaveToUserDefaults(WATCH_PASSWORD,_textFieldUserPassword.text);
         
         当你点击的时候能拿到对应的参数,存起来即可,SDK 配置参数均为读取存起来的值
         这样可以直接读取了
         */
        [self.marqueeView removeFromSuperview];
        [self.marqueeView1 removeFromSuperview];
        [self stopTimer];
        [self.requestData requestCancel];
        [self.lockView removeFromSuperview];
        self.requestData = nil;
        [self.playerView.smallVideoView removeFromSuperview];
        self.contentView.chatView.hidden = YES;
        [_announcementView removeFromSuperview];
        [self.playerView removeFromSuperview];
        [self removeObserver];
        [self.view addSubview:self.playerView1];
        WS(weakSelf)
        self.playerView1.changePlayBack = ^(NSInteger btnTag) {
            [weakSelf changePlayBack:btnTag];
        };
        self.playerView1.exitCallBack = ^{
            [weakSelf dismissViewControllerAnimated:YES completion:nil];

        };
        [self.playerView1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.height.mas_equalTo(SCREEN_WIDTH *0.5625);
            make.top.equalTo(self.view).offset(SCREEN_STATUS);
        }];
    } else {//回放切直播
        [self.playerView1.marqueeView1 removeFromSuperview];
        [self.playerView1.marqueeView removeFromSuperview];
        [self.playerView1.lockView removeFromSuperview];
        [self.playerView1 playBackRequestCancel];
        [self.playerView1.smallVideoView removeFromSuperview];
        [self.playerView1 removeFromSuperview];
        self.playerView1 = nil;
        self.contentView.chatView.hidden = NO;
        [self.view addSubview:self.playerView];
        [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.height.mas_equalTo(SCREEN_WIDTH *0.5625);
            make.top.equalTo(self.view).offset(SCREEN_STATUS);
        }];
        [self integrationSDK];
        [self addObserver];
        
    }

}
//竖屏模式下点击空白退出键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.screenLandScape == NO) {
        [self.view endEditing:YES];
    }
}
//隐藏home条
- (BOOL)prefersHomeIndicatorAutoHidden {
    return  YES;
}
-(void) stopTimer {
    if([_userCountTimer isValid]) {
        [_userCountTimer invalidate];
        _userCountTimer = nil;
    }
}
//问卷和问卷统计
//移除问卷视图
-(void)removeQuestionnaireSurvey {
    [_questionnaireSurvey removeFromSuperview];
    _questionnaireSurvey = nil;
    [_questionnaireSurveyPopUp removeFromSuperview];
    _questionnaireSurveyPopUp = nil;
}
//签到
-(RollcallView *)rollcallView {
    if(!_rollcallView) {
        RollcallView *rollcallView = [[RollcallView alloc] initWithDuration:self.duration lotteryblock:^{
            [self.requestData answer_rollcall];//签到
        } isScreenLandScape:self.screenLandScape];
        _rollcallView = rollcallView;
    }
    return _rollcallView;
}
//移除签到视图
-(void)removeRollCallView {
    [_rollcallView removeFromSuperview];
    _rollcallView = nil;
}
//显示签到视图
-(void)showRollCallView{
    if (_rollcallView) {
        [APPDelegate.window bringSubviewToFront:_rollcallView];
    }
}
//#ifdef LIANMAI_WEBRTC
//监听菜单按钮的selected属性
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    BOOL hidden = change[@"new"] == 0 ? YES: NO;
    [_playerView menuViewSelected:hidden];
}
//#endif

/**
 *  @brief  公告
 */
- (void)announcement:(NSString *)str {
    if (str) {
        [self addAnnouncementAlertView:str];
    }
    
}
/**
 *  @brief  监听到有公告消息
 */
- (void)on_announcement:(NSDictionary *)dict {
    NSLog(@"%@",dict);
    if ([dict[@"action"] isEqualToString:@"remove"]) {
        return;
    }
     [self addAnnouncementAlertView:dict[@"announcement"]];
}


-(void)dealloc{
//    NSLog(@"%s", __func__);
    /*      自动登录情况下，会存在移除控制器但是SDK没有销毁的情况 */
    if (_requestData) {
        [_requestData requestCancel];
        _requestData = nil;
    }
}
@end
