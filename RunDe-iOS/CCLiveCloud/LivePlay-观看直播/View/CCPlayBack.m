//
//  CCPlayBack.m
//  CCLiveCloud
//
//  Created by Clark on 2019/10/23.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCPlayBack.h"
#import "Utility.h"
#import "InformationShowView.h"
#import "CCAlertView.h"//提示框
#import "CCProxy.h"



#import <AVFoundation/AVFoundation.h>
@interface CCPlayBack ()<RequestDataPlayBackDelegate,UIScrollViewDelegate>
@property (nonatomic, strong)NSTimer                    * playerTimer;//隐藏导航定时器
@property (nonatomic, strong)InformationShowView        * informationViewPop;//提示视图
@property (nonatomic, assign)BOOL                       isSmallDocView;//是否是文档小窗

@property (nonatomic, strong)UILabel                    * unStart;//重新播放


@property (nonatomic,assign) BOOL                       pauseInBackGround;//后台是否暂停
@property (nonatomic,assign) BOOL                       enterBackGround;//是否进入后台
@property (nonatomic,copy)  NSString                    * groupId;//聊天分组
@property (nonatomic,copy)  NSString                    * roomName;//房间名
@property (nonatomic, strong)UIButton                   *shareButton;//分享

#pragma mark - 文档显示模式
//@property (nonatomic,assign)BOOL                        isSmallDocView;//是否是文档小屏
@property (nonatomic,strong)UIView                      * onceDocView;//临时DocView(双击ppt进入横屏调用)
@property (nonatomic,strong)UIView                      * oncePlayerView;//临时playerView(双击ppt进入横屏调用)
@property (nonatomic,strong)UILabel                  *label;

@property(nonatomic,strong)NSDictionary * jsonDict;


@end
@implementation CCPlayBack

//初始化视图
- (instancetype)initWithFrame:(CGRect)frame docViewType:(BOOL)isSmallDocView{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        _sliderValue = 0;//初始化滑动条进度
        _playBackRate = 1.0;//初始化回放速率
//        _isSmallDocView = isSmallDocView;//是否是文档小窗
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
         _pauseInBackGround = NO;
         _isSmallDocView = YES;
        [self setupUI];
        [self addObserver];//添加通知
        [self integrationSDK];//集成SDK
    }
    return self;
}


//集成SDK
- (void)integrationSDK {
    UIView *docView = _smallVideoView;
    PlayParameter *parameter = [[PlayParameter alloc] init];
    parameter.userId = GetFromUserDefaults(PLAYBACK_USERID);//userId
    parameter.roomId = GetFromUserDefaults(PLAYBACK_ROOMID);//roomId
    parameter.liveId = GetFromUserDefaults(PLAYBACK_LIVEID);//liveId
    parameter.recordId = GetFromUserDefaults(PLAYBACK_RECORDID);//回放Id
    parameter.viewerName = GetFromUserDefaults(PLAYBACK_USERNAME);//用户名
    parameter.token = GetFromUserDefaults(PLAYBACK_PASSWORD);//密码
    parameter.docParent = docView;//文档小窗
    parameter.docFrame = CGRectMake(0, 0, docView.frame.size.width, docView.frame.size.height);//文档小窗大小
    parameter.playerParent = self;//视频视图
    parameter.playerFrame = CGRectMake(0, 0,self.frame.size.width, self.frame.size.height);//视频位置,ps:起始位置为视频视图坐标
    parameter.security = YES;//是否开启https,建议开启
    parameter.PPTScalingMode = 4;//ppt展示模式,建议值为4
    parameter.pauseInBackGround = _pauseInBackGround;//后台是否暂停
    parameter.defaultColor = [UIColor whiteColor];//ppt默认底色，不写默认为白色
    parameter.scalingMode = 1;//屏幕适配方式
    parameter.pptInteractionEnabled = !_isSmallDocView;//是否开启ppt滚动
//        parameter.groupid = self.groupId;//用户的groupId
    _requestDataPlayBack = [[RequestDataPlayBack alloc] initWithParameter:parameter];
    _requestDataPlayBack.delegate = self;
    
    /* 设置playerView */
    [self showLoadingView];//显示视频加载中提示
}
- (void)receivedMarqueeInfo:(NSDictionary *)dic {
    if (dic == nil) {
        return;
    }
    self.jsonDict = dic;
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
                  self.marqueeView.fatherView = self.smallVideoView;
                  self.marqueeView1.fatherView = self;
                  self.smallVideoView.layer.masksToBounds = YES;
             
    
}
- (void)docLoadCompleteWithIndex:(NSInteger)index {
    if (index == 0) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.smallVideoView addSubview:self.marqueeView];
        [self addSubview:self.marqueeView1];
        [self.marqueeView startMarquee];
        [self.marqueeView1 startMarquee];
    });
    }
}
#pragma mark- 必须实现的代理方法

/**
 *    @brief    请求成功
 */
