//
//  CCChatContentView.h
//  CCLiveCloud
//
//  Created by 何龙 on 2019/1/21.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomTextField.h"//输入框
#import "PPStickerTextView.h"//薪输入框
NS_ASSUME_NONNULL_BEGIN
typedef void(^CCSendMessageBlock)(void);//发送消息回调

@protocol CCChatContentViewDelegate <NSObject>

/**
 键盘将要出现回调

 @param height 键盘的行高
 @param endEditIng 是否停止编辑(当一些视图出现时，停止编辑,强制退出输入框)
 */
-(void)keyBoardWillShow:(CGFloat)height endEditIng:(BOOL)endEditIng;

/**
 关闭键盘
 */
-(void)hiddenKeyBoard;

-(void)contentViewFuncButtonAction:(BOOL)isSelect;//功能按钮

@end
@interface CCChatContentView : UIView

//@property (nonatomic, strong)CustomTextField       *chatTextField;//聊天文本框
@property (nonatomic, strong) PPStickerTextView *textView;//新聊天文本框
@property (nonatomic, strong, readonly) NSString *plainText;
@property (nonatomic, copy) CCSendMessageBlock     sendMessageBlock;//发送信息回调
@property (nonatomic, weak)id<CCChatContentViewDelegate> delegate;//代理
@end

NS_ASSUME_NONNULL_END
