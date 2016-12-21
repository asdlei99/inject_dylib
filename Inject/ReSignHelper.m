//
//  ReCodeSignHelper.m
//  ReCodeSign
//
//  Created by ryan on 15/12/18.
//  Copyright © 2015年 ryan. All rights reserved.
//

#import "ReSignHelper.h"
#import "UserDefault.h"
#import "LogHelper.h"

NSString *const kNotificationLogComing = @"logComming";

@interface ReSignHelper ()

@property (nonatomic, copy) SignCompletedBlock block;
@property (nonatomic, strong) NSTask *task;
@property (nonatomic, strong) NSTask *shellTask;
@property (nonatomic, strong) NSTask *codeSignTask;

@end

@implementation ReSignHelper

NSString *const kResignShellName = @"resign";
NSString *const kResourceRulesName = @"ResourceRules";

+ (void)startReCodeSign:(SignCompletedBlock)block
{
    ReSignHelper *helper = [[ReSignHelper alloc] init];
    helper.block = block;
    [helper start];
}

+ (void)startRecodeSign:(NSString *)inputPath outPath:(NSString *)outPath provisionPath:(NSString *)provisionPath certificateName:(NSString *)certificateName dylibName:(NSString *)dylibName callBack:(SignCompletedBlock)block
{
    ReSignHelper *helper = [[ReSignHelper alloc] init];
    helper.inputPath = inputPath;
    helper.outPath = outPath;
    helper.provisionPath = provisionPath;
    helper.certificateName = certificateName;
    helper.dylibName = dylibName;
    helper.block = block;
    [helper start];
}

+ (NSArray *)getCertificates
{
    NSTask *getCerTask = [[NSTask alloc] init];
    NSPipe *pie = [NSPipe pipe];
    [getCerTask setLaunchPath:@"/usr/bin/security"];
    [getCerTask setArguments:@[@"find-identity", @"-v", @"-p", @"codesigning"]];
    [getCerTask setStandardOutput:pie];
    [getCerTask setStandardError:pie];
    [getCerTask launch];
    [getCerTask waitUntilExit];
    
    NSFileHandle *fileHandle = [pie fileHandleForReading];
    NSString *securityResult = [[NSString alloc] initWithData:[fileHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    // Verify the security result
    NSMutableArray *tempGetCertsResult = [NSMutableArray arrayWithCapacity:20];
    if (securityResult && securityResult.length > 0) {
        NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
        for (int i = 0; i <= [rawResult count] - 2; i+=2) {
            if (rawResult.count - 1 < i + 1) {
                // Invalid array, don't add an object to that position
            } else {
                // Valid object
                [tempGetCertsResult addObject:[rawResult objectAtIndex:i+1]];
            }
        }
    }
    return tempGetCertsResult;
}

- (void)start
{
    NSString *inputFile = self.inputPath;
    NSString *payloadPath = [self.outPath stringByAppendingPathComponent:@"Payload"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([manager fileExistsAtPath:payloadPath isDirectory:&isDirectory]) {
        [manager removeItemAtPath:payloadPath error:nil];
    }
    [manager createDirectoryAtPath:payloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    [self.task setLaunchPath:@"/bin/cp"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-r", inputFile, payloadPath, nil];
    [self.task setArguments:arguments];
    [self.task launch];
    [self.task waitUntilExit];
    [self initShell];
    [self codeSign];
    [self clean];
    if (_block) {
        _block(nil);
    }
}

- (void)codeSign
{
    NSString *resourceRulesArgument = [[NSBundle mainBundle] pathForResource:kResourceRulesName
                                                                      ofType:@"plist"];
    [self.codeSignTask setLaunchPath:@"/bin/sh"];
    NSMutableArray *arguments = @[[self resignShellPath],
                                  self.inputPath,
                                  self.outPath,
                                  self.provisionPath,
                                  self.certificateName,
                                  [self appName],
                                  resourceRulesArgument].mutableCopy;
    if (self.dylibName) {
        [arguments addObject:self.dylibName];
    }
    [self.codeSignTask setArguments:arguments];
    [self.codeSignTask setCurrentDirectoryPath:self.outPath];
    NSPipe *pie = [NSPipe pipe];
    [self.codeSignTask setStandardError:pie];
    [self.codeSignTask setStandardOutput:pie];
    [self.codeSignTask launch];
    [self.codeSignTask waitUntilExit];
    
    NSFileHandle *fileHandel = [pie fileHandleForReading];
    NSString *log = [[NSString alloc] initWithData:[fileHandel readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    [LogHelper logLowLevel:log];
}

- (void)clean
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self resignShellPath]]) {
        [fileManager removeItemAtPath:[self resignShellPath] error:nil];
    }
}

- (NSString *)appName
{
    NSURL *URL = [[NSURL URLWithString:self.inputPath] URLByDeletingPathExtension];
    return URL.lastPathComponent;
}

- (void)initShell
{
    NSString *shellPath = [[NSBundle mainBundle] pathForResource:kResignShellName
                                                          ofType:@"strings"];
    NSStringEncoding encoding;
    NSString *shellContent = [NSString stringWithContentsOfFile:shellPath usedEncoding:&encoding error:nil];
    NSString *shellOutputPath = [self resignShellPath];
    if (shellContent) {
        [[NSFileManager defaultManager] createFileAtPath:shellContent contents:nil attributes:nil];
        [shellContent writeToFile:shellOutputPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    [self.shellTask setLaunchPath:@"/bin/chmod"];
    [self.shellTask setArguments:@[@"+x",shellOutputPath]];
    [self.shellTask launch];
    [self.shellTask waitUntilExit];
}

- (void)alertError:(NSString *)error
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:error];
    [alert runModal];
}

#pragma mark - setter & getter
- (NSTask *)task
{
    if (_task == nil) {
        _task = [[NSTask alloc] init];
    }
    return _task;
}

- (NSTask *)shellTask
{
    if (_shellTask == nil) {
        _shellTask = [[NSTask alloc] init];
    }
    return _shellTask;
}

- (NSTask *)codeSignTask
{
    if (_codeSignTask == nil) {
        _codeSignTask = [[NSTask alloc] init];
    }
    return _codeSignTask;
}

- (NSString *)resignShellPath
{
    return [self.outPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sh",kResignShellName]];
}

@end
