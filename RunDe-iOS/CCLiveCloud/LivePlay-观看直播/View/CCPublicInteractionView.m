//
//  CCInteractionView.m
//  CCLiveCloud
//
//  Created by 何龙 on 2019/1/7.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCPublicInteractionView.h"
#import "CCIntroductionView.h"//简介
#import "CCQuestionView.h"//问答
#import "Dialogue.h"//模型
#import "CCChatViewDataSourceManager.h"//数据处理
#import "CCGiftButton.h"
#import "CCSendGiftView.h" //送礼物

@interface CCPublicInteractionView ()<UIScrollViewDelegate, CCChatViewDataSourceManagerDelegate>

@property (nonatomic, strong)CCChatViewDataSourceManager *manager;//聊天数据源
@property (nonatomic,strong)CCIntroductionView       * introductionView;//简介视图
@property (nonatomic,strong)CCQuestionView           * questionChatView;//问答视图
@property (strong, nonatomic) NSMutableArray         * keysArrAll;//问答数组
@property (nonatomic,strong)NSMutableDictionary      * QADic;//问答字典
//@property (nonatomic,strong)UIScrollView             * scrollView;//文档聊天等视图
@property (nonatomic,strong)NSMutableDictionary      * userDic;//聊天字典
@property (nonatomic,strong)NSMutableDictionary      * dataPrivateDic;//私聊
//@property (nonatomic,strong)UIView                   * lineView;//分割线
//@property (nonatomic,strong)UIView                   * line;//分割线
//@property (nonatomic,strong)UIView                   * shadowView;//滚动条
@property (nonatomic,assign)NSInteger                  templateType;//房间类型
@property (nonatomic,copy)  NSString                 * viewerId;
@property (nonatomic,strong)NSMutableArray           * chatArr;//聊天数组
@property (nonatomic,assign)NSInteger                  lastTime;//最后一条消息
@property (nonatomic,strong)NSTimer                  * updateTimer;//更新计时器
@property (nonatomic, assign)BOOL                       isSmallDocView;//是否是文档小窗模式

@property (nonatomic,copy) HiddenMenuViewBlock       hiddenMenuViewBlock;//隐藏菜单按钮
@property (nonatomic,copy) ChatMessageBlock          chatMessageBlock;//公聊回调
@property (nonatomic,copy) PrivateChatBlock          privateChatBlock;//私聊回调
@property (nonatomic,copy) QuestionBlock             questionBlock;//问答回调
@property (nonatomic,assign) BOOL isAllowChat;

@property(nonatomic,strong)UIView * headerView;

@property(nonatomic,strong)CCGiftButton * giftButton;
@property(nonatomic,assign)BOOL isOffset;
@property(nonatomic,assign)BOOL headerViewIsClose;

