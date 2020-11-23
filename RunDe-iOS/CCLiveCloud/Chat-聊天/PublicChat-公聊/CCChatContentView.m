//
//  CCChatContentView.m
//  CCLiveCloud
//
//  Created by 何龙 on 2019/1/21.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCChatContentView.h"
#import "PPUtil.h"
#import "PPStickerKeyboard.h"
#import "PPStickerDataManager.h"

#import "InformationShowView.h"//提示信息视图
@interface CCChatContentView ()<UITextFieldDelegate,UITextViewDelegate,PPStickerKeyboardDelegate>
@property(nonatomic,strong)InformationShowView          *informationView;//提示视图
@property(nonatomic,assign)CGRect                       keyboardRect;//键盘尺寸
@property(nonatomic,assign)BOOL                         keyboardHidden;//是否隐藏键盘
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic,copy)NSAttributedString *attributedText;
@property(nonatomic) NSRange selectedRange;
@property (nonatomic,assign) BOOL isAllowChat;
//默认样式
@property(nonatomic,strong)UIButton * courseButton;
@property(nonatomic,strong)UIButton * giftButton;
@property(nonatomic,strong)UIButton * funcButton;

//键盘出现样式
@property(nonatomic,strong)UIButton * emojiButton;
@property(nonatomic,strong)UIButton * button1;
@property(nonatomic,strong)UIButton * button2;


//键盘出现样式
@property(nonatomic,strong)UIButton * rightView;//右侧按钮
@property(nonatomic,strong)UIView * emojiView;//表情键盘
@property (nonatomic, strong) UIButton *sendBtn;

//新聊天
@property (nonatomic, strong) PPStickerKeyboard *stickerKeyboard;

@end

@implementation CCChatContentView
-(instancetype)init{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
        self.isAllowChat = YES;
        [self addSubview:self.courseButton];
        [self.courseButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.width.and.height.equalTo(@35);
            make.top.equalTo(@7);
        }];
        
        [self addSubview:self.textView];
        [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.and.height.equalTo(self.courseButton);
            make.left.equalTo(self.courseButton.mas_right).offset(5);
            make.right.equalTo(@(-(15 + 35 * 2 +10)));
        }];

        [self addSubview:self.giftButton];
        [self.giftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textView.mas_right).offset(5);
            make.width.and.height.equalTo(self.courseButton);
            make.centerY.equalTo(self.courseButton);
        }];

        [self addSubview:self.funcButton];
        [self.funcButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.giftButton.mas_right).offset(10);
            make.width.and.height.equalTo(self.courseButton);
            make.centerY.equalTo(self.courseButton);
        }];

        [self addSubview:self.emojiButton];
        self.emojiButton.hidden = YES;
        [self.emojiButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.courseButton);
        }];

        [self addSubview:self.button1];
        self.button1.hidden = YES;
        [self.button1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.giftButton);
        }];

        [self addSubview:self.button2];
        self.button2.hidden = YES;
        [self.button2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.funcButton);
        }];
        
        //添加通知
        [self addObserver];
    }
    return self;
}

-(void)changeUIWithStyle:(NSInteger)style
{
    self.funcButton.selected = NO;
    if (style == 1) {
        self.courseButton.hidden = NO;
        self.giftButton.hidden = NO;
        self.funcButton.hidden = NO;
        self.emojiButton.hidden = YES;
        self.emojiButton.selected = NO;
        self.button1.hidden = YES;
        self.button2.hidden = YES;
    }else{
        self.courseButton.hidden = YES;
        self.giftButton.hidden = YES;
        self.funcButton.hidden = YES;
        self.emojiButton.hidden = NO;
        self.button1.hidden = NO;
        self.button2.hidden = NO;
    }
}

#pragma mark - action
-(void)courseButtonAction
{
    //课程
}

-(void)giftButtonAction
{
    //礼物
    if (self.isAllowChat == YES) {
        
    } else {//禁言了
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showBanChat" object:nil userInfo:nil];
    }
     
}

