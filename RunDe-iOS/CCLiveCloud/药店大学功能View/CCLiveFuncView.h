//
//  CC没啥用.h
//  CCLiveCloud
//
//  Created by zwl on 2019/10/15.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//打赏 评价 咨询 view

typedef void(^CCLiveFuncViewHiddenValueChange)(BOOL isHidden);

@interface CCLiveFuncView : UIView

@property(nonatomic,copy)CCLiveFuncViewHiddenValueChange hiddenValueChange;
@property(nonatomic,assign)BOOL isAllowChat;

@end

@interface CCLiveFuncButton : UIButton

@end

NS_ASSUME_NONNULL_END