@end
#define IMGURL @"[img_"
@implementation CCPublicInteractionView
- (void)dealloc
{
    [_updateTimer invalidate];
}
-(instancetype)initWithFrame:(CGRect)frame
              hiddenMenuView:(nonnull HiddenMenuViewBlock)block
                   chatBlock:(nonnull ChatMessageBlock)chatBlock
            privateChatBlock:(nonnull PrivateChatBlock)privateChatBlock
               questionBlock:(nonnull QuestionBlock)questionBlock
                 docViewType:(BOOL)isSmallDocView{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor blackColor]];
        self.isAllowChat = YES;
        _hiddenMenuViewBlock = block;
        _chatMessageBlock = chatBlock;
        _privateChatBlock = privateChatBlock;
        _questionBlock = questionBlock;
        _isSmallDocView = isSmallDocView;
        [self setUpUI];
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *dataFormatter = [[NSDateFormatter alloc]init];
        [dataFormatter setDateFormat:@"HH:mm:ss"];
        NSString *dateString = [dataFormatter stringFromDate:currentDate];
        _lastTime = [NSString timeSwitchTimestamp:dateString andFormatter:@"HH:mm:ss"];
        
        self.isOffset = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeBgColor:) name:@"allow_chat" object:nil];
    }
    return self;
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
//初始化布局
-(void)setUpUI{
    //设置功能切换
    [self addSubview:self.headerView];
    self.headerView.frame = CGRectMake(0, 0, self.frame.size.width, 85);
    self.headerView.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
    [self.headerView addSubview:self.giftButton];
    [self.giftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-15));
        make.width.equalTo(@80);
        make.height.equalTo(@30);
        make.centerY.equalTo(self.headerView);
    }];
    
    [self.headerView addSubview:self.authorLabel];
    [self.authorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.headerView);
        make.left.equalTo(self.headerView).offset(16);
    }];
    
    [self.headerView addSubview:self.peopleCountLabel];
    [self.peopleCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.headerView);
        make.left.equalTo(self.authorLabel.mas_right).offset(16 );
    }];
    UIView * line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithLight:[UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
    [self.headerView addSubview:self.giftButton];
    [self.headerView addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.headerView);
        make.height.mas_equalTo(1);
    }];
    UIView * line1 = [[UIView alloc] init];
    line1.backgroundColor = [UIColor colorWithLight:[UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
    [self.headerView addSubview:self.giftButton];
    [self.headerView addSubview:line1];
    [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.headerView);
        make.height.mas_equalTo(1);
    }];
    
    [self addSubview:self.chatView];
    self.chatView.frame = CGRectMake(0, CGRectGetMaxY(self.headerView.frame), self.frame.size.width, self.frame.size.height - self.headerView.frame.size.height);
    

}
- (void)upDateHeaderViewConstraintIsClose:(BOOL)isClose
{
    if (self.headerViewIsClose!=isClose)
    {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:.3 animations:^{
            if (isClose){
                weakSelf.headerView.frame = CGRectMake(150,0, self.frame.size.width- 150, 85);
                    [self.authorLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.headerView).offset(25);
                        make.left.equalTo(self.headerView).offset(15);
                    }];
                    
                    [self.headerView addSubview:self.peopleCountLabel];
                    [self.peopleCountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.authorLabel.mas_bottom).offset(5);
                        make.left.equalTo(self.authorLabel);
                    }];
                    self.chatView.frame = CGRectMake(0, CGRectGetMaxY(self.headerView.frame), self.frame.size.width, self.frame.size.height - self.headerView.frame.size.height);
//                [self.chatView.funcBgView mas_remakeConstraints:^(MASConstraintMaker *make) {
//                    make.left.and.right.equalTo(@0);
//                    make.bottom.equalTo(self.chatView.inputView.mas_top);
//                    make.height.equalTo(@(13 + 35 + 13));
//                }];
            }else {
                weakSelf.headerView.frame = CGRectMake(0, 0, self.frame.size.width, 60);
                    [self.authorLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.centerY.equalTo(self.headerView);
                        make.left.equalTo(self.headerView).offset(16);
                    }];
                    
                    [self.headerView addSubview:self.peopleCountLabel];
                    [self.peopleCountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.centerY.equalTo(self.headerView);
                        make.left.equalTo(self.authorLabel.mas_right).offset(16 );
                    }];
                
            }
                    self.chatView.frame = CGRectMake(0, CGRectGetMaxY(self.headerView.frame), self.frame.size.width, self.frame.size.height - self.headerView.frame.size.height);
//            [self.chatView.funcBgView mas_remakeConstraints:^(MASConstraintMaker *make) {
//                make.left.and.right.equalTo(@0);
//                make.bottom.equalTo(self.chatView.inputView.mas_top);
//                make.height.equalTo(@(13 + 35 + 13 + 25));
//            }];
        }];
        self.headerViewIsClose = isClose;
    }
    
}

#pragma mark - 响应事件
-(void)giftButtonAction
{
//    NSLog(@"点击送礼物");
    if (self.isAllowChat == YES) {
        
        CCSendGiftView * giftView = [[CCSendGiftView alloc]init];
        [giftView show];
    } else {
         [[NSNotificationCenter defaultCenter] postNotificationName:@"showBanChat" object:nil userInfo:nil];
    }
}


 
#pragma mark - 私有方法-----