-(void)funcButtonAction
{
    //+功能
    self.funcButton.selected = !self.funcButton.selected;
    
    if (self.delegate) {
        [self.delegate contentViewFuncButtonAction:self.funcButton.selected];
    }
}

-(void)emojiButtonAction
{

    self.emojiButton.selected = !self.emojiButton.selected;
    
    if (self.emojiButton.selected) {
        //出表情键盘

        self.textView.inputView = self.stickerKeyboard;         // 切换到自定义的表情键盘
        [self.textView reloadInputViews];
    }else{
        //收表情键盘
        self.textView.inputView = nil;                          // 切换到系统键盘
        [self.textView reloadInputViews];
    }

//    [self.chatTextField becomeFirstResponder];
//    [self.chatTextField reloadInputViews];
}

-(void)buttonOneAction
{
    //扣1
    [[NSNotificationCenter defaultCenter] postNotificationName:SENDCALLONE object:nil];
    _textView.text = nil;
    [_textView resignFirstResponder];
}

-(void)buttonTwoAction
{
    //扣2
    [[NSNotificationCenter defaultCenter] postNotificationName:SENDCALLTWO object:nil];
    _textView.text = nil;
    [_textView resignFirstResponder];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _textView.text = nil;
    [_textView resignFirstResponder];
}
#pragma mark - 懒加载
//聊天输入框

- (PPStickerTextView *)textView
{
    if (!_textView) {
        _textView = [[PPStickerTextView alloc] init];//WithFrame:CGRectMake(0, 80, 300, 60)];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:18.0f];
        _textView.scrollsToTop = NO;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.placeholder = @"在这里和老师互动哦";
        _textView.placeholderColor = [UIColor colorWithHexString:@"999999" alpha:0.8f];
        _textView.textContainerInset = UIEdgeInsetsMake(7, 0, 0, 0);
        _textView.layer.cornerRadius = 35 / 2.0;
        _textView.layer.masksToBounds = YES;
        _textView.layer.borderWidth = 0.5;
        _textView.layer.borderColor = [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1].CGColor;
        if (@available(iOS 11.0, *)) {
            _textView.textDragInteraction.enabled = NO;
        }
    }
    return _textView;
}
//
//#pragma mark - UITextView
//
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (self.plainText.length>300) {
        [_informationView removeFromSuperview];
           _informationView = [[InformationShowView alloc] initWithLabel:ALERT_INPUTLIMITATION];
           [APPDelegate.window addSubview:_informationView];
           [_informationView mas_makeConstraints:^(MASConstraintMaker *make) {
               make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 200, 0));
           }];

           [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(informationViewRemove) userInfo:nil repeats:NO];
        return NO;
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    if ([@"\n" isEqualToString:text]) {
        [self sendAction];
        _textView.text = nil;
        [_textView resignFirstResponder];
        
        return NO;
    }

    return YES;
}

