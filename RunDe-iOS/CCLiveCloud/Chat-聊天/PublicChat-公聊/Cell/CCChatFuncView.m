//
//  CCChatFuncView.m
//  CCLiveCloud
//
//  Created by zwl on 2019/10/10.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCChatFuncView.h"

@interface CCChatFuncView ()

@property(nonatomic,strong)UIButton * startButton;
@property(nonatomic,strong)CAEmitterLayer * emitterLayer;
@property(nonatomic,assign)NSInteger number;
@property(nonatomic,strong)NSTimer * timer;
@property(nonatomic,strong)UIView * btnGround;
@property(nonatomic,strong) UIButton * selectButton;
@end

@implementation CCChatFuncView

- (instancetype)init
{
    self = [super init];
    if (self) {
                
        [self setUpUI];
        
    }
    return self;
}

-(void)dealloc
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - action
-(void)selectButtonAction:(UIButton *)button
{
//    button.selected = !button.selected;
    self.selectButton.selected = !self.selectButton.selected;
    if (self.didSelect) {
        self.didSelect(self.selectButton.selected);
    }
}

- (void)likeButtonBeClicked:(UIButton *)sender {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.toValue = @1.5;
    animation.duration = 0.15;
    animation.autoreverses = YES;
    [sender.layer addAnimation:animation forKey:nil];
    [self multipleLikeAnimation];
}
- (void)multipleLikeAnimation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 5; i ++) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self likeAnimation];
            });
            int randomInt = random() % 5;
            [NSThread sleepForTimeInterval:randomInt/10.0];
        }
    });
}

- (void)likeAnimation {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"live_praise_gif_0%@",@(rand()%5)]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(5.0, 5.0, 20.0, 20.0);
    [imageView setContentMode:UIViewContentModeCenter];
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 20.0;
    [self.btnGround insertSubview:imageView atIndex:0];
    
    CGFloat finishX = round(random() % 130) - 130 + (CGRectGetWidth(self.bounds) - CGRectGetMinX(self.btnGround.frame));
    CGFloat speed = 1.0 / round(random() % 900) + 0.6;
    NSTimeInterval duration = 4.0 * speed;
    if (duration == INFINITY) {
        duration = 2.412346;
    }
    
    [UIView animateWithDuration:duration animations:^{
        imageView.alpha = 0.0;
        imageView.frame = CGRectMake(finishX, - 180, 40.0, 40.0);
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}


-(void)setUpUI
{
    self.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]];
    
    self.selectButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:nil Target:self Action:@selector(selectButtonAction:) AndTag:0];
    [self.selectButton setBackgroundImage:[UIImage imageNamed:@"radio.png"] forState:UIControlStateNormal];
    [self.selectButton setBackgroundImage:[UIImage imageNamed:@"radio_on.png"] forState:UIControlStateSelected];
    [self addSubview:self.selectButton];
    [self.selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@13);
        make.width.and.height.equalTo(@20);
        make.centerY.equalTo(self);
    }];
    
//    UILabel * label = [CCControl initLabelWithFrame:CGRectZero Title:@"只看老师" TextColor:[UIColor colorWithLight:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0] Dark:[UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:1.0]] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont systemFontOfSize:12]];
    UIButton * labelBen = [[UIButton alloc] init];
    [labelBen setBackgroundColor:UIColor.clearColor];
    [labelBen setTitle:@"只看老师" forState:UIControlStateNormal];
    [labelBen setTitleColor:[UIColor colorWithLight:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0] Dark:[UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:1.0]] forState:UIControlStateNormal];
//    [label sizeToFit];
    [self addSubview:labelBen];
    [labelBen mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectButton.mas_right).offset(5);
        make.centerY.equalTo(self.selectButton);
        make.width.mas_equalTo(80);
        make.top.bottom.equalTo(self.selectButton);
        
    }];
    [labelBen addTarget:self action:@selector(selectButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.btnGround = [[UIView alloc] initWithFrame:CGRectZero];
    self.btnGround.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]];
    [self addSubview:self.btnGround];
    [self.btnGround mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-16));
        make.width.and.height.equalTo(@35);
        make.centerY.equalTo(self);
    }];
    self.startButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:nil Target:self Action:@selector(likeButtonBeClicked:) AndTag:0];
    [self.startButton setBackgroundImage:[UIImage imageNamed:@"live_praise.png"] forState:UIControlStateNormal];
    [self.btnGround addSubview:self.startButton];
    [self.startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.btnGround);
    }];
    
    self.timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(getRandomTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void) getRandomTimer {
    int time = (arc4random() % 10);
    WS(weakSelf)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf likeButtonBeClicked:self.startButton];
    });
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