/**
 移除文档视图(接收到房间信息，不支持房间类型时移除文档视图

 @param docView docView
 */
-(void)removeDocView:(UIView *)docView{
    if (!_isSmallDocView) {
        [_docView removeFromSuperview];
        _docView = nil;
    }else{
        [docView removeFromSuperview];
    }
}
#pragma mark - SDK代理方法----------------------------
#pragma mark- 房间信息
//房间信息
-(void)roomInfo:(NSDictionary *)dic withPlayView:(CCPlayerView *)playerView smallView:(UIView *)smallView{
    
    NSArray *array = [_introductionView subviews];
    for(UIView *view in array) {
        [view removeFromSuperview];
    }
    self.introductionView.roomDesc = dic[@"desc"];
    if(!StrNotEmpty(dic[@"desc"])) {
        self.introductionView.roomDesc = EMPTYINTRO;
    }
    self.introductionView.roomName = dic[@"name"];
    
//    CGFloat shadowViewY = self.segment.frame.origin.y + self.segment.frame.size.height-2;
    _templateType = [dic[@"templateType"] integerValue];
    //    @"文档",@"聊天",@"问答",@"简介"
    
   
}
#pragma mark - 服务器端给自己设置的groupId
/**
 *    @brief    服务器端给自己设置的信息(The new method)
 *    viewerId 服务器端给自己设置的UserId
 *    groupId 分组id
 *    name 用户名
 */
-(void)setMyViewerInfo:(NSDictionary *) infoDic{
    //如果没有groupId这个字段,设置groupId为空(为空时默认显示所有聊天)
//    if([[infoDic allKeys] containsObject:@"groupId"]){
//        _groupId = infoDic[@"groupId"];
//    }else{
//        _groupId = @"";
//    }
    _groupId = @"";
    _viewerId = infoDic[@"viewerId"];
}
#pragma mark - 聊天管理
/**
 *    @brief    聊天管理(The new method)
 *    status    聊天消息的状态 0 显示 1 不显示
 *    chatIds   聊天消息的id列列表
 */
-(void)chatLogManage:(NSDictionary *) manageDic{
    //遍历数组,取出每一条聊天信息
    NSMutableArray *reloadArr = [NSMutableArray array];
    NSMutableArray *newPublicChatArr = [self.manager.publicChatArray mutableCopy];
    for (Dialogue *model in self.manager.publicChatArray) {
        //找到需要更改状态的那条信息
        if ([manageDic[@"chatIds"] containsObject:model.chatId]) {
            BOOL fromSelf = [model.fromuserid isEqualToString:model.myViwerId];
            BOOL haveImg = [model.msg containsString:@"http://"];
            if ([manageDic[@"status"] isEqualToString:@"0"] && !fromSelf && !haveImg) {
                [self.playerView insertDanmuModel:(CCPublicChatModel *)model];
            }
            //找到消息的位置
            NSUInteger index = [self.manager.publicChatArray indexOfObject:model];
            //更改消息的状态码
            model.status = manageDic[@"status"];
            //更新公聊数组状态
            [newPublicChatArr replaceObjectAtIndex:index withObject:model];
            //记录更改状态的模型下标
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [reloadArr addObject:indexPath];
        }
    }
    if (!reloadArr.count) {
//        NSLog(@"找不到聊天审核的信息");
        return;
    }
    //调用chatView的方法,更新聊天状态,并且刷新某一行
    [self.chatView reloadStatusWithIndexPaths:reloadArr publicArr:newPublicChatArr];
    [self.manager.publicChatArray removeAllObjects];
    self.manager.publicChatArray = [newPublicChatArr mutableCopy];
}
#pragma mark- 聊天
/**
 *    @brief    收到私聊信息
 */