- (NSString *)plainText
{
    return [self.textView.attributedText pp_plainTextForRange:NSMakeRange(0, self.textView.attributedText.length)];
}
- (void)refreshTextUI
{
    if (!self.textView.text.length) {
        return;
    }


    UITextRange *markedTextRange = [self.textView markedTextRange];
    UITextPosition *position = [self.textView positionFromPosition:markedTextRange.start offset:0];
    if (position) {
        return;     // 正处于输入拼音还未点确定的中间状态
    }

    NSRange selectedRange = self.textView.selectedRange;

    NSMutableAttributedString *attributedComment = [[NSMutableAttributedString alloc] initWithString:self.plainText attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16.0], NSForegroundColorAttributeName: [UIColor colorWithLight:[UIColor colorWithHexString:@"#333333" alpha:1.0f] Dark:[UIColor colorWithHexString:@"F2F2F7" alpha:1.0f]] }];

    // 匹配表情
    [PPStickerDataManager.sharedInstance replaceEmojiForAttributedString:attributedComment font:[UIFont systemFontOfSize:16.0]];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 5.0;
    [attributedComment addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:attributedComment.pp_rangeOfAll];

    NSUInteger offset = self.textView.attributedText.length - attributedComment.length;
    self.textView.attributedText = attributedComment;
    self.textView.selectedRange = NSMakeRange(selectedRange.location - offset, 0);
    self.attributedText = attributedComment;
    self.selectedRange = NSMakeRange(selectedRange.location - offset, 0);
}
- (void)textViewDidChange:(UITextView *)textView
{
    if (self.plainText.length>300) {
        [_informationView removeFromSuperview];
           _informationView = [[InformationShowView alloc] initWithLabel:ALERT_INPUTLIMITATION];
           [APPDelegate.window addSubview:_informationView];
           [_informationView mas_makeConstraints:^(MASConstraintMaker *make) {
               make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 200, 0));
           }];
           [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(informationViewRemove) userInfo:nil repeats:NO];
        self.textView.attributedText = self.attributedText;
        self.textView.selectedRange = self.selectedRange;
        return;
    }
    [self refreshTextUI];

}
//
//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
//{
//    if ([self.textView isFirstResponder]) {
//        return YES;
//    }
//    return NO;
//}
//
//
//- (BOOL)isFirstResponder
//{
//    return [self.textView isFirstResponder];
//}
//
//- (BOOL)resignFirstResponder
//{
//    [super resignFirstResponder];
//
//    return [self.textView resignFirstResponder];
//}
- (PPStickerKeyboard *)stickerKeyboard
{
    if (!_stickerKeyboard) {
        _stickerKeyboard = [[PPStickerKeyboard alloc] init];
        _stickerKeyboard.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), [self.stickerKeyboard heightThatFits]);
        _stickerKeyboard.delegate = self;
    }
    return _stickerKeyboard;
}
#pragma mark - PPStickerKeyboardDelegate

- (void)stickerKeyboard:(PPStickerKeyboard *)stickerKeyboard didClickEmoji:(PPEmoji *)emoji
{
    if (!emoji) {
        return;
    }

    UIImage *emojiImage = [UIImage imageNamed:[@"Emotion.bundle" stringByAppendingPathComponent:emoji.imageName]];
    if (!emojiImage) {
        return;
    }

    NSRange selectedRange = self.textView.selectedRange;
    NSString *emojiString = [NSString stringWithFormat:@"[%@]", emoji.imageTag];
    NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithString:emojiString];
    [emojiAttributedString pp_setTextBackedString:[PPTextBackedString stringWithString:emojiString] range:emojiAttributedString.pp_rangeOfAll];

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    [attributedText replaceCharactersInRange:selectedRange withAttributedString:emojiAttributedString];
    self.textView.attributedText = attributedText;
    self.textView.selectedRange = NSMakeRange(selectedRange.location + emojiAttributedString.length, 0);

    [self textViewDidChange:self.textView];
}