-(void)requestSucceed {
    //    NSLog(@"请求成功！");
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
    //  NSLog(@"请求失败:%@", message);
    NSArray *subviews = [APPDelegate.window subviews];
    
    // 如果没有子视图就直接返回
    if ([subviews count] == 0) return;
    
    for (UIView *subview in subviews) {
        if ([[subview class] isEqual:[CCAlertView class]]) {
            [subview removeFromSuperview];
        }
        
    }
    CCAlertView *alertView = [[CCAlertView alloc] initWithAlertTitle:message sureAction:@"好的" cancelAction:nil sureBlock:nil];
    [APPDelegate.window addSubview:alertView];
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
    NSInteger type = [dic[@"templateType"] integerValue];
       if (type == 4 || type == 5) {
           [self addSmallView];
       }

}
#pragma mark- 回放的开始时间和结束时间
/**
 *  @brief 回放的开始时间和结束时间
 */
-(void)liveInfo:(NSDictionary *)dic {
//    NSLog(@"%@",dic);
     SaveToUserDefaults(LIVE_STARTTIME, dic[@"startTime"]);
}

//监听播放状态
-(void)movieLoadStateDidChange:(NSNotification*)notification
{
//    NSLog(@"当前状态是%lu",(unsigned long)_requestDataPlayBack.ijkPlayer.loadState);
//    if (_requestDataPlayBack.ijkPlayer.loadState == 4) {
//        [self.playerView showLoadingView];
//    } else if (_requestDataPlayBack.ijkPlayer.loadState == 3) {
//        [self.playerView removeLoadingView];
//    }
    switch (_requestDataPlayBack.ijkPlayer.loadState)
    {
        case IJKMPMovieLoadStateStalled:
//            NSLog(@"当前状态是a%lu",(unsigned long)_requestDataPlayBack.ijkPlayer.loadState);

            break;
        case IJKMPMovieLoadStatePlayable:
//            NSLog(@"当前状态是b%lu",(unsigned long)_requestDataPlayBack.ijkPlayer.loadState);

            break;
        case IJKMPMovieLoadStatePlaythroughOK:
//            NSLog(@"当前状态是c%lu",(unsigned long)_requestDataPlayBack.ijkPlayer.loadState);

            break;
            //IJKMPMovieLoadStateUnknown
        case IJKMPMovieLoadStateUnknown:
//            NSLog(@"当前状态是d%lu",(unsigned long)_requestDataPlayBack.ijkPlayer.loadState);
            
            break;
        default:
            break;
    }
}
- (void)moviePlayerPlaybackDidFinish:(NSNotification*)notification {
    NSLog(@"播放完成");
}
//回放速率改变
- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    switch (_requestDataPlayBack.ijkPlayer.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            break;
        }
        case IJKMPMoviePlaybackStatePlaying:
        case IJKMPMoviePlaybackStatePaused: {

            if(self.pauseButton.selected == YES && [_requestDataPlayBack isPlaying]) {
                [_requestDataPlayBack pausePlayer];
            }
            if(self.loadingView && ![self.timer isValid]) {
//            if(![self.playerView.timer isValid]) {

//                NSLog(@"__test 重新开始播放视频, slider.value = %f", _playerView.slider.value);
                //#ifdef LockView
                                if (_pauseInBackGround == NO) {//后台支持播放
                                    [self setLockView];//设置锁屏界面
                                }
                //#endif
                [self removeLoadingView];//移除加载视图
                /*      保存日志     */
                [[SaveLogUtil sharedInstance] saveLog:@"" action:SAVELOG_ALERT];
                
                
                /* 当视频被打断时，重新开启视频需要校对时间 */
                if (self.slider.value != 0) {
                    _requestDataPlayBack.currentPlaybackTime = self.slider.value;
                    //开启playerView的定时器,在timerfunc中去校对SDK中播放器相关数据
                    [self startTimer];
                    return;
                }
                
                
                /*   从0秒开始加载文档  */
                [_requestDataPlayBack continueFromTheTime:0];
                /*   Ps:从100秒开始加载视频  */
//                [_requestDataPlayBack continueFromTheTime:100];
//                _requestDataPlayBack.currentPlaybackTime = 100;
                /*
                 //重新播放
                 [self.requestDataPlayBack replayPlayer];
                 self.requestDataPlayBack.currentPlaybackTime = 0;
                 self.playerView.sliderValue = 0;
                 */
                //开启playerView的定时器,在timerfunc中去校对SDK中播放器相关数据
                [self startTimer];
            }
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
//#ifdef LockView
/**
 设置锁屏播放器界面
 */
-(void)setLockView{
    if (_lockView) {//如果当前已经初始化，return;
        
        return;
    }
    _lockView = [[CCLockView alloc] initWithRoomName:_roomName duration:_requestDataPlayBack.ijkPlayer.duration];
//    [self addSubview:_lockView];
    [[UIApplication sharedApplication].keyWindow addSubview:_lockView];
    [_requestDataPlayBack.ijkPlayer setPauseInBackground:self.pauseInBackGround];
    WS(weakSelf)
    /*     播放/暂停回调     */
    _lockView.pauseCallBack = ^(BOOL pause) {
        weakSelf.pauseButton.selected = pause;
        weakSelf.centerButton.selected = pause;
        if (pause) {
            [weakSelf stopTimer];
            [weakSelf.requestDataPlayBack.ijkPlayer pause];
        }else{
            [weakSelf startTimer];
            [weakSelf.requestDataPlayBack.ijkPlayer play];
        }
    };
    /*     快进/快退回调     */
    _lockView.progressBlock = ^(int time) {
//        NSLog(@"---playBack快进/快退至%d秒", time);
        weakSelf.requestDataPlayBack.currentPlaybackTime = time;
        weakSelf.slider.value = time;
        weakSelf.sliderValue = weakSelf.slider.value;
    };
}
//#endif
- (void)playBackRequestCancel {
    [self stopTimer];
    [self stopPlayerTimer];
    if (_requestDataPlayBack) {
        [_requestDataPlayBack requestCancel];
        _requestDataPlayBack = nil;
    }
    [self removeObserver];
}
//移除通知
- (void)dealloc {
//    NSLog(@"%s", __func__);
    /*      自动登录情况下，会存在移除控制器但是SDK没有销毁的情况 */

}

#pragma mark - 添加通知
//通知监听
-(void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieLoadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

//移除通知
-(void) removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}
/**
 APP将要进入前台
 */
- (void)appWillEnterForegroundNotification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _enterBackGround = NO;
    });
    //#ifdef LockView
        /*  当视频播放被打断时，重新加载视频  */
        if (!self.requestDataPlayBack.ijkPlayer.playbackState) {
            [self.requestDataPlayBack replayPlayer];
            [self.lockView updateLockView];
        }
    //#endif
    if (self.pauseButton.selected == NO) {
        [self startTimer];
    }
}

