//
//  CCLiveDirectory.m
//  CCLiveCloud
//
//  Created by Clark on 2019/10/16.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCLiveDirectory.h"

@implementation CCLiveDirectory

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI{
    self.changeButton = [[UIButton alloc] init];
//    [self.changeButton setTitle:@"切换" forState:UIControlStateNormal];
//    [self.changeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.changeButton setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:_changeButton];
    [self.changeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self);
        make.width.height.mas_equalTo(100);
    }];
    self.changeButton.tag = 1;
    //  btn点击事件
//    [self.quanpingButton addTarget:self action:@selector(quanpingBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
}

@end