- (void)stickerKeyboardDidClickDeleteButton:(PPStickerKeyboard *)stickerKeyboard
{
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location == 0 && selectedRange.length == 0) {
        return;
    }

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    if (selectedRange.length > 0) {
        [attributedText deleteCharactersInRange:selectedRange];
        self.textView.attributedText = attributedText;
        self.textView.selectedRange = NSMakeRange(selectedRange.location, 0);
    } else {
        NSUInteger deleteCharactersCount = 1;

        // 下面这段正则匹配是用来匹配文本中的所有系统自带的 emoji 表情，以确认删除按钮将要删除的是否是 emoji。这个正则匹配可以匹配绝大部分的 emoji，得到该 emoji 的正确的 length 值；不过会将某些 combined emoji（如 👨‍👩‍👧‍👦 👨‍👩‍👧‍👦 👨‍👨‍👧‍👧），这种几个 emoji 拼在一起的 combined emoji 则会被匹配成几个个体，删除时会把 combine emoji 拆成个体。瑕不掩瑜，大部分情况下表现正确，至少也不会出现删除 emoji 时崩溃的问题了。
        NSString *emojiPattern1 = @"[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900-\\U0001F9FF]";
        NSString *emojiPattern2 = @"[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900–\\U0001F9FF]\\uFE0F";
        NSString *emojiPattern3 = @"[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900–\\U0001F9FF][\\U0001F3FB-\\U0001F3FF]";
        NSString *emojiPattern4 = @"[\\rU0001F1E6-\\U0001F1FF][\\U0001F1E6-\\U0001F1FF]";
        NSString *pattern = [[NSString alloc] initWithFormat:@"%@|%@|%@|%@", emojiPattern4, emojiPattern3, emojiPattern2, emojiPattern1];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:NULL];
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:attributedText.string options:kNilOptions range:NSMakeRange(0, attributedText.string.length)];
        for (NSTextCheckingResult *match in matches) {
            if (match.range.location + match.range.length == selectedRange.location) {
                deleteCharactersCount = match.range.length;
                break;
            }
        }

        [attributedText deleteCharactersInRange:NSMakeRange(selectedRange.location - deleteCharactersCount, deleteCharactersCount)];
        self.textView.attributedText = attributedText;
        self.textView.selectedRange = NSMakeRange(selectedRange.location - deleteCharactersCount, 0);
    }

    [self textViewDidChange:self.textView];
}

- (void)stickerKeyboardDidClickSendButton:(PPStickerKeyboard *)stickerKeyboard
{
    NSLog(@"333%@",self.textView.attributedText.string);
//发送按钮
    [self sendAction];
    _textView.text = nil;
    [_textView resignFirstResponder];
}

















//-(CustomTextField *)chatTextField{
//    if (!_chatTextField) {
//        _chatTextField = [[CustomTextField alloc] init];
//        _chatTextField.delegate = self;
//        [_chatTextField addTarget:self action:@selector(chatTextFieldChange) forControlEvents:UIControlEventEditingChanged];
////        _chatTextField.rightView = self.rightView;
//    }
//    return _chatTextField;
//}