/**
 APP将要进入后台
 */
- (void)appWillEnterBackgroundNotification {
    _enterBackGround = YES;
    UIApplication *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier taskID = 0;
    taskID = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:taskID];
    }];
    if (taskID == UIBackgroundTaskInvalid) {
        return;
    }
    [self stopTimer];
}

/**
 程序从后台激活
 */
- (void)applicationDidBecomeActiveNotification {
    if (_enterBackGround == NO && ![_requestDataPlayBack isPlaying]) {
        /*  如果当前视频不处于播放状态，重新进行播放,初始化播放状态 */
        [_requestDataPlayBack replayPlayer];
        [self stopTimer];
        [self showLoadingView];
        //#ifdef LockView
                [_lockView updateLockView];
        //#endif
//        NSLog(@"__test 视频被打断，重新播放视频");
//        NSLog(@"__test 当前的播放时间为:%f", _playerView.slider.value);
    }
}
#pragma mark - 横竖屏旋转设置
//旋转方向
- (BOOL)shouldAutorotate{
    if (self.isScreenLandScape == YES) {
        return YES;
    }
    return NO;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)prefersHomeIndicatorAutoHidden {

    return  YES;
}







//滑动事件
- (void) UIControlEventTouchDown:(UISlider *)sender {
    UIImage *image = [UIImage imageNamed:@"progressBar"];//图片模式，不设置的话会被压缩
    [_slider setThumbImage:image forState:UIControlStateNormal];//设置图片
}
//滑动完成
- (void) durationSliderDone:(UISlider *)sender
{
    UIImage *image2 = [UIImage imageNamed:@"progressBar"];//图片模式，不设置的话会被压缩
    [_slider setThumbImage:image2 forState:UIControlStateNormal];//设置图片
    _pauseButton.selected = NO;
    int duration = (int)sender.value;
    _leftTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", duration / 60, duration % 60];
    _slider.value = duration;
    if(duration == 0) {
        _sliderValue = 0;
    }
    WS(weakSelf)
    //滑块完成回调
//    self.sliderCallBack(duration);
    weakSelf.requestDataPlayBack.currentPlaybackTime = duration;
    //#ifdef LockView
            /*  校对锁屏播放器进度 */
            [weakSelf.lockView updateCurrentDurtion:weakSelf.requestDataPlayBack.currentPlaybackTime];
    //#endif
    if (weakSelf.requestDataPlayBack.ijkPlayer.playbackState != IJKMPMoviePlaybackStatePlaying) {
        [weakSelf.requestDataPlayBack startPlayer];
        [weakSelf startTimer];
    }
}
//滑块正在移动时
- (void) durationSliderMoving:(UISlider *)sender
{
    _pauseButton.selected = NO;
    int duration = (int)sender.value;
    _leftTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", duration / 60, duration % 60];
    _slider.value = duration;
    //滑块移动回调
//    self.sliderMoving();
    if (self.requestDataPlayBack.ijkPlayer.playbackState != IJKMPMoviePlaybackStatePaused) {
        [self.requestDataPlayBack pausePlayer];
        [self stopTimer];
    }
}

/**
 隐藏导航
 */
- (void)LatencyHiding {
    if (self.bottomShadowView.hidden == NO) {
        self.bottomShadowView.hidden = YES;
        self.topShadowView.hidden = YES;
    }
}

/**
 隐藏导航

 @param recognizer 手势
 */
- (void)doTapChange:(UITapGestureRecognizer*) recognizer {
    
    if (self.bottomShadowView.hidden == YES) {
        self.bottomShadowView.hidden = NO;
        self.topShadowView.hidden = NO;
        [self.topShadowView becomeFirstResponder];
        [self bringSubviewToFront:self.topShadowView];
        [self bringSubviewToFront:self.bottomShadowView];
    } else {
        self.bottomShadowView.hidden = YES;
        self.topShadowView.hidden = YES;
        [self.topShadowView resignFirstResponder];
    }
    [self endEditing:NO];
    
}

