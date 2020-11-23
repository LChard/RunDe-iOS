//
//  CCDocView.h
//  CCLiveCloud
//
//  Created by 何龙 on 2019/3/21.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDocView : UIView
@property (nonatomic, strong) UIButton *smallCloseBtn;
@property (nonatomic, copy)void(^hiddenSmallVideoBlock)(void);
@property (nonatomic, copy)void(^changeDocView)(BOOL isScreenLandscape);
/// 拖动小窗事件终止回调 回调参数 小窗 frame
@property (nonatomic, copy)void(^CCDocViewGestureRecognizerStateEndedBlock)(CGRect rect);
/**
 初始化方法

 @param smallVideo 是否是文档小窗
 @return self
 */
-(instancetype)initWithType:(BOOL)smallVideo;

@property (nonatomic,assign)BOOL isZhuanTiKe;

@end

NS_ASSUME_NONNULL_END
