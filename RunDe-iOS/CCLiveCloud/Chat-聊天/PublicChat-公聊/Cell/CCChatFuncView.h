//
//  CCChatFuncView.h
//  CCLiveCloud
//
//  Created by zwl on 2019/10/10.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CCChatFuncViewSelectButtonAction)(BOOL isSelect);

@interface CCChatFuncView : UIView

@property(nonatomic,copy)CCChatFuncViewSelectButtonAction didSelect;

@end

NS_ASSUME_NONNULL_END
