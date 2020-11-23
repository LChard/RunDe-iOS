//
//  UIButton+UserInfo.m
//  CCLiveCloud
//
//  Created by MacBook Pro on 2018/12/20.
//  Copyright © 2018 MacBook Pro. All rights reserved.
//

#import "UIButton+UserInfo.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

static char key;
static char key1;


@implementation UIButton (UserInfo)

- (NSObject *)userid {
    return objc_getAssociatedObject(self, &key);
}

- (void)setUserid:(NSObject *)value {
    objc_setAssociatedObject(self, &key, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSObject *)correct {
    return objc_getAssociatedObject(self, &key1);
}
- (void)setCorrect:(NSString *)correct {
    objc_setAssociatedObject(self, &key1, correct, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
