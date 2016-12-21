//
//  ReCodeSignHelper.h
//  ReCodeSign
//
//  Created by ryan on 15/12/18.
//  Copyright © 2015年 ryan. All rights reserved.
//

#import <AppKit/AppKit.h>

typedef void (^SignCompletedBlock) (NSError *error);

@interface ReSignHelper : NSObject

@property (nonatomic, copy) NSString *inputPath;
@property (nonatomic, copy) NSString *outPath;
@property (nonatomic, copy) NSString *provisionPath;
@property (nonatomic, copy) NSString *certificateName;
@property (nonatomic, copy) NSString *dylibName;

//+ (void)startReCodeSign:(SignCompletedBlock)block;

+ (void)startRecodeSign:(NSString *)inputPath
                outPath:(NSString *)outPath
          provisionPath:(NSString *)provisionPath
        certificateName:(NSString *)certificateName
              dylibName:(NSString *)dylibName
               callBack:(SignCompletedBlock)block;

+ (NSArray *)getCertificates;

@end
