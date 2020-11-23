//
//  CCGiftRewardPopView.m
//  CCLiveCloud
//
//  Created by zwl on 2019/10/21.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCGiftRewardPopView.h"

@interface CCGiftRewardPopView ()

@property(nonatomic,strong)UIImageView * bgImageView;
@property(nonatomic,strong)UILabel * nameLabel;
@property(nonatomic,strong)UILabel * contentLabel;
@property(nonatomic,strong)UILabel * numLabel;

@property(nonatomic,strong)NSMutableArray * array;

@property(nonatomic,strong)NSMutableAttributedString * attr;
@property(nonatomic,strong)NSTimer * timer;
@property(nonatomic,assign)CGFloat animateTime;
@property(nonatomic,assign)CGFloat timeSpace;
@property(nonatomic,assign)NSInteger currentNum;
@property(nonatomic,assign)NSInteger maxNum;
@property(nonatomic,assign)BOOL textAnimateFinish;//文字动画是否执行完成
@property(nonatomic,assign)BOOL frameAnimateFinish;//位置动画是否执行完成

@end

@implementation CCGiftRewardPopView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.hidden = YES;
        CGFloat width = 260;
        CGFloat height = 50;
        self.frame = CGRectMake(0, 0, width, height);
        self.style = CCGiftRewardPopViewStyleGift;
         
        self.bgImageView = [CCControl initImageViewWithFrame:CGRectZero AndImage:@"live_send_bg.png"];
        [self addSubview:self.bgImageView];
        [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        self.nameLabel = [CCControl initLabelWithFrame:CGRectZero Title:nil TextColor:[UIColor whiteColor] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont systemFontOfSize:16]];
        [self addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@20);
            make.bottom.equalTo(self.mas_centerY).offset(-3);
            make.width.equalTo(@100);
            make.height.equalTo(@16);
        }];
        
        self.contentLabel = [CCControl initLabelWithFrame:CGRectZero Title:nil TextColor:[UIColor whiteColor] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont systemFontOfSize:13]];
        [self addSubview:self.contentLabel];
        [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.nameLabel);
            make.top.equalTo(self.mas_centerY).offset(3);
//            make.width.equalTo(self.nameLabel);
            make.height.equalTo(@13);
        }];
            
        self.imageView = [CCControl initImageViewWithFrame:CGRectZero AndImage:@""];
        [self addSubview:self.imageView];
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.nameLabel.mas_right).offset(18);
            make.width.and.height.equalTo(@30);
//            make.top.equalTo(@0);
            make.centerY.equalTo(self);
        }];
        
        self.numLabel = [CCControl initLabelWithFrame:CGRectZero Title:nil TextColor:[UIColor whiteColor] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont fontWithName:@"Arial" size:20]];
        [self addSubview:self.numLabel];
        [self.numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.imageView.mas_right).offset(10);
            make.right.equalTo(@(-5));
            make.height.equalTo(@28);
            make.centerY.equalTo(self).offset(1.5);
        }];
        
    }
    return self;
}

-(void)beginAnimate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!self.hidden) {
            return;
        }
        
  
        [self changeUI];
        
        self.hidden = NO;
        [UIView animateWithDuration:2 animations:^{
            //        self.hidden = NO;
            self.frame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        } completion:^(BOOL finished) {
    
            self.frameAnimateFinish = YES;
            [self stopCurrentAnimate];
        }];
    });
}

