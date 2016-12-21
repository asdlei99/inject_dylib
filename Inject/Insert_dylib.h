//
//  Insert_dylib.h
//  Inject
//
//  Created by zhuanghaishao on 2016/12/19.
//  Copyright © 2016年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Insert_dylib : NSObject

+ (void)inject:(NSString *)dylibPath appPath:(NSString *)appPath;

@end
