//
//  CCGiftRewardPopView.h
//  CCLiveCloud
//
//  Created by zwl on 2019/10/21.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CCGiftRewardPopViewStyle) {
    CCGiftRewardPopViewStyleGift,//礼物
    CCGiftRewardPopViewStyleReward//打赏
};

@interface CCGiftRewardPopView : UIView

@property(nonatomic,assign)CCGiftRewardPopViewStyle style;

@property(nonatomic,strong)UIImageView * imageView;
//等确定数据才能修改 ，临时测试
//@property(nonatomic,copy)NSString * name;
//@property(nonatomic,copy)NSString * content;
//@property(nonatomic,copy)NSString * num;

-(void)addAnimate:(NSDictionary *)animateDict;

-(void)insertAnimate:(NSDictionary *)animateDict;

-(void)stopAnimate;

@end

NS_ASSUME_NONNULL_END