- (void)OnPrivateChat:(NSDictionary *)dic withMsgBlock:(NewMessageBlock)block {
    //判断消息方是否是自己
    BOOL fromSelf = [dic[@"fromuserid"] isEqualToString:_viewerId];
    if ((!fromSelf && _chatView.ccPrivateChatView.frame.origin.y == SCREENH_HEIGHT) || _chatView.ccPrivateChatView.hidden) {
        //提示新私聊消息
        block();
    }
    
    if(dic[@"fromuserid"] && dic[@"fromusername"] && [self.userDic objectForKey:dic[@"fromuserid"]] == nil) {
        [self.userDic setObject:dic[@"fromusername"] forKey:dic[@"fromuserid"]];
    }
    if(dic[@"touserid"] && dic[@"tousername"] && [self.userDic objectForKey:dic[@"touserid"]] == nil) {
        [self.userDic setObject:dic[@"tousername"] forKey:dic[@"touserid"]];
    }
    Dialogue *dialogue = [[Dialogue alloc] init];
    dialogue.userid = dic[@"fromuserid"];
    dialogue.fromuserid = dic[@"fromuserid"];
    dialogue.username = dic[@"fromusername"];
    dialogue.fromusername = dic[@"fromusername"];
    dialogue.useravatar = dic[@"useravatar"];
    dialogue.touserid = dic[@"touserid"];
    dialogue.msg = dic[@"msg"];
    dialogue.time = dic[@"time"];
    dialogue.tousername = self.userDic[dialogue.touserid];
    dialogue.myViwerId = _viewerId;
    //判断是否有fromuserrole这个字段，如果没有，给他赋值
    if (![[dic allKeys] containsObject:@"fromuserrole"]) {
//        NSLog(@"没有身份标识");
        dialogue.fromuserrole = @"host";
    }else{
        dialogue.fromuserrole = dic[@"fromuserrole"];
    }
    
    NSString *anteName = nil;
    NSString *anteid = nil;
    if([dialogue.fromuserid isEqualToString:self.viewerId]) {
        anteid = dialogue.touserid;
        anteName = dialogue.tousername;
    } else {
        anteid = dialogue.fromuserid;
        anteName = dialogue.fromusername;
    }
    NSMutableArray *array = [self.dataPrivateDic objectForKey:anteid];
    if(!array) {
        array = [[NSMutableArray alloc] init];
        [self.dataPrivateDic setValue:array forKey:anteid];
    }
    [array addObject:dialogue];
    [self.chatView reloadPrivateChatDict:self.dataPrivateDic anteName:anteName anteid:anteid];
}
/**
 *    @brief  历史聊天数据
 */
- (void)onChatLog:(NSArray *)chatLogArr {
    /*  防止网络不好或者断开连麦时重新刷新此接口，导致重复显示历史聊天数据 */
    if (self.manager.publicChatArray.count > 0) {
        return;
    }
    //解析历史聊天数据
    [self.manager initWithPublicArray:chatLogArr userDic:self.userDic viewerId:self.viewerId groupId:self.groupId];
    [self.chatView reloadPublicChatArray:self.manager.publicChatArray];
}
/**
 *    @brief  收到公聊消息
 */
- (void)onPublicChatMessage:(NSDictionary *)dic{
    //解析公聊消息
    WS(weakSelf)
    [self.manager addPublicChat:dic userDic:self.userDic viewerId:self.viewerId groupId:self.groupId danMuBlock:^(CCPublicChatModel * _Nonnull model) {
        //弹幕
        [weakSelf.playerView insertDanmuModel:model];
    }];
    //判断时间
    NSString *publistTime = dic[@"time"];
    NSInteger publish = [NSString timeSwitchTimestamp:publistTime andFormatter:@"HH:mm:ss"];
    if (_lastTime == publish) {
        //添加数组
        [self.chatArr addObject:[self.manager.publicChatArray lastObject]];
//        NSLog(@"同一秒，添加至数组");
        [_updateTimer invalidate];
            if (@available(iOS 10.0, *)) {
                _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
                    if (weakSelf.chatArr.count != 0) {
                        [weakSelf.chatView addPublicChatArray:weakSelf.chatArr];
                        [weakSelf.chatArr removeAllObjects];
                        //                NSLog(@"延迟数据校对");
                    }
                }];
            } else {
             _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(addPublicChatArray) userInfo:nil repeats:YES];
            }

    }else{
        if (self.chatArr.count != 0) {
            [self.chatView addPublicChatArray:self.chatArr];
            [self.chatArr removeAllObjects];
//            NSLog(@"将数组中的元素添加至消息中");
        }
        [self.chatView addPublicChat:[self.manager.publicChatArray lastObject]];
        _lastTime = publish;
    }
    