/**
 创建UI
 */
- (void)setupUI {
    //上面阴影
    self.topShadowView =[[UIView alloc] init];
     UIImageView *topShadow = [[UIImageView alloc] init];
     topShadow.image = [UIImage imageNamed:@"playerBar_against"];
     [self addSubview:self.topShadowView];
     [self.topShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
         make.edges.equalTo(self);
     }];
    //返回按钮
    self.backButton = [[UIButton alloc] init];//
    [self.backButton setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    self.backButton.tag = 1;
    self.backButton.layer.shadowOffset =  CGSizeMake(4, 0);           //阴影的偏移量
    self.backButton.layer.shadowOpacity = 0.8;                        //阴影的不透明度
    self.backButton.layer.shadowColor = [UIColor orangeColor].CGColor;//阴影的颜色

    [self.topShadowView addSubview:_backButton];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topShadowView).offset(CCGetRealFromPt(20));
        make.top.equalTo(self.topShadowView).offset(CCGetRealFromPt(14));
        make.width.height.mas_equalTo(CCGetRealFromPt(50));
    }];
    
    //分享按钮
    self.shareButton = [[UIButton alloc] init];
    self.shareButton.titleLabel.textColor = [UIColor whiteColor];
    self.shareButton.titleLabel.font = [UIFont systemFontOfSize:FontSize_30];
    self.shareButton.tag = 1;
//    [self.shareButton setTitle:PLAY_CHANGEVIDEO forState:UIControlStateNormal];
    [self.shareButton setBackgroundImage:[UIImage imageNamed:@"live_share"] forState:UIControlStateNormal];
    [self.topShadowView addSubview:_shareButton];
    [self.shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topShadowView).offset(CCGetRealFromPt(-18));
        make.top.equalTo(self.topShadowView).offset(CCGetRealFromPt(16));
        make.height.mas_equalTo(CCGetRealFromPt(70));
        make.width.mas_equalTo(CCGetRealFromPt(70));
    }];
    [self.shareButton addTarget:self action:@selector(shareButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //切换视频
    self.changeButton = [[UIButton alloc] init];
    self.changeButton.titleLabel.textColor = [UIColor whiteColor];
    self.changeButton.titleLabel.font = [UIFont systemFontOfSize:FontSize_30];
    self.changeButton.tag = 1;
//    [self.changeButton setTitle:PLAY_CHANGEVIDEO forState:UIControlStateNormal];
    [self.changeButton setBackgroundImage:[UIImage imageNamed:@"live_switchscreen"] forState:UIControlStateNormal];
    [self.topShadowView addSubview:_changeButton];
    [self.changeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topShadowView).offset(CCGetRealFromPt(-18));
        make.top.equalTo(self.shareButton.mas_bottom).offset(CCGetRealFromPt(20));
        make.height.mas_equalTo(CCGetRealFromPt(70));
        make.width.mas_equalTo(CCGetRealFromPt(70));
    }];

    //下面阴影
    self.bottomShadowView =[[UIView alloc] init];
