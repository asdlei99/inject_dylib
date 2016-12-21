//
//  LogHelper.h
//  Inject
//
//  Created by zhuanghaishao on 2016/12/21.
//  Copyright © 2016年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelLow,
    LogLevelHigh
};

@protocol LogHelperDelegate <NSObject>

- (void)didReceivedNewLog:(NSString *)log logLevel:(LogLevel)logLevel;

@end

@interface LogHelper : NSObject

@property (nonatomic, weak) id<LogHelperDelegate>delegate;

+ (instancetype)helper;

+ (void)logLowLevel:(NSString *)log;

+ (void)logHighLevel:(NSString *)log;

@end
