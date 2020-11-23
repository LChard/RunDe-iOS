//
//  CCPopBaseView.h
//  CCLiveCloud
//
//  Created by zwl on 2019/10/17.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCPopBaseView : UIView

@property(nonatomic,strong)UIView * bgView;
@property(nonatomic,assign)CGFloat topHeight;

-(void)setTitle:(NSString *)title;

-(void)show;

-(void)dismiss;

@end

NS_ASSUME_NONNULL_END
