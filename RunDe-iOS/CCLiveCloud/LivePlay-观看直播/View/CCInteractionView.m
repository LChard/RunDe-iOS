//
//  CCInteractionView.m
//  CCLiveCloud
//
//  Created by 何龙 on 2019/1/7.
//  Copyright © 2019 MacBook Pro. All rights reserved.
//

#import "CCInteractionView.h"
#import "CCIntroductionView.h"//简介
#import "CCQuestionView.h"//问答
#import "Dialogue.h"//模型
#import "CCChatViewDataSourceManager.h"//数据处理
#import "CCLiveDirectory.h"
@interface CCInteractionView ()<UIScrollViewDelegate, CCChatViewDataSourceManagerDelegate>

@property (nonatomic, strong)CCChatViewDataSourceManager *manager;//聊天数据源
@property (nonatomic,strong)CCIntroductionView       * introductionView;//简介视图
//@property (nonatomic,strong)CCQuestionView           * questionChatView;//问答视图
@property (nonatomic,strong)CCLiveDirectory           * questionChatView;//问答视图

@property (strong, nonatomic) NSMutableArray         * keysArrAll;//问答数组
@property (nonatomic,strong)NSMutableDictionary      * QADic;//问答字典
@property (nonatomic,strong)UIScrollView             * scrollView;//文档聊天等视图
@property (nonatomic,strong)NSMutableDictionary      * userDic;//聊天字典
@property (nonatomic,strong)NSMutableDictionary      * dataPrivateDic;//私聊
@property (nonatomic,strong)UIView                   * lineView;//分割线
@property (nonatomic,strong)UIView                   * line;//分割线
@property (nonatomic,strong)UIView                   * shadowView;//滚动条
@property (nonatomic,assign)NSInteger                  templateType;//房间类型
@property (nonatomic,copy)  NSString                 * viewerId;
@property (nonatomic,strong)NSMutableArray           * chatArr;//聊天数组
@property (nonatomic,assign)NSInteger                  lastTime;//最后一条消息
@property (nonatomic,strong)NSTimer                  * updateTimer;//更新计时器
@property (nonatomic, assign)BOOL                       isSmallDocView;//是否是文档小窗模式
@property (nonatomic, assign)BOOL                       ischange;//是否是切换直播和回放

@property (nonatomic,copy) HiddenMenuViewBlock       hiddenMenuViewBlock;//隐藏菜单按钮
@property (nonatomic,copy) ChatMessageBlock          chatMessageBlock;//公聊回调
@property (nonatomic,copy) PrivateChatBlock          privateChatBlock;//私聊回调
@property (nonatomic,copy) QuestionBlock             questionBlock;//问答回调

@end
#define IMGURL @"[img_"
@implementation CCInteractionView
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
        self.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0]];
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
    }
    return self;
}
//初始化布局
-(void)setUpUI{
    //设置功能切换
    //UISegmentedControl,功能控制,聊天文档等
    [self addSubview:self.segment];
    self.segment.frame = CGRectMake(0, 0, SCREEN_WIDTH, CCGetRealFromPt(82));
    
    [self addSubview:self.shadowView];
    UIView * bgline = [[UIView alloc] initWithFrame:CGRectZero];
    bgline.backgroundColor =  [UIColor colorWithLight:[UIColor colorWithHexString:@"#dddddd" alpha:1.0f] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
    [self addSubview:bgline];
    [bgline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_segment);
        make.width.mas_equalTo(SCREEN_WIDTH);
        make.height.mas_equalTo(1);
    }];
    //UIScrollView分块,聊天,问答,简介均添加在这里
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CCGetRealFromPt(82), self.frame.size.width , SCREENH_HEIGHT - (SCREEN_WIDTH *0.5625 + CCGetRealFromPt(80))-SCREEN_STATUS)];
    _scrollView.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
    _scrollView.pagingEnabled = YES;
    _scrollView.scrollEnabled = NO;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * 3, _scrollView.frame.size.height);
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_scrollView];
    
    //添加更多菜单