//聊天输入中
//-(void)chatTextFieldChange
//{
//    if(_chatTextField.text.length > 300) {
//        //        [self endEditing:YES];
//        _chatTextField.text = [_chatTextField.text substringToIndex:300];
//        [_informationView removeFromSuperview];
//        _informationView = [[InformationShowView alloc] initWithLabel:ALERT_INPUTLIMITATION];
//        [APPDelegate.window addSubview:_informationView];
//        [_informationView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 200, 0));
//        }];
//
//        [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(informationViewRemove) userInfo:nil repeats:NO];
//    }
//}
//右侧表情键盘按钮
//-(UIButton *)rightView {
//    if(!_rightView) {
//        _rightView = [UIButton buttonWithType:UIButtonTypeCustom];
//        _rightView.frame = CGRectMake(0, 0, 42, 42);
//        _rightView.imageView.contentMode = UIViewContentModeScaleAspectFit;
//        _rightView.backgroundColor = CCClearColor;
//        [_rightView setImage:[UIImage imageNamed:@"face_nov"] forState:UIControlStateNormal];
//        [_rightView setImage:[UIImage imageNamed:@"face_hov"] forState:UIControlStateSelected];
//        [_rightView addTarget:self action:@selector(faceBoardClick) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _rightView;
//}
////点击表情键盘
//- (void)faceBoardClick {
//    BOOL selected = !_rightView.selected;
//    _rightView.selected = selected;
//
//    if(selected) {
//        [_chatTextField setInputView:self.emojiView];
//    } else {
//        [_chatTextField setInputView:nil];
//    }
//
//    [_chatTextField becomeFirstResponder];
//    [_chatTextField reloadInputViews];
//}
//-(void)loadFacialView:(int)page size:(CGSize)size {
//    int maxRow = 4;
//    int maxCol = 8;
//    CGFloat itemWidth = self.scrollView.bounds.size.width / maxCol;
//    CGFloat itemHeight = self.scrollView.bounds.size.height / maxRow;
//    // 添加表情
//    for (int index = 0, row = 0; index < 100; row++) {
//        int page = row / maxRow;
//        CGFloat addtionWidth = page * CGRectGetWidth(self.scrollView.bounds);
//        int decreaseRow = page * maxRow;
//        for (int col = 0; col < maxCol; col++, index ++) {
//            if (index < 100) {
//                 UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//                   [self.scrollView addSubview:button];
//                   [button setBackgroundColor:[UIColor clearColor]];
//                   [button setFrame:CGRectMake(col * itemWidth + addtionWidth, (row-decreaseRow) * itemHeight, itemWidth, itemHeight)];
//                   button.showsTouchWhenHighlighted = YES;
//                   button.tag = index;
//                   [button addTarget:self action:@selector(faceButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//                   [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%03d", index+201]]
//                                           forState:UIControlStateNormal];
//
//                   [button setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
//            } else {
//                break;
//            }
//        }
//    }
//    UIButton *delBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    delBtn.layer.cornerRadius = 5.0;
//    delBtn.backgroundColor = [UIColor colorWithRed:234.0 / 255.0 green:234.0/ 255.0 blue:234.0/ 255.0 alpha:1.0];
////    delBtn.frame = CGRectMake(self.scrollView.frame.origin.x + self.scrollView.frame.size.width, 0, itemWidth - 5.0, itemHeight - 5.0);
//    [delBtn setImage:[UIImage imageNamed:@"chat_btn_facedel"] forState:UIControlStateNormal];
//    [delBtn addTarget:self action:@selector(backFace)forControlEvents:UIControlEventTouchUpInside];
//    [_emojiView addSubview:delBtn];
//    [delBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(_emojiView);
//        make.right.mas_equalTo(_emojiView).offset(-65);
//        make.size.mas_equalTo(CGSizeMake(65, 49.5));
//    }];
//    self.sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
////    self.sendBtn.layer.cornerRadius = 5.0;
//    self.sendBtn.enabled = NO;
//    self.sendBtn.backgroundColor = [UIColor colorWithLight:[UIColor lightGrayColor] Dark:[UIColor darkGrayColor]];
//
//    [self.sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
////    [self.sendBtn setTitleColor:[UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0] forState:UIControlStateDisabled];
//    [self.sendBtn setTitle:@"发送" forState:UIControlStateNormal];
//    [self.sendBtn addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
//    [_emojiView addSubview:self.sendBtn];
//    [self.sendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.right.bottom.equalTo(_emojiView);
//        make.size.mas_equalTo(CGSizeMake(65, 49.5));
//    }];
//
//    UIView * bg = [[UIView alloc] initWithFrame:CGRectZero];
//    bg.backgroundColor = [UIColor colorWithLight:[UIColor colorWithRed:238/255.0 green:238/255.0 blue:238/255.0 alpha:1.0] Dark:[UIColor colorWithRed:17/255.0 green:17/255.0 blue:17/255.0 alpha:1.0]];
//    [_emojiView addSubview:bg];
//    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.bottom.equalTo(_emojiView);
//        make.size.mas_equalTo(CGSizeMake(65, 49.5));
//    }];
//    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
//    iv.image = [UIImage imageNamed:@"input box_emoji_class01"];
//    iv.backgroundColor = [UIColor clearColor];
//    [bg addSubview:iv];
//    [iv mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.centerY.equalTo(bg);
//        make.size.mas_equalTo(CGSizeMake(25, 25));
//    }];
//}
- (void)sendAction{
    self.sendMessageBlock();
//    [self sendBtnEnable:NO];
}
//- (void)sendBtnEnable:(BOOL)enable {
//    self.sendBtn.enabled = enable;
//    if (enable) {
//        self.sendBtn.backgroundColor = [UIColor colorWithRed:255/255.0 green:69/255.0 blue:75/255.0 alpha:1.0];
//    } else {
//        self.sendBtn.backgroundColor = [UIColor lightGrayColor];
//    }
//}
//表情视图
//-(UIView *)emojiView {
//    if(!_emojiView) {
//
//        if(_keyboardRect.size.width == 0 || _keyboardRect.size.height ==0) {
//         _keyboardRect = CGRectMake(0, 0, 736, 194);
//        }
//
//     _emojiView = [[UIView alloc] initWithFrame:_keyboardRect];
//     _emojiView.backgroundColor =[UIColor colorWithLight:CCRGBColor(242,239,237) Dark:[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1.0]];
//    _scrollView = [[UIScrollView alloc] init];
//    _scrollView.backgroundColor = [UIColor colorWithLight:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] Dark:[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1.0]];
//    _scrollView.frame = CGRectMake(0.0, 0.0, _emojiView.bounds.size.width, _emojiView.bounds.size.height-49.5);
//    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * 6.0, CGRectGetHeight(self.scrollView.bounds));
//    _scrollView.pagingEnabled = YES;
//    [_emojiView addSubview:_scrollView];
//    [self loadFacialView:1 size:CGSizeMake(30, 30)];
//
//
//    }
//    return _emojiView;
//}