//    [self.chatView reloadPublicChatArray:self.manager.publicChatArray];
}
- (void)addPublicChatArray {
    if (self.chatArr.count != 0) {
        [self.chatView addPublicChatArray:self.chatArr];
        [self.chatArr removeAllObjects];
        //                NSLog(@"延迟数据校对");
    }
}
/**
 *  @brief  接收到发送的广播
 */
- (void)broadcast_msg:(NSDictionary *)dic {
    //解析广播消息
    [self.manager addRadioMessage:dic];
    [self.chatView addPublicChat:[self.manager.publicChatArray lastObject]];
}
/*
 *  @brief  收到自己的禁言消息，如果你被禁言了，你发出的消息只有你自己能看到，其他人看不到
 */
- (void)onSilenceUserChatMessage:(NSDictionary *)message {
    
    [self onPublicChatMessage:message];
}
/**
 *    @brief    当主讲全体禁言时，你再发消息，会出发此代理方法，information是禁言提示信息
 */
- (void)information:(NSString *)information {
    
}
#pragma mark- 问答
//发布问题的id
-(void)publish_question:(NSString *)publishId {
    for(NSString *encryptId in self.keysArrAll) {
        NSMutableArray *arr = [self.QADic objectForKey:encryptId];
        Dialogue *dialogue = [arr objectAtIndex:0];
        if(dialogue.dataType == NS_CONTENT_TYPE_QA_QUESTION && [dialogue.encryptId isEqualToString:publishId]) {
            dialogue.isPublish = YES;
        }
    }
    [self.questionChatView reloadQADic:self.QADic keysArrAll:self.keysArrAll];
}
/**
 *    @brief  收到提问，用户观看时和主讲的互动问答信息
 */
- (void)onQuestionDic:(NSDictionary *)questionDic
{
    
    if ([questionDic count] == 0) return ;
    if (questionDic) {
        Dialogue *dialog = [[Dialogue alloc] init];
        //通过groupId过滤数据------
        NSString *msgGroupId = questionDic[@"value"][@"groupId"];
        //判断是否自己or消息的groupId为空or是否是本组聊天信息
        if ([_groupId isEqualToString:@""] || [msgGroupId isEqualToString:@""] || [self.groupId isEqualToString:msgGroupId] || !msgGroupId) {
            
            dialog.msg = questionDic[@"value"][@"content"];
            dialog.username = questionDic[@"value"][@"userName"];
            dialog.fromuserid = questionDic[@"value"][@"userId"];
            dialog.myViwerId = _viewerId;
            dialog.time = questionDic[@"time"];
            NSString *encryptId = questionDic[@"value"][@"id"];
            if([encryptId isEqualToString:@"-1"]) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
                NSString *dateTime = [formatter stringFromDate:[NSDate date]];
                encryptId = [NSString stringWithFormat:@"%@[%@]",encryptId,dateTime];
            }
            dialog.encryptId = encryptId;
            dialog.useravatar = questionDic[@"useravatar"];
            dialog.dataType = NS_CONTENT_TYPE_QA_QUESTION;
            dialog.isPublish = NO;
            
            
            //将过滤过的数据添加至问答字典
            NSMutableArray *arr = [self.QADic objectForKey:dialog.encryptId];
            if (arr == nil) {
                arr = [[NSMutableArray alloc] init];
                [self.QADic setObject:arr forKey:dialog.encryptId];
            }
            if(![self.keysArrAll containsObject:dialog.encryptId]) {
                [self.keysArrAll addObject:dialog.encryptId];
            }
            [arr addObject:dialog];
            [self.questionChatView reloadQADic:self.QADic keysArrAll:self.keysArrAll];
        }
    }
}
/**
 *    @brief  收到回答
 */