//    [APPDelegate.window addSubview:self.menuView];
    
    
    //添加聊天
    [_scrollView addSubview:self.chatView];
    self.chatView.frame = CGRectMake(0, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    
    //添加直播目录
    [_scrollView addSubview:self.questionChatView];
    self.questionChatView.frame = CGRectMake(_scrollView.frame.size.width * 1, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    
    //添加讲师介绍
    [_scrollView addSubview:self.introductionView];
    self.introductionView.frame = CGRectMake(_scrollView.frame.size.width * 2, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    
}

#pragma mark - 响应事件
- (void)changeLive:(UIButton *)sender {
    if (sender.tag == 1) {
        sender.tag = 2;
    } else {
        sender.tag = 1;
    }
    self.actionBlock(sender.tag);
//    _segment.selectedSegmentIndex = 1;
    self.ischange = YES;


}
#pragma mark - 切换底部功能
//切换底部功能 如聊天,问答,简介等
- (void)segmentAction:(UISegmentedControl *)segment
{
    NSInteger index = segment.selectedSegmentIndex;
    int py = _scrollView.contentOffset.y;
    [self endEditing:YES];
    CGFloat width0 = [segment widthForSegmentAtIndex:0];
    CGFloat width1 = [segment widthForSegmentAtIndex:1];
    CGFloat width2 = [segment widthForSegmentAtIndex:2];
    CGFloat width3 = 0;//[segment widthForSegmentAtIndex:3];
    CGFloat shadowViewY = segment.frame.origin.y + segment.frame.size.height - 3;
    switch(index){
        case 0: {
            [UIView animateWithDuration:0.25 animations:^{
                self.shadowView.frame = CGRectMake(width0/2-12.5, shadowViewY, 25, 3);
            }];

        }
            [self.scrollView setContentOffset:CGPointMake(0, py)];
            break;
        case 1: {
            [UIView animateWithDuration:0.25 animations:^{
                self.shadowView.frame = CGRectMake(width0+width1/2 - 12.5, shadowViewY, 25, 3);
            }];
        }
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width, py)];
            [self.questionChatView becomeFirstResponder];
            break;
        case 2: {
            [UIView animateWithDuration:0.25 animations:^{
                self.shadowView.frame = CGRectMake(width0 + width1 + width2/2 -12.5, shadowViewY, 25, 3);
            }];
        }
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * 2, py)];
            break;
        case 3: {
            [UIView animateWithDuration:0.25 animations:^{
                self.shadowView.frame = CGRectMake(width0 + width1 + width2 + width3 / 2 - 12.5, shadowViewY, 25, 3);
            }];
        }
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * 3, py)];
            break;
        default:
            break;
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
    
    CGFloat shadowViewY = self.segment.frame.origin.y + self.segment.frame.size.height-3;
    _templateType = [dic[@"templateType"] integerValue];
    //    @"文档",@"聊天",@"问答",@"简介"
    if (_templateType == 1) {
        //聊天互动： 无 直播文档： 无 直播问答： 无
        [_segment setWidth:0.0f forSegmentAtIndex:0];
        [_segment setWidth:0.0f forSegmentAtIndex:1];
        [_segment setWidth:self.segment.frame.size.width forSegmentAtIndex:2];
//        [_segment setWidth:0.0f forSegmentAtIndex:3];
        _segment.selectedSegmentIndex = 2;
        _shadowView.frame = CGRectMake([self.segment widthForSegmentAtIndex:0] + [self.segment widthForSegmentAtIndex:1]+[self.segment widthForSegmentAtIndex:2]/2 -12.5, shadowViewY, 25, 3);
        int py = _scrollView.contentOffset.y;
        [_scrollView setContentOffset:CGPointMake(SCREEN_WIDTH * 2, py)];
        
        /*    移除文档视图,隐藏切换按钮,移除视频聊天功能   */
        [self removeDocView:smallView];
        playerView.changeButton.hidden = YES;
        [playerView.contentView removeFromSuperview];
    } else if (_templateType == 2) {
        //聊天互动： 有 直播文档： 无 直播问答： 有
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:0];
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:1];
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:2];
//        [_segment setWidth:0.0f forSegmentAtIndex:3];
        _segment.selectedSegmentIndex = 0;
        _shadowView.frame = CGRectMake([self.segment widthForSegmentAtIndex:0]/2 - 12.5, shadowViewY, 25, 3);
        int py = _scrollView.contentOffset.y;
        [_scrollView setContentOffset:CGPointMake(0, py)];
        
        /*    移除文档视图,隐藏切换按钮   */
        [self removeDocView:smallView];
        playerView.changeButton.hidden = YES;
    } else if (_templateType == 3) {
        //聊天互动： 有 直播文档： 无 直播问答： 无
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:0];
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:1];
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:2];
//        [_segment setWidth:0.0f forSegmentAtIndex:3];
        _segment.selectedSegmentIndex = 0;
        _shadowView.frame = CGRectMake([self.segment widthForSegmentAtIndex:0]/2 - 12.5, shadowViewY, 25, 3);
        int py = _scrollView.contentOffset.y;
        [_scrollView setContentOffset:CGPointMake(0, py)];
        
        /*    移除文档视图,隐藏切换按钮   */
        [self removeDocView:smallView];
        playerView.changeButton.hidden = YES;
    } else if (_templateType == 4) {
        //聊天互动： 有 直播文档： 有 直播问答： 无
        _segment.selectedSegmentIndex = 0;
//        CGFloat docWidth = _isSmallDocView ? 0 : self.segment.frame.size.width / count;
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:0];
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:1];
        [_segment setWidth:self.segment.frame.size.width/3 forSegmentAtIndex:2];