//- (void) backFace {
//    NSString *inputString = _chatTextField.text;
//    if ( [inputString length] > 0) {
//        NSString *string = nil;
//        NSInteger stringLength = [inputString length];
//        if (stringLength >= FACE_NAME_LEN) {
//            string = [inputString substringFromIndex:stringLength - FACE_NAME_LEN];
//            NSRange range = [string rangeOfString:FACE_NAME_HEAD];
//            if ( range.location == 0 ) {
//                string = [inputString substringToIndex:[inputString rangeOfString:FACE_NAME_HEAD options:NSBackwardsSearch].location];
//            } else {
//                string = [inputString substringToIndex:stringLength - 1];
//            }
//        }
//        else {
//            string = [inputString substringToIndex:stringLength - 1];
//        }
//        _chatTextField.text = string;
//        if (_chatTextField.text.length == 0) {
//            [self sendBtnEnable:NO];
//        }
//    }
//}

//- (void)faceButtonClicked:(id)sender {
//    NSInteger i = ((UIButton*)sender).tag;
//    [self sendBtnEnable:YES];
//    NSMutableString *faceString = [[NSMutableString alloc]initWithString:_chatTextField.text];
//    [faceString appendString:[NSString stringWithFormat:@"[em2_%03d]",(int)i+201]];
//    _chatTextField.text = faceString;
//    [self chatTextFieldChange];
//}

-(UIButton *)courseButton
{
    if (!_courseButton) {
        _courseButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:nil Target:self Action:@selector(courseButtonAction) AndTag:0];
        [_courseButton setBackgroundImage:[UIImage imageNamed:@"tool_bar_course.png"] forState:UIControlStateNormal];
    }
    return _courseButton;
}

-(UIButton *)giftButton
{
    if (!_giftButton) {
        _giftButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:nil Target:self Action:@selector(giftButtonAction) AndTag:0];
        [_giftButton setBackgroundImage:[UIImage imageNamed:@"tool_bar_gift.png"] forState:UIControlStateNormal];
    }
    return _giftButton;
}

-(UIButton *)funcButton
{
    if (!_funcButton) {
        _funcButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:nil Target:self Action:@selector(funcButtonAction) AndTag:0];
        [_funcButton setBackgroundImage:[UIImage imageNamed:@"tool_bar_plus.png"] forState:UIControlStateNormal];
        [_funcButton setBackgroundImage:[UIImage imageNamed:@"tool_bar_close.png"] forState:UIControlStateSelected];
    }
    return _funcButton;
}