//    UIImageView *bottomShadow = [[UIImageView alloc] init];
//    bottomShadow.image = [UIImage imageNamed:@"playerBar"];
    self.bottomShadowView.backgroundColor = [UIColor colorWithRed:5/255.0 green:0/255.0 blue:1/255.0 alpha:0.6];
    [self addSubview:self.bottomShadowView];
    [self.bottomShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(CCGetRealFromPt(70));
    }];

    //播放底部暂停播放
    self.pauseButton = [[UIButton alloc] init];//live_progress_play
    [self.pauseButton setBackgroundImage:[UIImage imageNamed:@"live_progress_stop"] forState:UIControlStateNormal];
    [self.pauseButton setBackgroundImage:[UIImage imageNamed:@"live_progress_play"] forState:UIControlStateSelected];
    [self.bottomShadowView addSubview:_pauseButton];
    self.pauseButton.tag = 1;
    [self.pauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomShadowView);
        make.width.height.mas_equalTo(CCGetRealFromPt(40));
        make.left.equalTo(self.bottomShadowView).offset(CCGetRealFromPt(26));
    }];
    //中间暂停按钮
    self.centerButton = [[UIButton alloc] init];//live_screen_play
    [self.centerButton setBackgroundImage:[UIImage imageNamed:@"live_screen_stop"] forState:UIControlStateNormal];
    [self.centerButton setBackgroundImage:[UIImage imageNamed:@"live_screen_play"] forState:UIControlStateSelected];
    [self.topShadowView addSubview:_centerButton];
    self.centerButton.tag = 1;
    [self.centerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.topShadowView);
        make.width.height.mas_equalTo(CCGetRealFromPt(90));
    }];

    //当前播放时间
    _leftTimeLabel = [[UILabel alloc] init];
    _leftTimeLabel.text = @"00:00";
    _leftTimeLabel.userInteractionEnabled = NO;
    _leftTimeLabel.textColor = [UIColor whiteColor];
    _leftTimeLabel.font = [UIFont systemFontOfSize:FontSize_24];
    _leftTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self.bottomShadowView addSubview:_leftTimeLabel];
    [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.pauseButton);
        make.left.equalTo(self.pauseButton.mas_right).offset(CCGetRealFromPt(10));
        make.width.mas_equalTo(CCGetRealFromPt(90));
    }];
    [self.leftTimeLabel layoutIfNeeded];
    //时间中间的/
    UILabel * placeholder = [[UILabel alloc] init];
    placeholder.text = @"/";
    placeholder.textColor = [UIColor whiteColor];
    placeholder.font = [UIFont systemFontOfSize:FontSize_24];
    placeholder.textAlignment = NSTextAlignmentCenter;
    [self.bottomShadowView addSubview:placeholder];
    [placeholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.leftTimeLabel);
        make.left.equalTo(self.leftTimeLabel.mas_right);
    }];
    //总时长
    _rightTimeLabel = [[UILabel alloc] init];
    _rightTimeLabel.text = @"--:--";
    _rightTimeLabel.userInteractionEnabled = NO;
    _rightTimeLabel.textColor = [UIColor whiteColor];
    _rightTimeLabel.font = [UIFont systemFontOfSize:FontSize_24];
    _rightTimeLabel.alpha = 0.6f;
    _rightTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self.bottomShadowView addSubview:_rightTimeLabel];
    [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.leftTimeLabel.mas_right).offset(CCGetRealFromPt(10));
        make.centerY.equalTo(self.leftTimeLabel);
        make.width.mas_equalTo(CCGetRealFromPt(90));

    }];
    [self.rightTimeLabel layoutIfNeeded];

    //滑动条
    _slider = [[MySlider alloc] init];
    //设置滑动条最大值
    _slider.maximumValue=0;
    //设置滑动条的最小值，可以为负值
    _slider.minimumValue=0;
    //设置滑动条的滑块位置float值
    _slider.value=[GetFromUserDefaults(SET_BITRATE) integerValue];
    //左侧滑条背景颜色
    _slider.minimumTrackTintColor = CCRGBColor(255,102,51);
    //右侧滑条背景颜色
    _slider.maximumTrackTintColor = CCRGBColor(153, 153, 153);
    //设置滑块的颜色
    [_slider setThumbImage:[UIImage imageNamed:@"progressBar"] forState:UIControlStateNormal];
    //对滑动条添加事件函数
    [_slider addTarget:self action:@selector(durationSliderMoving:) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(durationSliderDone:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    [_slider addTarget:self action:@selector(UIControlEventTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.bottomShadowView addSubview:_slider];

    //全屏按钮
    self.quanpingButton = [[UIButton alloc] init];
    [self.quanpingButton setBackgroundImage:[UIImage imageNamed:@"live_full screen"] forState:UIControlStateNormal];
    [self.quanpingButton setBackgroundImage:[UIImage imageNamed:@"live_small screen"] forState:UIControlStateSelected];
    self.quanpingButton.tag = 1;
    [self.bottomShadowView addSubview:_quanpingButton];
    [self.quanpingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomShadowView);
        make.right.equalTo(self.bottomShadowView).offset(CCGetRealFromPt(-20));
        make.width.height.mas_equalTo(CCGetRealFromPt(40));
    }];

    //倍速按钮
    self.speedButton = [[UIButton alloc] init];
    [self.speedButton setTitle:@"1.0x" forState:UIControlStateNormal];
    self.speedButton.titleLabel.font = [UIFont systemFontOfSize:FontSize_28];
    [self.bottomShadowView addSubview:_speedButton];
    [self.speedButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomShadowView);
        make.right.equalTo(self.quanpingButton.mas_left).offset(CCGetRealFromPt(-10));
        make.width.mas_equalTo(CCGetRealFromPt(70));
        make.height.mas_equalTo(CCGetRealFromPt(56));
    }];
    [self.speedButton layoutIfNeeded];

    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomShadowView).offset(3);
        make.right.equalTo(self.bottomShadowView).offset(-3);
        make.top.mas_equalTo(self.bottomShadowView);
        make.height.mas_equalTo(CCGetRealFromPt(34));
