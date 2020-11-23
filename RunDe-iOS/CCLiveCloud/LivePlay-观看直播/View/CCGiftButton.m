//
//  CCGiftButton.m
//  CCLiveCloud
//
//  Created by zwl on 2019/10/9.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCGiftButton.h"

@implementation CCGiftButton

-(CGRect)imageRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(6, 5, 20, 20);
}

-(CGRect)titleRectForContentRect:(CGRect)contentRect
{
    return CGRectMake(26, 0, self.frame.size.width - 26, self.frame.size.height);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