- (void)onAnswerDic:(NSDictionary *)answerDic
{
    
    if ([answerDic count] == 0) return;
    
    if (answerDic) {
        Dialogue *dialog = [[Dialogue alloc] init];
        dialog.msg = answerDic[@"value"][@"content"];
        dialog.username = answerDic[@"value"][@"userName"];
        dialog.fromuserid = answerDic[@"value"][@"questionUserId"];
        dialog.myViwerId = _viewerId;
        dialog.time = answerDic[@"time"];
        dialog.encryptId = answerDic[@"value"][@"questionId"];
        dialog.useravatar = answerDic[@"useravatar"];
        dialog.dataType = NS_CONTENT_TYPE_QA_ANSWER;
        dialog.isPrivate = [answerDic[@"value"][@"isPrivate"] boolValue];
        
        NSMutableArray *arr = [self.QADic objectForKey:dialog.encryptId];
        if (arr == nil) {
            arr = [[NSMutableArray alloc] init];
            [self.QADic setObject:arr forKey:dialog.encryptId];
        } else if (dialog.isPrivate == NO && [arr count] > 0) {
            Dialogue *firstDialogue = [arr objectAtIndex:0];
            if(firstDialogue.isPublish == NO && firstDialogue.dataType == NS_CONTENT_TYPE_QA_QUESTION) {
                firstDialogue.isPublish = YES;
            }
        }
        [arr addObject:dialog];
        [self.questionChatView reloadQADic:self.QADic keysArrAll:self.keysArrAll];
    }
}
/**
 *    @brief  收到提问&回答
 */
- (void)onQuestionArr:(NSArray *)questionArr onAnswerArr:(NSArray *)answerArr
{
    
    if ([questionArr count] == 0 && [answerArr count] == 0) {
        return;
    }
    
    [self.QADic removeAllObjects];
    
    for (NSDictionary *dic in questionArr) {
        Dialogue *dialog = [[Dialogue alloc] init];
        //通过groupId过滤数据------start
        NSString *msgGroupId = dic[@"groupId"];
        //判断是否自己or消息的groupId为空or是否是本组聊天信息
        if ([_groupId isEqualToString:@""] || [msgGroupId isEqualToString:@""] || [self.groupId isEqualToString:msgGroupId] || !msgGroupId) {
            
            dialog.msg = dic[@"content"];
            dialog.username = dic[@"questionUserName"];
            dialog.fromuserid = dic[@"questionUserId"];
            dialog.myViwerId = _viewerId;
            dialog.time = dic[@"time"];
            dialog.encryptId = dic[@"encryptId"];
            dialog.useravatar = dic[@"useravatar"];
            dialog.dataType = NS_CONTENT_TYPE_QA_QUESTION;
            dialog.isPublish = [dic[@"isPublish"] boolValue];
            
            //将过滤过的数据添加至问答字典
            NSMutableArray *arr = [self.QADic objectForKey:dialog.encryptId];
            if (arr == nil) {
                arr = [[NSMutableArray alloc] init];
                [self.QADic setObject:arr forKey:dialog.encryptId];
            }
            if(![self.keysArrAll containsObject:dialog.encryptId]) {
                [self.keysArrAll addObject:dialog.encryptId];
            }
            
            [arr addObject:dialog];
        }
    }
    
    for (NSDictionary *dic in answerArr) {
        Dialogue *dialog = [[Dialogue alloc] init];
        dialog.msg = dic[@"content"];
        dialog.username = dic[@"answerUserName"];
        dialog.fromuserid = dic[@"answerUserId"];
        dialog.myViwerId = _viewerId;
        dialog.encryptId = dic[@"encryptId"];
        dialog.useravatar = dic[@"useravatar"];
        dialog.dataType = NS_CONTENT_TYPE_QA_ANSWER;
        dialog.isPrivate = [dic[@"isPrivate"] boolValue];
        NSMutableArray *arr = [self.QADic objectForKey:dialog.encryptId];
        if (arr != nil) {
            [arr addObject:dialog];
        }
    }
    
    [self.questionChatView reloadQADic:self.QADic keysArrAll:self.keysArrAll];
}
//主动调用方法
/**
 *    @brief    提问
 *    @param     message 提问内容
 */
