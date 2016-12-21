//
//  ViewController.m
//  Inject
//
//  Created by zhuanghaishao on 2016/12/19.
//  Copyright © 2016年 ryan. All rights reserved.
//

#import "ViewController.h"
#import "ReSignHelper.h"
#import "UserDefault.h"
#import "Insert_dylib.h"
#import "LogHelper.h"

@interface ViewController ()<NSComboBoxDataSource, NSComboBoxDelegate, LogHelperDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *inputPathField;
@property (nonatomic, weak) IBOutlet NSTextField *ouputPathField;
@property (nonatomic, weak) IBOutlet NSTextField *profilePathField;
@property (nonatomic, weak) IBOutlet NSComboBox *certificateComboBox;
@property (nonatomic, weak) IBOutlet NSTextField *dylibPathField;
@property (nonatomic, weak) IBOutlet NSButton *checkBoxButton;
@property (nonatomic, weak) IBOutlet NSTextView *textView;
@property (nonatomic, strong) NSArray *certificates;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[LogHelper helper] setDelegate:self];
    [self initView];
}

- (void)initView
{
    self.inputPathField.stringValue = [UserDefault userDefault].inputPath;
    self.ouputPathField.stringValue = [UserDefault userDefault].outPath;
    self.profilePathField.stringValue = [UserDefault userDefault].provisionPath;
    self.dylibPathField.stringValue = [UserDefault userDefault].dylibPath;
    self.certificates = [ReSignHelper getCertificates];
    [self.certificateComboBox reloadData];
    NSInteger index = [self.certificates indexOfObject:[UserDefault userDefault].certificationName];
    if (index != NSNotFound) {
        [self.certificateComboBox selectItemAtIndex:index];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

#pragma mark - action
- (IBAction)chooseInputPath:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setTitle:self.inputPathField.placeholderString];
    [panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[@"app"]];
    NSInteger index = [panel runModal];
    if (index == NSModalResponseOK) {
        NSURL *fileURL = [panel URL];
        _inputPathField.stringValue = fileURL.relativePath;
        [UserDefault userDefault].inputPath = fileURL.relativePath;
    }
}

- (IBAction)chooseOutputPath:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setTitle:self.ouputPathField.placeholderString];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    NSInteger index = [panel runModal];
    if (index == NSModalResponseOK) {
        NSURL *fileURL = [panel URL];
        self.ouputPathField.stringValue = fileURL.relativePath;
        [UserDefault userDefault].outPath = fileURL.relativePath;
    }
}

- (IBAction)chooseProvisingPath:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setTitle:self.profilePathField.placeholderString];
    [panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[@"mobileprovision", @"MOBILEPROVISION"]];
    NSInteger index = [panel runModal];
    if (index == NSModalResponseOK) {
        NSURL *fileURL = [panel URL];
        self.profilePathField.stringValue = fileURL.relativePath;
        [UserDefault userDefault].provisionPath = fileURL.relativePath;
    }
}

- (IBAction)chooseDylibPath:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setTitle:self.profilePathField.placeholderString];
    [panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[@"dylib"]];
    NSInteger index = [panel runModal];
    if (index == NSModalResponseOK) {
        NSURL *fileURL = [panel URL];
        self.dylibPathField.stringValue = fileURL.relativePath;
        [UserDefault userDefault].dylibPath = fileURL.relativePath;
    }
}

- (IBAction)startAction:(id)sender
{
    self.textView.string = @"";
    if ([self validateParams]) {
        NSURL *inputURL =  [NSURL fileURLWithPath:self.inputPathField.stringValue];
        NSString *dylibName = nil;
        NSString *appName = inputURL.lastPathComponent;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tmpPayload = [self.ouputPathField.stringValue stringByAppendingPathComponent:@"tmpPayload"];
        if ([fileManager fileExistsAtPath:tmpPayload]) {
            [fileManager removeItemAtPath:tmpPayload error:nil];
        }
        NSError *error = nil;
        //create tmpPayload
        [fileManager createDirectoryAtPath:tmpPayload withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            [LogHelper logHighLevel:error.description];
            return;
        }
        //copy app
        NSString *dstPath = [tmpPayload stringByAppendingPathComponent:appName];
        [fileManager copyItemAtPath:self.inputPathField.stringValue toPath:dstPath error:&error];
        if (error) {
            [LogHelper logHighLevel:error.description];
            return;
        }
        if (self.checkBoxButton.state == NSOnState) {
            [Insert_dylib inject:self.dylibPathField.stringValue appPath:dstPath];
            dylibName = [[NSURL URLWithString:self.dylibPathField.stringValue]
                         URLByDeletingPathExtension].lastPathComponent;
        }
        //resign
        [ReSignHelper startRecodeSign:dstPath
                              outPath:self.ouputPathField.stringValue
                        provisionPath:self.profilePathField.stringValue
                      certificateName:self.certificateComboBox.stringValue
                            dylibName:dylibName
                             callBack:^(NSError *error) {
                                 if (error) {
                                     [LogHelper logLowLevel:@"Resign Fail"];
                                 } else {
                                     [LogHelper logLowLevel:@"Resign Success"];
                                 }
                                 [fileManager removeItemAtPath:tmpPayload error:nil];
                             }];
    }
}

- (BOOL)validateParams
{
    if (self.checkBoxButton.state == NSOnState
        && self.dylibPathField.stringValue.length == 0) {
        [LogHelper logHighLevel:@"please choose dylib path"];
        return NO;
    }
    if (self.inputPathField.stringValue.length == 0) {
        [LogHelper logHighLevel:@"please choose app path"];
        return NO;
    }
    if (self.ouputPathField.stringValue.length == 0) {
        [LogHelper logHighLevel:@"please choose ipa output path"];
        return NO;
    }
    if (self.profilePathField.stringValue.length == 0) {
        [LogHelper logHighLevel:@"please choose profile path"];
        return NO;
    }
    return YES;
}

#pragma mark - NSComboBox delegate
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return self.certificates.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return self.certificates[index];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    NSComboBox *comboBox = notification.object;
    NSInteger index = [comboBox indexOfSelectedItem];
    [UserDefault userDefault].certificationName = self.certificates[index];
}

#pragma mark - log
- (void)didReceivedNewLog:(NSString *)log logLevel:(LogLevel)logLevel
{
    self.textView.string = [NSString stringWithFormat:@"%@\n%@",self.textView.string,log];
}
@end