- (UIButton *)emojiButton
{
    if (!_emojiButton) {
        _emojiButton = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeCustom Title:nil Image:nil Target:self Action:@selector(emojiButtonAction) AndTag:0];
        [_emojiButton setBackgroundImage:[UIImage imageNamed:@"input_box_icon_emoji.png"] forState:UIControlStateNormal];
        [_emojiButton setBackgroundImage:[UIImage imageNamed:@"input box_icon_keyboard"] forState:UIControlStateSelected];

    }
    return _emojiButton;
}

- (UIButton *)button1
{
    if (!_button1) {
        _button1 = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeSystem Title:nil Image:nil Target:self Action:@selector(buttonOneAction) AndTag:0];
        [_button1 setBackgroundImage:[UIImage imageNamed:@"input_box_icon_one.png"] forState:UIControlStateNormal];
    }
    return _button1;
}

-(UIButton *)button2
{
    if (!_button2) {
        _button2 = [CCControl initButtonWithFrame:CGRectZero ButtonType:UIButtonTypeSystem Title:nil Image:nil Target:self Action:@selector(buttonTwoAction) AndTag:0];
        [_button2 setBackgroundImage:[UIImage imageNamed:@"input_box_icon_two.png"] forState:UIControlStateNormal];
    }
    return _button2;
}

//#pragma mark - TextFieldDelegate
//- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    if(!StrNotEmpty([_chatTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]])) {
//        [_informationView removeFromSuperview];
//        _informationView = [[InformationShowView alloc] initWithLabel:ALERT_EMPTYMESSAGE];
//        [APPDelegate.window addSubview:_informationView];
//        [_informationView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 200, 0));
//        }];
//
//        [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(informationViewRemove) userInfo:nil repeats:NO];
//        return YES;
//    }
//    //发送消息回调
//    if (_sendMessageBlock) {
//        _sendMessageBlock();
//    }
//    _chatTextField.text = nil;
//    [_chatTextField resignFirstResponder];
//    return YES;
//}
#pragma mark - 移除提示视图
-(void)informationViewRemove {
    [_informationView removeFromSuperview];
    _informationView = nil;
}
#pragma mark - 添加通知
-(void)addObserver{
    //键盘将要弹出
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    //键盘将要消失
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    //接收到停止弹出键盘
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hiddenKeyBoard:)
                                                 name:@"keyBorad_hidden"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeBgColor:) name:@"allow_chat" object:nil];
     
}
// 参数类型是NSNotification

- (void)changeBgColor:(NSNotification *)notification{

  BOOL allow_question = [notification.userInfo[@"allowChat"] boolValue];
  if (allow_question == YES) {
      self.isAllowChat = YES;
  } else {
      self.isAllowChat = NO;
  }
}
#pragma mark - 键盘事件
-(void)hiddenKeyBoard:(NSNotification *)noti{
    NSDictionary *userInfo = [noti userInfo];
    self.keyboardHidden = [userInfo[@"keyBorad_hidden"] boolValue];
}
//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
//    self.chatTextField.userInteractionEnabled = NO;
//    return YES;
//}
//键盘将要出现
- (void)keyboardWillShow:(NSNotification *)noti {
    self.textView.userInteractionEnabled = YES;
    self.textView.inputView = nil;
    NSDictionary *userInfo = [noti userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    _keyboardRect = [aValue CGRectValue];
    CGFloat y = _keyboardRect.size.height;
    if (self.delegate) {
        [self.delegate keyBoardWillShow:y endEditIng:self.keyboardHidden];
    }
    
    [self changeUIWithStyle:2];
}
//
//键盘将要消失
- (void)keyboardWillHide:(NSNotification *)notif {
    if (self.delegate) {
        [self.delegate hiddenKeyBoard];
    }
    [self changeUIWithStyle:1];
}
#pragma mark - 移除监听
-(void)removeObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"keyBorad_hidden" object:nil];
}
-(void)dealloc{
    [self removeObserver];
}

@end