- (void)question:(NSString *)message {
    //提问
    if (_questionBlock) {
        _questionBlock(message);
    }
}
#pragma mark - 懒加载
//创建聊天问答等功能选择
/*
-(UISegmentedControl *)segment {
    if(!_segment) {
        NSArray *segmentedArray = [[NSArray alloc] initWithObjects:@"聊天",@"问答",@"简介", nil];
        _segment = [[UISegmentedControl alloc] initWithItems:segmentedArray];
        //文字设置
        NSMutableDictionary *attDicNormal = [NSMutableDictionary dictionary];
        attDicNormal[NSFontAttributeName] = [UIFont systemFontOfSize:FontSize_30];
        attDicNormal[NSForegroundColorAttributeName] = CCRGBColor(51,51,51);
        NSMutableDictionary *attDicSelected = [NSMutableDictionary dictionary];
        attDicSelected[NSFontAttributeName] = [UIFont systemFontOfSize:FontSize_30];
        attDicSelected[NSForegroundColorAttributeName] = CCRGBColor(51,51,51);
        [_segment setTitleTextAttributes:attDicNormal forState:UIControlStateNormal];
        [_segment setTitleTextAttributes:attDicSelected forState:UIControlStateSelected];
        _segment.selectedSegmentIndex = 0;
        _segment.backgroundColor = [UIColor whiteColor];
        
//        _segment.tintColor = [UIColor whiteColor];
        [_segment setBackgroundImage:[self imageWithColor:UIColor.whiteColor] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [_segment setBackgroundImage:[self imageWithColor:UIColor.whiteColor] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [_segment setDividerImage:[self imageWithColor:UIColor.whiteColor] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        _segment.momentary = NO;
        [_segment addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        
    }
    return _segment;
}
 */
 
- (UIImage *)imageWithColor:(UIColor *)color {
    
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}
-(CCDocView *)docView{
    if (!_docView) {
        _docView = [[CCDocView alloc] initWithType:_isSmallDocView];
    }
    return _docView;
}
//创建简介视图
-(CCIntroductionView *)introductionView {
    if(!_introductionView) {
        _introductionView = [[CCIntroductionView alloc] init];
        _introductionView.backgroundColor = CCRGBColor(250,250,250);
    }
    return _introductionView;
}
//创建问答视图
-(CCQuestionView *)questionChatView {
    if(!_questionChatView) {
        WS(weakSelf)
        _questionChatView = [[CCQuestionView alloc] initWithQuestionBlock:^(NSString *message) {
            [weakSelf question:message];
        } input:YES];
        _questionChatView.backgroundColor = [UIColor grayColor];
    }
    return _questionChatView;
}
//问答相关
-(NSMutableArray *)keysArrAll {
    if(_keysArrAll==nil || [_keysArrAll count] == 0) {
        _keysArrAll = [[NSMutableArray alloc]init];
    }
    return _keysArrAll;
}
-(NSMutableDictionary *)QADic {
    if(!_QADic) {
        _QADic = [[NSMutableDictionary alloc] init];
    }
    return _QADic;
}
//创建聊天视图
-(CCChatBaseView *)chatView {
    if(!_chatView) {
        WS(weakSelf)
        //公聊发消息回调
        _chatView = [[CCChatBaseView alloc] initWithPublicChatBlock:^(NSString * _Nonnull msg) {
            // 发送公聊信息
            if (weakSelf.chatMessageBlock) {
                weakSelf.chatMessageBlock(msg);
            }
        } isInput:YES];
        //私聊发消息回调
        _chatView.privateChatBlock = ^(NSString * _Nonnull anteid, NSString * _Nonnull msg) {
            // 发送私聊信息
            if (weakSelf.privateChatBlock) {
                weakSelf.privateChatBlock(anteid, msg);
            }
        };
        _chatView.backgroundColor = [UIColor colorWithLight:CCRGBColor(250,250,250) Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
    }
    return _chatView;
}
//初始化数据管理
-(CCChatViewDataSourceManager *)manager{
    if (!_manager) {
        _manager = [CCChatViewDataSourceManager sharedManager];
        _manager.delegate = self;
        [_manager removeData];
    }
    return _manager;
}
//聊天相关
-(NSMutableDictionary *)userDic {
    if(!_userDic) {
        _userDic = [[NSMutableDictionary alloc] init];
    }
    return _userDic;
}
-(NSDictionary *)dataPrivateDic {
    if(!_dataPrivateDic) {
        _dataPrivateDic = [[NSMutableDictionary alloc] init];
    }
    return _dataPrivateDic;
}
//滚动条
//-(UIView *)shadowView {
//    if (!_shadowView) {
//        _shadowView = [[UIView alloc] init];
//        _shadowView.backgroundColor = CCRGBColor(255,102,51);
//    }
//    return _shadowView;
//}
//聊天数组
-(NSMutableArray *)chatArr{
    if (!_chatArr) {
        _chatArr = [NSMutableArray array];
    }
    return _chatArr;
}

-(UIView *)headerView
{
    if (!_headerView) {
        _headerView = [CCControl initViewWithFrame:CGRectZero BackgroundColor:[UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]] Tag:0 AndAlpha:1];
    }
    return _headerView;
}

