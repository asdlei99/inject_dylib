//
//  LogHelper.m
//  Inject
//
//  Created by zhuanghaishao on 2016/12/21.
//  Copyright © 2016年 ryan. All rights reserved.
//

#import "LogHelper.h"

@implementation LogHelper

static LogHelper *_helper;
+ (instancetype)helper
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = [[self alloc] init];
    });
    return _helper;
}

+ (void)log:(NSString *)log level:(LogLevel)level
{
    LogHelper *helper = [LogHelper helper];
    if (helper.delegate && [helper.delegate respondsToSelector:@selector(didReceivedNewLog:logLevel:)]) {
        [helper.delegate didReceivedNewLog:log logLevel:level];
    }
}

+ (void)logLowLevel:(NSString *)log
{
    [self log:log level:LogLevelLow];
}

+ (void)logHighLevel:(NSString *)log
{
    [self log:log level:LogLevelHigh];
}

@end