//结束当前动画
-(void)stopCurrentAnimate
{
    if (self.style == CCGiftRewardPopViewStyleGift) {
        
        if (!self.textAnimateFinish) {
            return;
        }
        
        if (!self.frameAnimateFinish) {
            return;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.frame = CGRectMake(-self.frame.size.width, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        if (self.array.count >0) {
            [self.array removeObjectAtIndex:0];
        }
        self.hidden = YES;
        if (self.array.count != 0) {
            [self beginAnimate];
        }
    });
}

-(void)stopAnimate
{
    [self.layer removeAllAnimations];
    self.hidden = YES;
    
    @synchronized (self) {
        [self.array removeAllObjects];
    }
}

-(void)beginGiftTimer
{
    if (self.timer) {
        return;
    }
    
    if (self.animateTime == 0) {
        //不需要动画
        return;
    }
    
    self.timer = [NSTimer timerWithTimeInterval:self.timeSpace target:self selector:@selector(giftTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

-(void)giftTimerAction
{
    self.currentNum++;
    
    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"x%ld",(long)self.currentNum] attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Arial" size: 28],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0], NSStrokeWidthAttributeName:@-1.5,NSStrokeColorAttributeName: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]}];
    self.numLabel.attributedText = attr;
    
//    [self.attr replaceCharactersInRange:NSMakeRange(0, self.attr.length) withString:[NSString stringWithFormat:@"%ld",self.currentNum]];
    
    if (self.currentNum == self.maxNum) {
        [self.timer invalidate];
        self.timer = nil;
        self.textAnimateFinish = YES;
        
        [self stopCurrentAnimate];
    }
}

-(void)changeUI
{
    /*
     @{@"name":dic[@"username"],
     @"content":array1[0],
     @"num":array[1]};
     */
    NSDictionary * firstAnimateDict = [self.array firstObject];

    self.nameLabel.text = [firstAnimateDict objectForKey:@"name"];
    self.contentLabel.text = [firstAnimateDict objectForKey:@"content"];
    
    if (self.style == CCGiftRewardPopViewStyleGift) {
        NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:@"0" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Arial" size: 28],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0], NSStrokeWidthAttributeName:@-1.5,NSStrokeColorAttributeName: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]}];
        self.attr = attr;
        
        //计算动画间隔
        self.currentNum = 0;
        
        self.maxNum = [[[firstAnimateDict objectForKey:@"num"] substringWithRange:NSMakeRange(1, [[firstAnimateDict objectForKey:@"num"] length] - 1)] integerValue];
        if (self.maxNum >= 1 && self.maxNum <= 5) {
            self.animateTime = 1;
        }else if (self.maxNum > 5 && self.maxNum <= 10){
            self.animateTime = 1.5;
        }else{
            self.animateTime = 1.5;
        }
        self.timeSpace = self.animateTime / (CGFloat)self.maxNum;
        
        self.textAnimateFinish = NO;
        self.frameAnimateFinish = NO;
        
        //开始动画
        NSLog(@"timeSpace:%f currentNum:%ld maxNum:%ld",self.timeSpace,(long)self.currentNum,(long)self.maxNum);
        [self beginGiftTimer];
        
    }else{
        NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:[firstAnimateDict objectForKey:@"num"] attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Arial" size: 28],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0], NSStrokeWidthAttributeName:@-1.5,NSStrokeColorAttributeName: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]}];
        self.attr = attr;
        
//        self.textAnimateFinish = YES;
        self.frameAnimateFinish = NO;
    }
    self.numLabel.attributedText = self.attr;

    
//    self.nameLabel.text = self.name;
//    self.contentLabel.text = self.content;
//    NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] initWithString:self.num attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Arial" size: 20],NSForegroundColorAttributeName: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0], NSStrokeWidthAttributeName:@-1.5,NSStrokeColorAttributeName: [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0]}];
//    self.numLabel.attributedText = attr;
}

-(void)addAnimate:(NSDictionary *)animateDict
{
    [self.array addObject:animateDict];
    
    [self beginAnimate];
}

-(void)insertAnimate:(NSDictionary *)animateDict
{
    if (self.style == CCGiftRewardPopViewStyleGift) {
        if (!self.textAnimateFinish || !self.frameAnimateFinish) {
            //动画未完成
            if (self.array.count >= 1) {
                [self.array insertObject:animateDict atIndex:1];
            }else{
                [self.array addObject:animateDict];
            }
            
        }else{
            //动画已完成
            [self.array addObject:animateDict];
        }
    }else{
        if (!self.frameAnimateFinish) {
            if (self.array.count >= 1) {
                [self.array insertObject:animateDict atIndex:1];
            }else{
                [self.array addObject:animateDict];
            }
        }else{
            [self.array addObject:animateDict];
        }
    }
    [self beginAnimate];
}

-(NSMutableArray *)array
{
    if (!_array) {
        _array = [[NSMutableArray alloc]init];
    }
    return _array;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