//        make.width.mas_equalTo(SCREEN_WIDTH - CCGetRealFromPt(460));
    }];
    [self.slider layoutIfNeeded];
    
    //单击手势
    UITapGestureRecognizer *TapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doTapChange:)];
    TapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:TapGesture];

    //隐藏导航
    [self stopPlayerTimer];
    
    CCProxy *weakObject = [CCProxy proxyWithWeakObject:self];
    self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:weakObject selector:@selector(LatencyHiding) userInfo:nil repeats:YES];
    
    //新加属性
    [self.backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.changeButton addTarget:self action:@selector(changeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.quanpingButton addTarget:self action:@selector(quanpingButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.speedButton addTarget:self action:@selector(playbackRateBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.centerButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    //添加文档小窗
    //小窗
//    CGRect rect = [UIScreen mainScreen].bounds;
//    CGRect smallVideoRect = CGRectMake(rect.size.width -CCGetRealFromPt(220), CCGetRealFromPt(462)+CCGetRealFromPt(82)+(IS_IPHONE_X? 44:20), CCGetRealFromPt(202), CCGetRealFromPt(152));
    _smallVideoView = [[CCDocView alloc] initWithType:_isSmallDocView];
    __weak typeof(self)weakSelf = self;
    _smallVideoView.hiddenSmallVideoBlock = ^{
        [weakSelf hiddenSmallVideoview];
    };
    
    //直播未开始
    self.liveEnd = [[UIImageView alloc] init];
    self.liveEnd.image = [UIImage imageNamed:@"live_streaming_unstart_bg"];
    [self addSubview:self.liveEnd];
    self.liveEnd.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625);
    self.liveEnd.hidden = YES;
    //直播未开始图片
    UIImageView * alarmClock = [[UIImageView alloc] init];
    alarmClock.image = [UIImage imageNamed:@"live_streaming_unstart"];
    [self.liveEnd addSubview:alarmClock];
    [alarmClock mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.liveEnd);
        make.height.width.mas_equalTo(CCGetRealFromPt(64));
        make.centerY.equalTo(self.liveEnd.mas_centerY).offset(-10);
    }];
    
    self.unStart = [[UILabel alloc] init];
    self.unStart.textColor = [UIColor whiteColor];
    self.unStart.alpha = 0.6f;
    self.unStart.textAlignment = NSTextAlignmentCenter;
    self.unStart.font = [UIFont systemFontOfSize:FontSize_30];
    self.unStart.text = PLAY_END;
    [self.liveEnd addSubview:self.unStart];
    self.unStart.frame = CGRectMake(SCREEN_WIDTH/2-50, CCGetRealFromPt(271), 100, 30);
    
    
}
#pragma mark - 点击分享按钮
- (void)shareButtonClick:(UIButton *)sender {
    
}
- (void)addSmallView {
    [APPDelegate.window addSubview:_smallVideoView];
}
#pragma mark - btn点击事件

/**
 点击切换倍速按钮
 */
-(void)playbackRateBtnClicked {
    NSString *title = self.speedButton.titleLabel.text;
    if([title isEqualToString:@"1.0x"]) {
        [self.speedButton setTitle:@"1.5x" forState:UIControlStateNormal];
        _playBackRate = 1.5;
//        self.changeRate(_playBackRate);
        self.requestDataPlayBack.ijkPlayer.playbackRate = _playBackRate;

    } else if([title isEqualToString:@"1.5x"]) {
        [self.speedButton setTitle:@"0.5x" forState:UIControlStateNormal];
        _playBackRate = 0.5;
//        self.changeRate(_playBackRate);
        self.requestDataPlayBack.ijkPlayer.playbackRate = _playBackRate;

    } else if([title isEqualToString:@"0.5x"]) {
        [self.speedButton setTitle:@"1.0x" forState:UIControlStateNormal];
        _playBackRate = 1.0;
//        self.changeRate(_playBackRate);
        self.requestDataPlayBack.ijkPlayer.playbackRate = _playBackRate;
    }
    
    [self stopTimer];
    CCProxy *weakObject = [CCProxy proxyWithWeakObject:self];
    _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / _playBackRate) target:weakObject selector:@selector(timerfunc) userInfo:nil repeats:YES];
}

/**
 点击暂停和继续
 */
- (void)pauseButtonClick {
    if (self.pauseButton.selected == NO) {
        self.pauseButton.selected = YES;
        self.centerButton.selected = YES;
//        self.pausePlayer(YES);

            [self stopTimer];
            [self.requestDataPlayBack pausePlayer];


    } else if (self.pauseButton.selected == YES){
        self.pauseButton.selected = NO;
        self.centerButton.selected = NO;
//        self.pausePlayer(NO);

        [self startTimer];
        [self.requestDataPlayBack startPlayer];
    }
}
//强制转屏
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

/**
 点击全屏按钮

 @param sender sender
 */
- (void)quanpingButtonClick:(UIButton *)sender {

    
    UIView *view = [self superview];
    if (!sender.selected) {
        sender.selected = YES;
        sender.tag = 2;
        self.backButton.tag = 2;
//        [self turnRight];

        self.changePlayBack(1);
#warning 需要处理全屏
        if (self.delegate) {
            [self.delegate quanpingPlayBackBtnClicked:_changeButton.tag];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSLog(@"%@ %@",self.marqueeView.fatherView,self.marqueeView1.fatherView);
                
                [self.marqueeView startMarquee];
                [self.marqueeView1 startMarquee];
            });
        }
//        self.quanpingAction(_changeButton.tag);
//        self.quanpingChangeAction(sender.tag);
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(view);
            make.height.mas_equalTo(SCREENH_HEIGHT);
        }];
        [self layoutIfNeeded];//
        [self layouUI:YES];
