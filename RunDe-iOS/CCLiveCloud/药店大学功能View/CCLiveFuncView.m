//
//  CC没啥用.m
//  CCLiveCloud
//
//  Created by zwl on 2019/10/15.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCLiveFuncView.h"
#import "CCRewardTeacherView.h"
#import "CCCommitView.h"

@implementation CCLiveFuncView

- (instancetype)init
{
    self = [super init];
    if (self) {
        //96 + bottom
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, 97 + TabbarSafeBottomMargin);
        self.backgroundColor = [UIColor colorWithLight:[UIColor colorWithRed:245/255.0 green:241/255.0 blue:246/255.0 alpha:1.0] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
        self.isAllowChat = YES;
        NSArray * title = @[@"打赏",@"评价",@"咨询"];
        NSArray * images = @[@"tool_bar_reward.png",@"tool_bar_evaluation.png",@"tool_bar_advisory.png"];
        for (int i = 0; i < title.count; i++) {
            CCLiveFuncButton * button = [CCLiveFuncButton buttonWithType:UIButtonTypeCustom];
            [button setTitle:[title objectAtIndex:i] forState:UIControlStateNormal];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.titleLabel.font = [UIFont systemFontOfSize:14];
            [button setTitleColor:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:1.0]] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:[images objectAtIndex:i]] forState:UIControlStateNormal];
            button.tag = 100 + i;
            [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(@(22 + (94 * i)));
                make.top.equalTo(@15);
                make.width.and.height.equalTo(@50);
            }];
        }

    }
    return self;
}



-(void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    if (self.hiddenValueChange) {
        self.hiddenValueChange(hidden);
    }
}

-(void)buttonAction:(UIButton *)button
{
    //100 + i
    if (button.tag == 100) {
        if (self.isAllowChat == YES) {
            //打赏
            CCRewardTeacherView * rewardTeacherView = [[CCRewardTeacherView alloc]init];
            [rewardTeacherView show];
        } else {
             [[NSNotificationCenter defaultCenter] postNotificationName:@"showBanChat" object:nil userInfo:nil];
        }
    }
    if (button.tag == 101) {
        //评价
        CCCommitView * commitView = [[CCCommitView alloc]init];
        [commitView show];
    }
    if (button.tag == 102) {
        
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@implementation CCLiveFuncButton

-(CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
}

-(CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(0, self.frame.size.width + 6, self.frame.size.width, 14);
}

@end