-(UILabel *)authorLabel
{
    if (!_authorLabel) {
        _authorLabel = [CCControl initLabelWithFrame:CGRectZero Title:@"老师直播间" TextColor:[UIColor colorWithLight:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] Dark:[UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0]] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont systemFontOfSize:16]];
    }
    return _authorLabel;
}

-(UILabel *)peopleCountLabel
{
    if (!_peopleCountLabel) {
        _peopleCountLabel = [CCControl initLabelWithFrame:CGRectZero Title:@"" TextColor:[UIColor colorWithLight:[UIColor colorWithRed:150/255.0 green:148/255.0 blue:148/255.0 alpha:1.0] Dark:[UIColor colorWithRed:99/255.0 green:99/255.0 blue:102/255.0 alpha:1.0]] TextAlignment:NSTextAlignmentLeft AndFont:[UIFont systemFontOfSize:14]];
    }
    return _peopleCountLabel;
}

-(CCGiftButton *)giftButton
{
    if (!_giftButton) {
        _giftButton = [CCGiftButton buttonWithType:UIButtonTypeCustom];
        _giftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_giftButton setTitle:@"送礼物" forState:UIControlStateNormal];
        [_giftButton setTitleColor:[UIColor colorWithRed:254/255.0 green:153/255.0 blue:42/255.0 alpha:1.0] forState:UIControlStateNormal];
        _giftButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_giftButton setImage:[UIImage imageNamed:@"live_gift.png"] forState:UIControlStateNormal];
        [_giftButton addTarget:self action:@selector(giftButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _giftButton.layer.masksToBounds = YES;
        _giftButton.layer.cornerRadius = 4;
        _giftButton.layer.borderWidth = 0.5;
        _giftButton.layer.borderColor = [UIColor colorWithRed:254/255.0 green:153/255.0 blue:42/255.0 alpha:1.0].CGColor;
    }
    return _giftButton;
}

#pragma mark - CCChatViewDataSourceDelegate
- (void)updateIndexPath:(nonnull NSIndexPath *)indexPath chatArr:(nonnull NSMutableArray *)chatArr {
    id object = [chatArr objectAtIndex:indexPath.row];
    [self.chatView.publicChatArray replaceObjectAtIndex:indexPath.row withObject:object];
    [self.chatView reloadStatusWithIndexPath:indexPath publicArr:self.chatView.publicChatArray];
}

#pragma mark - 移除聊天
-(void)removeChatView{
    [self.chatView.ccPrivateChatView removeFromSuperview];
    [[CCChatViewDataSourceManager sharedManager] removeData];
}
@end