//        CGRect rect = view.frame;
        [self.smallVideoView setFrame:CGRectMake(0, CCGetRealFromPt(332), 150, 85)];
    } else {
        sender.selected = NO;
        [self backButtonClick:sender];
        sender.tag = 1;
//        self.quanpingChangeAction(sender.tag);

    }
}
//切换视频和文档
- (void)changeButtonClick:(UIButton *)sender {
    if (_smallVideoView.hidden) {
//        NSString *title = _changeButton.tag == 1 ? PLAY_CHANGEDOC : PLAY_CHANGEVIDEO;
//        [_changeButton setTitle:title forState:UIControlStateNormal];
        _smallVideoView.hidden = NO;
//        [_changeButton setTitle:@"" forState:UIControlStateNormal];
        [self.changeButton setBackgroundImage:[UIImage imageNamed:@"live_switchscreen"] forState:UIControlStateNormal];
        return;
    }
    if (sender.tag == 1) {//切换文档大屏
        sender.tag = 2;
//        [sender setTitle:PLAY_CHANGEVIDEO forState:UIControlStateNormal];
    } else {//切换文档小屏
        sender.tag = 1;
//        [sender setTitle:PLAY_CHANGEDOC forState:UIControlStateNormal];
    }
    if (sender.tag == 2) {
          [_requestDataPlayBack changeDocParent:self];
          [_requestDataPlayBack changePlayerParent:self.smallVideoView];
          [_requestDataPlayBack changeDocFrame:CGRectMake(0, 0,self.frame.size.width, self.frame.size.height)];
          [_requestDataPlayBack changePlayerFrame:CGRectMake(0, 0, self.smallVideoView.frame.size.width, self.smallVideoView.frame.size.height)];
      }else{
          [_requestDataPlayBack changeDocParent:self.smallVideoView];
          [_requestDataPlayBack changePlayerParent:self];
          [_requestDataPlayBack changePlayerFrame:CGRectMake(0, 0,self.frame.size.width, self.frame.size.height)];
          [_requestDataPlayBack changeDocFrame:CGRectMake(0, 0, self.smallVideoView.frame.size.width, self.smallVideoView.frame.size.height)];
      }
    
    [self bringSubviewToFront:self.topShadowView];
    [self bringSubviewToFront:self.bottomShadowView];
    [self.smallVideoView bringSubviewToFront:self.marqueeView];
    [self bringSubviewToFront:self.marqueeView1];
}
//结束直播和退出全屏
- (void)backButtonClick:(UIButton *)sender {
    UIView *view = [self superview];
    if (sender.tag == 2) {//横屏返回竖屏
        sender.tag = 1;
        [self endEditing:NO];
//        [self turnPortrait];
        self.changePlayBack(0);
        if (_changeButton.tag == 1) {
            [_requestDataPlayBack changePlayerFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625)];
        } else {
            [_requestDataPlayBack changeDocFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625)];
        }
        
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(view);
            make.height.mas_equalTo(SCREEN_WIDTH *0.5625);
            make.top.equalTo(view).offset(SCREEN_STATUS);
        }];
        [self layoutIfNeeded];//
