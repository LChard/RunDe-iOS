//
//  Utility.m
//  TextUtil
//
//  Created by zx_04 on 15/8/20.
//  Copyright (c) 2015年 joker. All rights reserved.
//

#import "Utility.h"
#import <SDWebImagePrefetcher.h>

@implementation Utility
/**
 *  将带有表情符的文字转换为图文混排的文字
 *
 *  @param text      带表情符的文字
 *  @param y         图片的y偏移值
 *
 *  @return 转换后的文字
 */
+ (NSMutableAttributedString *)emotionStrWithString:(NSString *)text y:(CGFloat)y
{
    //1、创建一个可变的属性字符串
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text];
    //2、通过正则表达式来匹配字符串
    NSString *regex_emoji = @"\\[em2_[0-9]*\\]"; //匹配表情
    
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:regex_emoji options:NSRegularExpressionCaseInsensitive error:&error];
    if (!re) {
//        NSLog(@"%@", [error localizedDescription]);
        return attributeString;
    }
    
    NSArray *resultArray = [re matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    //3、获取所有的表情以及位置
    //用来存放字典，字典中存储的是图片和图片对应的位置
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:resultArray.count];
    //根据匹配范围来用图片进行相应的替换
    for(NSTextCheckingResult *match in resultArray) {
        //获取数组元素中得到range
        NSRange range = [match range];
        //获取原字符串中对应的值
        NSString *subStr = [text substringWithRange:range];
        if (subStr.length>8) {
            for (int i = 201; i <= 300; i ++) {
                NSString *str = [NSString stringWithFormat:@"[em2_%03d]",i];
                //            NSLog(@"str = %@",str);
                
                if ([str isEqualToString:subStr]) {
                    //face[i][@"png"]就是我们要加载的图片
                    //新建文字附件来存放我们的图片,iOS7才新加的对象
                    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                    //给附件添加图片
                    NSString *pic = [NSString stringWithFormat:@"%03d",i];
                    textAttachment.image = [UIImage imageNamed:pic];
                    //调整一下图片的位置,如果你的图片偏上或者偏下，调整一下bounds的y值即可
                    textAttachment.bounds = CGRectMake(0, y, textAttachment.image.size.width, textAttachment.image.size.height);
                    //把附件转换成可变字符串，用于替换掉源字符串中的表情文字
                    NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:textAttachment];
                    //把图片和图片对应的位置存入字典中
                    NSMutableDictionary *imageDic = [NSMutableDictionary dictionaryWithCapacity:2];
                    [imageDic setObject:imageStr forKey:@"image"];
                    [imageDic setObject:[NSValue valueWithRange:range] forKey:@"range"];
                    //把字典存入数组中
                    [imageArray addObject:imageDic];
                }
            }
        } else {
            
            for (int i = 1; i <= 21; i ++) {
                NSString *str = [NSString stringWithFormat:@"[em2_%02d]",i];
                //            NSLog(@"str = %@",str);
                
                if ([str isEqualToString:subStr]) {
                    //face[i][@"png"]就是我们要加载的图片
                    //新建文字附件来存放我们的图片,iOS7才新加的对象
                    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                    //给附件添加图片
                    NSString *pic = [NSString stringWithFormat:@"%03d",i];
                    textAttachment.image = [UIImage imageNamed:pic];

                    if ([pic isEqualToString:@"021"]) {
                        //调整一下图片的位置,如果你的图片偏上或者偏下，调整一下bounds的y值即可
                        textAttachment.bounds = CGRectMake(0, y+4, textAttachment.image.size.width, textAttachment.image.size.height);
                    } else {
                        //调整一下图片的位置,如果你的图片偏上或者偏下，调整一下bounds的y值即可
                        textAttachment.bounds = CGRectMake(0, y, textAttachment.image.size.width, textAttachment.image.size.height);
                    }
                    //把附件转换成可变字符串，用于替换掉源字符串中的表情文字
                    NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:textAttachment];
                    //把图片和图片对应的位置存入字典中
                    NSMutableDictionary *imageDic = [NSMutableDictionary dictionaryWithCapacity:2];
                    [imageDic setObject:imageStr forKey:@"image"];
                    [imageDic setObject:[NSValue valueWithRange:range] forKey:@"range"];
                    //把字典存入数组中
                    [imageArray addObject:imageDic];
                }
            }
        }
    }
    
    //4、从后往前替换，否则会引起位置问题
    for (int i = (int)imageArray.count -1; i >= 0; i--) {
        NSRange range;
        [imageArray[i][@"range"] getValue:&range];
        //进行替换
        [attributeString replaceCharactersInRange:range withAttributedString:imageArray[i][@"image"]];
    }
    return attributeString;
}