//        [_segment setWidth:docWidth forSegmentAtIndex:3];
        if (self.ischange == YES) {
            _segment.selectedSegmentIndex = 1;
        } else {
            _segment.selectedSegmentIndex = 0;
            _shadowView.frame = CGRectMake([self.segment widthForSegmentAtIndex:0]/2 - 12.5, shadowViewY, 25, 3);
        }
        
        /*  如果文档在下，隐藏切换按钮   */
        if (!_isSmallDocView) {
            _playerView.changeButton.hidden = YES;
            _playerView.changeButton.tag = 1;
        }
    } else if (_templateType == 5) {
        //聊天互动： 有 直播文档： 有 直播问答： 有
        CGFloat count = _isSmallDocView ? 3 : 4;
//        CGFloat docWidth = _isSmallDocView ? 0 : self.segment.frame.size.width / count;
        [_segment setWidth:self.segment.frame.size.width/count forSegmentAtIndex:0];
        [_segment setWidth:self.segment.frame.size.width/count forSegmentAtIndex:1];
        [_segment setWidth:self.segment.frame.size.width/count forSegmentAtIndex:2];
//        [_segment setWidth:docWidth forSegmentAtIndex:3];
        if (self.ischange == YES) {
            _segment.selectedSegmentIndex = 1;
        } else {
            _segment.selectedSegmentIndex = 0;
            _shadowView.frame = CGRectMake([self.segment widthForSegmentAtIndex:0]/2 - 12.5, shadowViewY, 25, 3);
        }
        
        /*  如果文档在下,隐藏切换按钮   */
        if (!_isSmallDocView) {
            _playerView.changeButton.hidden = YES;
            _playerView.changeButton.tag = 1;
        }
    }else if(_templateType == 6) {
        //聊天互动： 无 直播文档： 无 直播问答： 有
        _segment.selectedSegmentIndex = 1;
        [_segment setWidth:0.0f forSegmentAtIndex:0];
        [_segment setWidth:self.segment.frame.size.width/2 forSegmentAtIndex:1];
        [_segment setWidth:self.segment.frame.size.width/2 forSegmentAtIndex:2];
//        [_segment setWidth:0.0f forSegmentAtIndex:3];
        _shadowView.frame = CGRectMake([self.segment widthForSegmentAtIndex:0]/2-12.5, shadowViewY, 25, 3);
        int py = _scrollView.contentOffset.y;
        [_scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, py)];
        
        /*    移除文档视图,隐藏切换按钮   */
        [self removeDocView:smallView];
        playerView.changeButton.hidden = YES;
        [playerView.contentView removeFromSuperview];
    }
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

