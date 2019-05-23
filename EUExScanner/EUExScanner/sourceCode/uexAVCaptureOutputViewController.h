/**
 *
 *	@file   	: uexZXingScannerViewController.h  in EUExScanner
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 15/12/22.
 *
 *	@copyright 	: 2015 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
 
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger,uexScannerEncodingC){
    uexScannerEncodingCUTF8 = 0,
    uexScannerEncodingCGBK,
};


typedef void (^uexScannerCompletionBlock)(NSString *scanResult,NSString *codeType,BOOL isCancelled);


@interface uexAVCaptureOutputViewController : UIViewController
@property (nonatomic,strong)UIImage *lineImage;
@property (nonatomic,strong)UIImage *backgroundScanImage;
@property (nonatomic,strong)NSString *scannerTitle;
@property (nonatomic,strong)NSString *scannerPrompt;
@property (nonatomic,strong)uexScannerCompletionBlock completion;
@property (nonatomic,assign)uexScannerEncodingC charset;
@property (nonatomic,strong)UIImageView *lineView;
@property (nonatomic,assign)float frequency;
@property (nonatomic,assign) BOOL ShowPicker; // No 不显示 YES 显示 是否显示相册


//AVCaptureOutput
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (strong,nonatomic)AVCaptureDeviceInput *input;
@property (strong,nonatomic)AVCaptureDevice *device;
@property (strong,nonatomic)AVCaptureMetadataOutput *output;


- (instancetype)initWithCompletion:(uexScannerCompletionBlock)completion;
@end
