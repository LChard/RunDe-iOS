//
//  CCPlayBack.h
//  CCLiveCloud
//
//  Created by Clark on 2019/10/23.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MySlider.h"
#import "LoadingView.h"//加载
#import "CCDocView.h"//文档视图
#import "CCSDK/RequestDataPlayBack.h"//sdk
#import "CCSDK/SaveLogUtil.h"//日志
#import <HDMarqueeTool/HDMarqueeTool.h>
//#ifdef LockView
#import "CCLockView.h"//锁屏
//#endif
NS_ASSUME_NONNULL_BEGIN
@protocol CCPlayBackDelegate <NSObject>
@optional

/**
 全屏按钮点击代理

 @param tag 1视频为主，2文档为主
 */
-(void)quanpingPlayBackBtnClicked:(NSInteger)tag;

/**
 返回按钮点击代理

 @param tag 1.视频为主，2.文档为主
 */
-(void)backBtnClicked:(NSInteger)tag;

/**
 切换视频/文档按钮点击回调

 @param tag changeBtn的tag值
 */
-(void)changeBtnClicked:(NSInteger)tag;

/**
 开始播放时调用此方法
 */
-(void)timerfunc;
@end
@interface CCPlayBack : UIView
@property (nonatomic, weak)id<CCPlayBackDelegate>       delegate;
@property (nonatomic,assign)BOOL                          isScreenLandScape;//是否横屏
@property (nonatomic,assign)float                         playBackRate;//播放速率
@property (nonatomic,strong)NSTimer                     * timer;//计时器
@property (nonatomic,strong)CCDocView                   * smallVideoView;//文档或者小图
@property (nonatomic, strong)UIButton                   * smallCloseBtn;//小窗关闭按钮
@property (nonatomic,strong)LoadingView                 * loadingView;//加载视图
@property (nonatomic, strong)UILabel                    * leftTimeLabel;//当前播放时长
@property (nonatomic, strong)UILabel                    * rightTimeLabel;//总时长
@property (nonatomic, strong)MySlider                   * slider;//滑动条
@property (nonatomic, strong)UIButton                   * backButton;//返回按钮
@property (nonatomic, strong)UIButton                   * changeButton;//切换视频文档按钮
@property (nonatomic, strong)UIButton                   * quanpingButton;//全屏按钮
@property (nonatomic, strong)UIButton                   * pauseButton;//暂停按钮
@property (nonatomic, strong)UIButton                   *centerButton;//屏幕中间暂停播放
@property (nonatomic, strong)UIButton                   * speedButton;//倍速按钮
@property (nonatomic, assign)NSInteger                  sliderValue;//滑动值
@property (nonatomic, strong)UIView                     * topShadowView;//上面的阴影
@property (nonatomic, strong)UIView                     * bottomShadowView;//下面的阴影
@property (nonatomic,strong)RequestDataPlayBack         * requestDataPlayBack;//sdk

@property (nonatomic, strong)UIImageView                * liveEnd;//播放结束视图

@property (nonatomic,copy) void(^exitCallBack)(void);//退出直播间回调
@property (nonatomic,copy) void(^sliderCallBack)(int);//滑块回调
@property (nonatomic,copy) void(^sliderMoving)(void);//滑块移动回调
@property (nonatomic,copy) void(^changeRate)(float rate);//改变播放器速率回调
@property (nonatomic,copy) void(^pausePlayer)(BOOL pause);//暂停播放器回调
@property (nonatomic,copy) void(^changePlayBack)(NSInteger btnTag);//横竖屏
@property(nonatomic,strong)HDMarqueeView * marqueeView;
@property(nonatomic,strong)HDMarqueeView * marqueeView1;
//#ifdef LockView
@property (nonatomic,strong)CCLockView                  * lockView;//锁屏视图



/**
 初始化方法

 @param frame frame
 @param isSmallDocView 是否是文档小窗
 @return self;
 */
- (instancetype)initWithFrame:(CGRect)frame docViewType:(BOOL)isSmallDocView;
/**
 开始播放
 */
-(void)startTimer;

/**
 停止播放
 */
-(void)stopTimer;

/**
 显示加载中视图
 */
-(void)showLoadingView;

/**
 移除加载中视图
 */
-(void)removeLoadingView;
#pragma mark - 屏幕旋转
//转为横屏
-(void)turnRight;
//转为竖屏
-(void)turnPortrait;
//添加小窗
- (void)addSmallView;
//移除回放
- (void)playBackRequestCancel;
@end

NS_ASSUME_NONNULL_END
