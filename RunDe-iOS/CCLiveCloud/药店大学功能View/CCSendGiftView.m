//
//  CCSendGiftView.m
//  CCLiveCloud
//
//  Created by zwl on 2019/10/17.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCSendGiftView.h"

@interface CCSendGiftView ()

@property(nonatomic,assign)NSInteger currentNum;//当前数量选择

@end

@implementation CCSendGiftView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.currentNum = -1;
        
        [self setTitle:@"送礼物"];
        CGFloat buttonSize = (SCREEN_WIDTH / 4.0);
        CGFloat space = 8;
        CGFloat midBgViewHeight = buttonSize * 2 + space + 17;
        
        [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
            make.left.and.right.equalTo(@0);
            make.height.equalTo(@(self.topHeight + midBgViewHeight + 50 + TabbarSafeBottomMargin));
        }];
        

        UIView * midBgView = [CCControl initViewWithFrame:CGRectZero BackgroundColor:self.backgroundColor Tag:0 AndAlpha:1];
        [self.bgView addSubview:midBgView];
        [midBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(@0);
            make.top.equalTo(@(self.topHeight));
            make.height.equalTo(@(midBgViewHeight));
        }];
        
        NSArray * titles = @[@"666",@"玫瑰",@"彩笔",@"金麦",@"老师心",@"玫瑰",@"彩笔",@"金麦"];
        for (int i = 0; i < titles.count; i++) {
            CCSendGiftButton * button = [CCSendGiftButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(buttonSize * (i % 4), (buttonSize + space) * (i  / 4), buttonSize, buttonSize);
            button.titleLabel.font = [UIFont systemFontOfSize:14];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            [button setTitle:[titles objectAtIndex:i] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:1.0]] forState:UIControlStateNormal];
            //先随便搞个 站位
            [button setImage:[UIImage imageNamed:@"chat_ic_face_hov"] forState:UIControlStateNormal];
            button.tag = 100 + i;
            [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
            [midBgView addSubview:button];
        }
        
        UIView * lineView = [CCControl initViewWithFrame:CGRectZero BackgroundColor:[UIColor colorWithLight:[UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0] Dark:[UIColor colorWithRed:71/255.0 green:71/255.0 blue:71/255.0 alpha:1.0]] Tag:0 AndAlpha:1];
        [self.bgView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(@0);
            make.top.equalTo(midBgView.mas_bottom);
            make.height.equalTo(@1);
        }];
        
        NSArray * nums = @[@"x1",@"x5",@"x10"];
        for (int i = 0; i < nums.count; i++) {
            UIButton * button = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:[nums objectAtIndex:i] Image:nil Target:self Action:@selector(numButtonAction:) AndTag:200 + i];
            [button setTitleColor:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:1.0]] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithHexString:@"#FF454B" alpha:1] forState:UIControlStateSelected];
            button.titleLabel.font = [UIFont systemFontOfSize:16];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.layer.cornerRadius = 15;
            button.layer.borderWidth = 0.5;
            button.layer.borderColor = [UIColor colorWithHexString:@"#DDDDDD" alpha:1].CGColor;
            [self.bgView addSubview:button];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(@(15 + (60 + 10) * i));
                make.top.equalTo(lineView.mas_bottom).offset(9);
                make.width.equalTo(@60);
                make.height.equalTo(@30);
            }];
        }
        
        UIButton * sendButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:@"发送" Image:nil Target:self Action:@selector(sendButtonAction) AndTag:0];
        sendButton.titleLabel.font = [UIFont systemFontOfSize:16];
        sendButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [sendButton setBackgroundColor:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]];
        sendButton.layer.cornerRadius = 15;
        [self.bgView addSubview:sendButton];
        [sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lineView.mas_bottom).offset(9);
            make.right.equalTo(@(-15));
            make.width.equalTo(@90);
            make.height.equalTo(@30);
        }];

    }
    return self;
}

-(void)buttonAction:(CCSendGiftButton *)button
{
    // 100 + i
}

-(void)numButtonAction:(UIButton *)button
{
    // 200 + i
    if (button.selected) {
        return;
    }
    
    button.selected = !button.selected;
    button.layer.borderColor = [UIColor colorWithHexString:@"#FF454B" alpha:1].CGColor;
    
    if (self.currentNum != -1) {
        UIButton * preButton = (UIButton *)[self.bgView viewWithTag:200 + self.currentNum];
        preButton.selected = NO;
        preButton.layer.borderColor = [UIColor colorWithHexString:@"#DDDDDD" alpha:1].CGColor;
    }
    
    self.currentNum = button.tag - 200;
}

-(void)sendButtonAction
{
    //礼物数量
    NSNumber * giftNum = [NSNumber numberWithInt:arc4random()%10 + 1];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SENDGIFT object:giftNum];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@implementation CCSendGiftButton

-(CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return CGRectMake((self.frame.size.width - 75) / 2.0, (self.frame.size.height - 75) / 3.0, 75, 75);
}

-(CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0, 75 + (self.frame.size.height - 75) / 3.0 * 2, self.frame.size.width, 14);
}

@end
