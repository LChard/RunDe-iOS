//
//  CCPopBaseView.m
//  CCLiveCloud
//
//  Created by zwl on 2019/10/17.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCPopBaseView.h"

@interface CCPopBaseView ()

@property(nonatomic,strong)UIView * maskView;

@property(nonatomic,strong)UILabel * titleLabel;

@end

@implementation CCPopBaseView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.topHeight = 31;
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        self.hidden = YES;
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.top.equalTo(@0);
            make.width.equalTo(@(SCREEN_WIDTH));
            make.height.equalTo(@(SCREENH_HEIGHT));
        }];
        
        self.maskView = [CCControl initViewWithFrame:CGRectZero BackgroundColor:[UIColor clearColor] Tag:0 AndAlpha:1];
        [self addSubview:self.maskView];
        [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        self.bgView = [CCControl initViewWithFrame:CGRectZero BackgroundColor:[UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor blackColor]] Tag:0 AndAlpha:1];
        [self addSubview:self.bgView];
        
        self.titleLabel = [CCControl initLabelWithFrame:CGRectZero Title:nil TextColor:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0]] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont systemFontOfSize:16]];
        [self.bgView addSubview:self.titleLabel];
        
        UIButton * cancelButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:@"cancel.png" Target:self Action:@selector(cancelButtonAction) AndTag:0];
        [self.bgView addSubview:cancelButton];
        [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@(-10));
            make.width.and.height.equalTo(@28);
            make.centerY.equalTo(self.titleLabel);
        }];
        
    }
    return self;
}

-(void)cancelButtonAction
{
    [self dismiss];
}

-(void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@15);
        make.top.equalTo(@12);
        make.width.equalTo(@(self.titleLabel.frame.size.width));
        make.height.equalTo(@16);
    }];
    
    UIView * redView = [CCControl initViewWithFrame:CGRectZero BackgroundColor:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0] Tag:0 AndAlpha:1];
    [self.bgView addSubview:redView];
    [redView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(self.topHeight));
        make.width.equalTo(@25);
        make.height.equalTo(@3);
        make.centerX.equalTo(self.titleLabel);
    }];
}

-(void)show
{
    self.hidden = NO;
}

-(void)dismiss
{
    self.hidden = YES;
    
    [self removeFromSuperview];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