#pragma mark - 懒加载
//创建聊天问答等功能选择
-(UISegmentedControl *)segment {
    if(!_segment) {
        NSArray *segmentedArray = [[NSArray alloc] initWithObjects:@"聊天",@"直播目录",@"讲师介绍", nil];
        _segment = [[UISegmentedControl alloc] initWithItems:segmentedArray];
        //文字设置
        NSMutableDictionary *attDicNormal = [NSMutableDictionary dictionary];
        attDicNormal[NSFontAttributeName] = [UIFont systemFontOfSize:FontSize_30];
        attDicNormal[NSForegroundColorAttributeName] = [UIColor colorWithHexString:@"666666" alpha:1.0f];
        NSMutableDictionary *attDicSelected = [NSMutableDictionary dictionary];
        attDicSelected[NSFontAttributeName] = [UIFont systemFontOfSize:FontSize_30];
        attDicSelected[NSForegroundColorAttributeName] = [UIColor colorWithHexString:@"ff454b" alpha:1.0f];
        [_segment setTitleTextAttributes:attDicNormal forState:UIControlStateNormal];
        [_segment setTitleTextAttributes:attDicSelected forState:UIControlStateSelected];
        _segment.selectedSegmentIndex = 0;
        _segment.backgroundColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
        _segment.layer.cornerRadius = 0.1;
        _segment.clipsToBounds = YES;
        _segment.tintColor = [UIColor colorWithLight:[UIColor whiteColor] Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
        [_segment setBackgroundImage:[self imageWithColor:[UIColor colorWithLight:UIColor.whiteColor Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [_segment setBackgroundImage:[self imageWithColor:[UIColor colorWithLight:UIColor.whiteColor Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]]] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [_segment setBackgroundImage:[self imageWithColor:[UIColor colorWithLight:UIColor.whiteColor Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]]] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [_segment setDividerImage:[self imageWithColor:[UIColor colorWithLight:UIColor.whiteColor Dark:[UIColor colorWithRed:29/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]]] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        _segment.momentary = NO;
        [_segment addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];

    }
    return _segment;
}
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
//创建直播目录
-(CCLiveDirectory *)questionChatView {
    if(!_questionChatView) {
        _questionChatView = [[CCLiveDirectory alloc] init];
        _questionChatView.backgroundColor = [UIColor colorWithLight:[UIColor colorWithHexString:@"F4F4F4" alpha:1.0f] Dark:[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1.0]];
        [_questionChatView.changeButton addTarget:self action:@selector(changeLive:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _questionChatView;
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
        _chatView.backgroundColor = [UIColor colorWithLight:[UIColor colorWithHexString:@"F4F4F4" alpha:1.0f] Dark:[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1.0]];
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
-(UIView *)shadowView {
    if (!_shadowView) {
        _shadowView = [[UIView alloc] init];
        _shadowView.backgroundColor = [UIColor colorWithHexString:@"ff454b" alpha:1.0f];
    }
    return _shadowView;
}
//聊天数组
-(NSMutableArray *)chatArr{
    if (!_chatArr) {
        _chatArr = [NSMutableArray array];
    }
    return _chatArr;
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
