//
//  EUExScanner.m
//  EUExScanner
//
//  Created by liguofu on 15/3/17.
//  Copyright (c) 2015年 AppCan.can. All rights reserved.
//

#import "EUExScanner.h"

#import <Foundation/Foundation.h>
#import "uexAVCaptureOutputViewController.h"
#import "uexZXingScannerViewController.h"



#define UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(x) (self.jsonDict[x] && [self.jsonDict[x] isKindOfClass:[NSString class]])

@interface EUExScanner()
@property (nonatomic,strong)NSDictionary *jsonDict;
@end

@implementation EUExScanner




- (void)open:(NSMutableArray *)inArguments {

    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);

    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (authStatus) {
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:{
            ACLogInfo(@"uexScanner: 相机权限受限");
            
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexScanner.cbOpen" arguments:ACArgsPack(@1,@1,@0)];
            [func executeWithArguments:ACArgsPack(@(1),@"")];
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                if(granted==NO){
                    [self.webViewEngine callbackWithFunctionKeyPath:@"uexScanner.cbOpen" arguments:ACArgsPack(@1,@1,@0)];
                    [func executeWithArguments:ACArgsPack(@(1),@"")];
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self openCameraWithFunction:func];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            [self openCameraWithFunction:func];
            break;
        }

    }

}

-(void)openCameraWithFunction:(ACJSFunctionRef *)func{

    
    UIStatusBarStyle initialStatusBarStyle =[UIApplication sharedApplication].statusBarStyle;
    float phoneVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(phoneVersion<8.0){
        uexZXingScannerViewController *scanner=[[uexZXingScannerViewController alloc]initWithCompletion:^(NSString *scanResult, NSString *codeType, BOOL isCancelled) {
            [[UIApplication sharedApplication]setStatusBarStyle:initialStatusBarStyle];
            if(isCancelled){
                return;
            }
            
            NSMutableDictionary *result=[NSMutableDictionary dictionary];
            [result setValue:scanResult forKey:@"code"];
            [result setValue:codeType forKey:@"type"];


            [self.webViewEngine callbackWithFunctionKeyPath:@"uexScanner.cbOpen" arguments:ACArgsPack(@0,@1,[result ac_JSONFragment])];
            [func executeWithArguments:ACArgsPack(@(0),result)];
        }];
        
        
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"title")){
            scanner.scannerTitle=self.jsonDict[@"title"];
        }
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"tipLabel") ){
            scanner.scannerPrompt=self.jsonDict[@"tipLabel"];
        }
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"lineImg")){
            scanner.lineImage=[self getImageByPath:self.jsonDict[@"lineImg"]];
        }
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"pickBgImg")){
            scanner.backgroundScanImage=[self getImageByPath:self.jsonDict[@"pickBgImg"]];
        }
        if (UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"charset")){
            NSString *charsetStr = [self.jsonDict[@"charset"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
            if ([charsetStr isEqual:@"gbk"]) {
                scanner.charset = uexScannerEncodingCharsetGBK;
            }
        }
        if([self.jsonDict objectForKey:@"frequency"]){
            scanner.frequency=[[self.jsonDict objectForKey:@"frequency"] floatValue];
        }
        else{
            scanner.frequency=1.5;
        }
        

         [[self.webViewEngine viewController] presentViewController:scanner animated:YES completion:nil];
    }
    else{
        uexAVCaptureOutputViewController *scanner=[[uexAVCaptureOutputViewController alloc]initWithCompletion:^(NSString *scanResult, NSString *codeType, BOOL isCancelled) {
            [[UIApplication sharedApplication]setStatusBarStyle:initialStatusBarStyle];
            if(isCancelled){
                return;
            }
            
            NSMutableDictionary *result=[NSMutableDictionary dictionary];
            [result setValue:scanResult forKey:@"code"];
            [result setValue:codeType forKey:@"type"];

            [self.webViewEngine callbackWithFunctionKeyPath:@"uexScanner.cbOpen" arguments:ACArgsPack(@0,@1,[result ac_JSONFragment])];
            [func executeWithArguments:ACArgsPack(@(0),result)];

        }];
        
        
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"title")){
            scanner.scannerTitle=self.jsonDict[@"title"];
        }
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"tipLabel") ){
            scanner.scannerPrompt=self.jsonDict[@"tipLabel"];
        }
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"lineImg")){
            scanner.lineImage=[self getImageByPath:self.jsonDict[@"lineImg"]];
        }
        if(UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"pickBgImg")){
            scanner.backgroundScanImage=[self getImageByPath:self.jsonDict[@"pickBgImg"]];
        }
        if (UEX_SCANNER_AVAILABLE_STRING_FOR_KEY(@"charset")){
            NSString *charsetStr = [self.jsonDict[@"charset"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
            if ([charsetStr isEqual:@"gbk"]) {
                scanner.charset = uexScannerEncodingCGBK;
            }
        }
        if([self.jsonDict objectForKey:@"frequency"]){
            scanner.frequency = [[self.jsonDict objectForKey:@"frequency"] floatValue];
        }
        else{
            scanner.frequency = 1.5;
        }
        if([self.jsonDict objectForKey:@"isGallery"]){
            scanner.ShowPicker = [[self.jsonDict objectForKey:@"isGallery"] boolValue];
        }
        else{
            scanner.ShowPicker = YES; //默认显示相册按钮
        }
        
        [[self.webViewEngine viewController] presentViewController:scanner animated:YES completion:nil];

    }
}

- (void)setJsonData:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary*info) = inArguments;
    self.jsonDict=info;
}


- (NSString *)recognizeFromImage:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *imagePath) = inArguments;

    UIImage *image = nil;
    if ([imagePath hasPrefix:@"https"] || [imagePath hasPrefix:@"http"]) {
        NSURL *url = [NSURL URLWithString:imagePath];
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    } else {
        image = [UIImage imageWithContentsOfFile:[self absPath:imagePath]];
    }
    if (!image) {
        return nil;
    }
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (!features || features.count<1) {
        return nil;
    }
    NSMutableArray *resultArr = [NSMutableArray array];
    for (int index = 0; index < [features count]; index ++) {
        CIQRCodeFeature *feature = [features objectAtIndex:index];
        NSString *scannedResult = feature.messageString;
        [resultArr addObject:scannedResult];
        
    }
    return resultArr.firstObject;
}

- (UIImage *)getImageByPath:(NSString *)path {
    NSString *imagePath =[self absPath:path];
    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
    return [UIImage imageWithData:imageData];
}


- (void)clean {
    
    self.jsonDict=nil;
}

@end