//+ (NSMutableAttributedString *)exchangeString:(NSString *)string withText:(NSString *)text imageName:(NSString *)imageName
+ (NSMutableAttributedString *)exchangeString:(NSString *)string withText:(NSString *)text imageName:(NSString *)imageName RefreshCell:(void (^)(void))refreshCell
{
    //1、创建一个可变的属性字符串
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text];
    
    //2、匹配字符串
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:string options:NSRegularExpressionCaseInsensitive error:&error];
    if (!re) {
//        NSLog(@"%@", [error localizedDescription]);
        return attributeString;
    }
    
    NSArray *resultArray = [re matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    //3、获取所有的图片以及位置
    //用来存放字典，字典中存储的是图片和图片对应的位置
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:resultArray.count];
    //根据匹配范围来用图片进行相应的替换
    for(NSTextCheckingResult *match in resultArray) {
        //获取数组元素中得到range
        NSRange range = [match range];
        //新建文字附件来存放我们的图片(iOS7才新加的对象)
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        //给附件添加图片
        
        if (imageName.length >10 && ![imageName containsString:@"live_call_"]) {
            
            NSURL *url = [NSURL URLWithString:imageName];
            NSString * imageKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
            UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:imageKey];
            if (!image) {
                
//                [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[url] progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
//
//                } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
//                    if (refreshCell) {
//                        refreshCell();
//                    }
//                }];
                [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
//                    NSLog(@"显示当前进度");
                } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                    NSLog(@"下载完成");
                    if (!error && refreshCell) {
                         refreshCell();
                    }
                }];
                image = [UIImage imageNamed:@"tool_bar_gift.png"];

            }
            textAttachment.image = image;
            textAttachment.bounds = CGRectMake(0, -10, 30, 30);
            
//            NSURL *url = [NSURL URLWithString:imageName];
//            NSData *imageData = [NSData dataWithContentsOfURL:url];
//            textAttachment.image = [UIImage imageWithData: imageData];
//            textAttachment.bounds = CGRectMake(0, -10, 30, 30);
        } else {
            textAttachment.image = [UIImage imageNamed:imageName];
            textAttachment.bounds = CGRectMake(0, -6, textAttachment.image.size.width, textAttachment.image.size.height);
        }
        //修改一下图片的位置,y为负值，表示向下移动
        //        textAttachment.bounds = CGRectMake(0, -2, textAttachment.image.size.width, textAttachment.image.size.height);
        
        
        //把附件转换成可变字符串，用于替换掉源字符串中的表情文字
        NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:textAttachment];
        //把图片和图片对应的位置存入字典中
        NSMutableDictionary *imageDic = [NSMutableDictionary dictionaryWithCapacity:2];
        [imageDic setObject:imageStr forKey:@"image"];
        [imageDic setObject:[NSValue valueWithRange:range] forKey:@"range"];
        //把字典存入数组中
        [imageArray addObject:imageDic];
    }
    
    //4、从后往前替换，否则会引起位置问题
    for (int i = (int)imageArray.count -1; i >= 0; i--) {
        NSRange range;
        [imageArray[i][@"range"] getValue:&range];
        //进行替换
        [attributeString replaceCharactersInRange:range withAttributedString:imageArray[i][@"image"]];
    }
    
    return attributeString;
}

@end