//        CGRect rect = view.frame;
        [self.smallVideoView setFrame:CGRectMake(0, SCREEN_WIDTH *0.5625+(IS_IPHONE_X? 44:20), 150, 85)];
        [self layouUI:NO];
    }else if( sender.tag == 1){//结束直播
        [self creatAlertController_alert];
    }
}
//创建提示窗
-(void)creatAlertController_alert {
    //设置提示弹窗
    WS(weakSelf)
    CCAlertView *alertView = [[CCAlertView alloc] initWithAlertTitle:ALERT_EXITPLAYBACK sureAction:SURE cancelAction:CANCEL sureBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf exitPlayBack];
        });
    }];
    [APPDelegate.window addSubview:alertView];
}
//退出直播回放
-(void)exitPlayBack{
    [self.smallVideoView removeFromSuperview];
    [self stopTimer];
    [self stopPlayerTimer];
    WS(weakSelf)
//    NSLog(@"退出直播回放");
    if (self.exitCallBack) {
        [weakSelf.requestDataPlayBack requestCancel];
        weakSelf.requestDataPlayBack = nil;
        self.exitCallBack();//退出回放回调
    }
}
#pragma mark - 播放和根据时间添加数据
//播放和根据时间添加数据
- (void)timerfunc
{
     if([_requestDataPlayBack isPlaying]) {
            [self removeLoadingView];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //获取当前播放时间和视频总时长
            NSTimeInterval position = (int)round(self.requestDataPlayBack.currentPlaybackTime);
            NSTimeInterval duration = (int)round(self.requestDataPlayBack.playerDuration);
            
            //存在播放器最后一点不播放的情况，所以把进度条的数据对到和最后一秒想同就可以了
            if(duration - position == 1 && (self.sliderValue == position || self.sliderValue == duration)) {
                position = duration;
            }
    //                            NSLog(@"__test --%f",_requestDataPlayBack.currentPlaybackTime);
            
            //设置plaerView的滑块和右侧时间Label
            self.slider.maximumValue = (int)duration;
            self.rightTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(duration / 60), (int)(duration) % 60];
            
            //校对SDK当前播放时间
            if(position == 0 && self.sliderValue != 0) {
                self.requestDataPlayBack.currentPlaybackTime = self.sliderValue;
                //            position = self.playerView.sliderValue;
                self.slider.value = self.sliderValue;
                //        } else if(fabs(position - self.playerView.slider.value) > 10) {
                //            self.requestDataPlayBack.currentPlaybackTime = self.playerView.slider.value;
                ////            position = self.playerView.slider.value;
                //            self.playerView.sliderValue = self.playerView.slider.value;
            } else {
                self.slider.value = position;
                self.sliderValue = self.slider.value;
            }
            
            //校对本地显示速率和播放器播放速率
            if(self.requestDataPlayBack.ijkPlayer.playbackRate != self.playBackRate) {
                self.requestDataPlayBack.ijkPlayer.playbackRate = self.playBackRate;
                //#ifdef LockView
                           //校对锁屏播放器播放速率
                           [_lockView updatePlayBackRate:self.requestDataPlayBack.ijkPlayer.playbackRate];
                           //#endif
                [self startTimer];
            }
            if(self.pauseButton.selected == NO && self.requestDataPlayBack.ijkPlayer.playbackState == IJKMPMoviePlaybackStatePaused) {
                //开启播放视频
                [self.requestDataPlayBack startPlayer];
            }
            /* 获取当前时间段的文档数据  time：从直播开始到现在的秒数，SDK会在画板上绘画出来相应的图形 */
            [self.requestDataPlayBack continueFromTheTime:self.sliderValue];
            //更新左侧label
            self.leftTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(self.sliderValue / 60), (int)(self.sliderValue) % 60];
            //#ifdef LockView
            /*  校对锁屏播放器进度 */
            [_lockView updateCurrentDurtion:_requestDataPlayBack.currentPlaybackTime];
            //#endif
        });
}
//开始播放
-(void)startTimer {
    [self stopTimer];
    CCProxy *weakObject = [CCProxy proxyWithWeakObject:self];
    _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / _playBackRate) target:weakObject selector:@selector(timerfunc) userInfo:nil repeats:YES];
}
//停止播放
-(void) stopTimer {
    if([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

/**
 显示视频加载中样式
 */
-(void)showLoadingView{
    if (_loadingView) {
        return;
    }
    _loadingView = [[LoadingView alloc] initWithLabel:PLAY_LOADING centerY:YES];
    [self addSubview:_loadingView];
    [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsMake(50, 0, 0, 0));
    }];
    [_loadingView layoutIfNeeded];
}

/**
 移除视频加载中样式
 */
-(void)removeLoadingView{
    if(_loadingView) {
        [_loadingView removeFromSuperview];
        _loadingView = nil;
    }
}
#pragma mark - 切换横竖屏
/**
 切换横竖屏

 @param screenLandScape 横竖屏
 */
- (void)layouUI:(BOOL)screenLandScape {
    if (screenLandScape == YES) {//横屏
        self.quanpingButton.selected = YES;
        NSInteger barHeight = IS_IPHONE_X?180:128;
        [self.bottomShadowView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(IS_IPHONE_X ? 44:0);
            make.height.mas_equalTo(CCGetRealFromPt(barHeight));
            make.right.equalTo(self).offset(IS_IPHONE_X? (-44):0);
        }];
        [self.topShadowView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(IS_IPHONE_X ? 44:0);
            make.right.equalTo(self).offset(IS_IPHONE_X? (-44):0);
        }];
//        [self.backButton layoutIfNeeded];
//        [self.titleLabel layoutIfNeeded];
        [self.slider mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(SCREEN_WIDTH - CCGetRealFromPt(460)-(IS_IPHONE_X?88:0));
        }];
        [self.slider layoutIfNeeded];
        self.liveEnd.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREENH_HEIGHT);
        self.unStart.frame = CGRectMake(SCREEN_WIDTH/2-50, CCGetRealFromPt(400), 100, 30);
    } else {//竖屏
        self.quanpingButton.selected = NO;
        [self.bottomShadowView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(CCGetRealFromPt(60));
            make.left.equalTo(self);
            make.right.equalTo(self);
        }];
        [self.topShadowView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.right.equalTo(self);
        }];
//        [self.backButton layoutIfNeeded];
//        [self.titleLabel layoutIfNeeded];
        [self.slider mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(SCREEN_WIDTH - CCGetRealFromPt(460));
        }];
        [self.slider layoutIfNeeded];
        self.liveEnd.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH *0.5625);
        self.unStart.frame = CGRectMake(SCREEN_WIDTH/2-50, CCGetRealFromPt(271), 100, 30);
    }
}
//移除提示信息
-(void)removeInformationViewPop {
    [_informationViewPop removeFromSuperview];
    _informationViewPop = nil;
}
//移除定时器
-(void)stopPlayerTimer {
    if([self.playerTimer isValid]) {
        [self.playerTimer invalidate];
        self.playerTimer = nil;
    }
}

#pragma mark - 隐藏视频小窗
//隐藏小窗视图
-(void)hiddenSmallVideoview{
    _smallVideoView.hidden = YES;
//    NSString *title = self.changeButton.tag == 1 ? PLAY_SHOWDOC : PLAY_SHOWVIDEO;
//    [self.changeButton setTitle:@"双屏" forState:UIControlStateNormal];
    [self.changeButton setBackgroundImage:[UIImage imageNamed:@"live_openscreen.png"] forState:UIControlStateNormal];
}
#pragma mark - 横竖屏旋转
//转为横屏
-(void)turnRight{
    self.isScreenLandScape = YES;
    [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
    self.isScreenLandScape = NO;
    [UIApplication sharedApplication].statusBarHidden = YES;
}
//转为竖屏
-(void)turnPortrait{
    self.isScreenLandScape = YES;
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
    [UIApplication sharedApplication].statusBarHidden = NO;
    self.isScreenLandScape = NO;
}
@end
