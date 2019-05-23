/**
 *
 *	@file   	: uexZXingScannerViewController.m  in EUExScanner
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

#import "uexAVCaptureOutputViewController.h"
#import <ZXingObjC/ZXingObjC.h>
#import <AppCanKit/AppCanKit.h>
@interface uexAVCaptureOutputViewController()<ZXCaptureDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic,strong)ZXCapture *ZXingCapture;

@end

//#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
//#define SCREEN_HEIGHT  ([UIScreen mainScreen].bounds.size.height)
#define SCREEN_WIDTH (self.view.bounds.size.width)
#define SCREEN_HEIGHT  (self.view.bounds.size.height)


static CGFloat kUexScannerTopToolbarHeitght                 = 50;
static CGFloat kUexScannerBottomToolbarHeitght              = 50;
static CGFloat kUexScannerCaptureWidth                      = 220;
static CGFloat kUexScannerCaptureHeight                     = 220;
static CGFloat kUexScannerPromptVerticalDistanceFromCapture = 10;
static CGFloat kUexScannerPromptMaxWidth                    = 300;


@implementation uexAVCaptureOutputViewController

#pragma mark - Life Cycle

- (instancetype)initWithCompletion:(uexScannerCompletionBlock)completion
{
    self = [super init];
    if (self) {
        [self initializer];
        self.completion=completion;
    }
    return self;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializer];
    }
    return self;
}

- (void)initializer{
    _scannerTitle = @"扫一扫";
    _scannerPrompt = @"对准二维码/条形码,即可自动扫描";
    _backgroundScanImage = [self bundleImageForName:@"pick_bg"];
    _lineImage = [self bundleImageForName:@"line"];
    ZXCapture *capture = [[ZXCapture alloc] init];
    capture.camera = capture.back;
    capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    capture.rotation = 90.0f;
    capture.layer.frame = self.view.bounds;
    

    self.ZXingCapture = capture;

    
}

- (void)viewDidLoad{

    [super viewDidLoad];


}


- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    self.view.backgroundColor=[UIColor whiteColor];
    
    //适配屏幕小一点的设备
    if(SCREEN_HEIGHT<375 || SCREEN_WIDTH<375){
        kUexScannerCaptureWidth=180;
        kUexScannerCaptureHeight=180;
    }
    self.ZXingCapture.hints = [self decodeHints];
    //self.ZXingCapture.delegate = self;
    
//    self.ZXingCapture.layer.frame = self.view.frame;
//    [self.view.layer addSublayer:self.ZXingCapture.layer];
//    self.ZXingCapture.layer.frame = self.view.bounds;
    
    if(!self.preview){
        [self loadAVCaptureOutput];
        [self addShadow];
        [self addCaptureView];
        [self addTopToolbar];
        [self addBottomToolbar];
        [self addPromptLabel];
        
    }
    

    [self applyOrientation];
}

- (void)dealloc{
    [_ZXingCapture.layer removeFromSuperlayer];
    _ZXingCapture = nil;
    
    [self.preview removeFromSuperlayer];
    self.preview=nil;
}

#pragma mark - StatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Rotate


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self applyOrientation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self applyOrientation];
     }];
}

#pragma mark - Scanner UI


- (void)addShadow{
    CALayer *shadowLayer = [CALayer layer];
    shadowLayer.frame = self.view.frame;
    shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
    shadowLayer.opacity = 0.3;
    [self.view.layer addSublayer:shadowLayer];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:[self captureRect]];
    [maskPath appendPath:[UIBezierPath bezierPathWithRect:self.view.frame]];
    maskLayer.path = maskPath.CGPath;
    maskLayer.fillRule=kCAFillRuleEvenOdd;
    shadowLayer.mask=maskLayer;
}


- (void)addCaptureView{
    UIImageView *captureView=[[UIImageView alloc]initWithImage:self.backgroundScanImage];
    captureView.frame=[self captureRect];
    
    //lineView
    self.lineView=[[UIImageView alloc] initWithImage:self.lineImage];
    [self.lineView setFrame:CGRectMake(10, 0, kUexScannerCaptureWidth-20, 2)];
    CAKeyframeAnimation *move=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    CGMutablePathRef path=CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, kUexScannerCaptureWidth/2, 0);
    CGPathAddLineToPoint(path, NULL, kUexScannerCaptureWidth/2, kUexScannerCaptureHeight);
    move.path=path;
    CFRelease(path);
    //足够大
    move.repeatCount=100000;
    move.duration=self.frequency;
    move.autoreverses=YES;
    move.removedOnCompletion=NO;
    [captureView addSubview:self.lineView];
    [self.lineView.layer addAnimation:move forKey:@"move"];
    
    //这个动画有必要么？
    /*
    //animation
    UIImageView *imageUp = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-kUexScannerCaptureWidth/2, SCREEN_HEIGHT/2-kUexScannerCaptureHeight/2, kUexScannerCaptureWidth, kUexScannerCaptureHeight/2)];
    imageUp.image =[self bundleImageForName:@"up"];
    [captureView addSubview:imageUp];
    
    UIImageView *imageDown = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-kUexScannerCaptureWidth/2, SCREEN_HEIGHT/2, kUexScannerCaptureWidth, kUexScannerCaptureHeight/2)];
    imageDown.image =[self bundleImageForName:@"down"];
    [captureView addSubview:imageDown];
    
    //up
    CABasicAnimation *translationUp = [CABasicAnimation animationWithKeyPath:@"position"];
    translationUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    translationUp.toValue = [NSValue valueWithCGPoint:CGPointMake(SCREEN_WIDTH/2, -100)];
    translationUp.duration =0.5;
    translationUp.repeatCount = 1;
    translationUp.fillMode = kCAFillModeForwards;
    translationUp.removedOnCompletion = YES;

    //down
    CABasicAnimation *translationDown = [CABasicAnimation animationWithKeyPath:@"position"];
    translationDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    translationDown.toValue = [NSValue valueWithCGPoint:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT)];
    translationDown.duration = 0.5;
    translationDown.fillMode = kCAFillModeForwards;
    translationDown.removedOnCompletion = YES;

    [imageUp.layer addAnimation:translationUp forKey:nil];
    [imageDown.layer addAnimation:translationDown forKey:nil];
    */
    [self.view addSubview:captureView];
}


- (void)addTopToolbar{
    UIToolbar *statusBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0, SCREEN_WIDTH, 20)];
    [statusBar setBarStyle:UIBarStyleBlack];
    statusBar.clipsToBounds = YES;
    
    UIToolbar *topToolbar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, kUexScannerTopToolbarHeitght)];
    UIBarButtonItem *titleItem=[[UIBarButtonItem alloc]initWithTitle:self.scannerTitle style:UIBarButtonItemStylePlain target:nil action:nil];
    titleItem.tintColor=[UIColor whiteColor];
    [topToolbar setItems:@[[self toolbarItemWithImageName:@"ocrBack" action:@selector(cancelButtonClicked:)],
                           [self flexibleSpaceItem],
                           titleItem,
                           [self flexibleSpaceItem]]];
    [topToolbar setBarStyle:UIBarStyleBlack];
    [topToolbar setTintColor:[UIColor whiteColor]];
    topToolbar.clipsToBounds = YES; 
    //[topToolbar setTranslucent:NO];
    [self.view addSubview:statusBar];
    [self.view addSubview:topToolbar];
}

- (void)addBottomToolbar{
    UIToolbar *bottomToolbar=[[UIToolbar alloc] initWithFrame:CGRectMake(0,SCREEN_HEIGHT-kUexScannerBottomToolbarHeitght, SCREEN_WIDTH, kUexScannerBottomToolbarHeitght)];
    [bottomToolbar setBarStyle:UIBarStyleBlack];
    [bottomToolbar setTintColor:[UIColor whiteColor]];
    //[bottomToolbar setTranslucent:NO];
    if (_ShowPicker) { //yes 显示
        [bottomToolbar setItems:@[[self toolbarItemWithImageName:@"ocr_flash-off" action:@selector(lightButtonClicked:)],
                                  [self flexibleSpaceItem],
                                  [self toolbarItemWithImageName:@"ocr_albums" action:@selector(albumButtonClicked:)]]];
    }else{  //no 显示
        [bottomToolbar setItems:@[[self toolbarItemWithImageName:@"ocr_flash-off" action:@selector(lightButtonClicked:)],
                                  [self flexibleSpaceItem]]];
    }
    
    [self.view addSubview:bottomToolbar];
}

-  (void)addPromptLabel{
    UILabel *promptLabel=[[UILabel alloc] init];
//CGRectMake(SCREEN_WIDTH*0.5-kUexScannerCaptureWidth*0.5, SCREEN_HEIGHT*.5+kUexScannerCaptureHeight*0.5+kUexScannerPromptVerticalMargin, kUexScannerCaptureWidth, 0)];
    promptLabel.numberOfLines=0;
    promptLabel.text=self.scannerPrompt;
    promptLabel.lineBreakMode=NSLineBreakByWordWrapping;
    promptLabel.textColor=[UIColor whiteColor];
    UIFont *promptFont=[UIFont systemFontOfSize:14];
    promptLabel.font=promptFont;

    CGRect promptRect=[self.scannerPrompt boundingRectWithSize:CGSizeMake(kUexScannerPromptMaxWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:promptFont}
                                                       context:nil];
    [promptLabel setFrame:CGRectMake(SCREEN_WIDTH*0.5-promptRect.size.width*0.5, SCREEN_HEIGHT*.5+kUexScannerCaptureHeight*0.5+kUexScannerPromptVerticalDistanceFromCapture, kUexScannerPromptMaxWidth,promptRect.size.height)];
    [self.view addSubview:promptLabel];
    
}

#pragma mark - Bar Button Action

- (void)cancelButtonClicked:(id)sender{
    [self dismissWithResult:@"" codeType:@"" isCancelled:YES];
}
- (void)lightButtonClicked:(id)sender{
    self.ZXingCapture.torch=!self.ZXingCapture.torch;
}

- (void)albumButtonClicked:(id)sender{
//8.0+
//    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
//        
//    }];
    
    ALAuthorizationStatus status=[ALAssetsLibrary authorizationStatus];
    if(status==ALAuthorizationStatusNotDetermined){
        ALAssetsLibrary *photo=[ALAssetsLibrary alloc];
        [photo assetForURL:nil resultBlock:^(ALAsset *asset) {
            [self openPicker];
        } failureBlock:^(NSError *error) {
            [self openPicker];
        }];
    }
    else{
        [self openPicker];
    }
}
-(void)openPicker{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Helper

- (void)dismissWithResult:(NSString *)scanResult codeType:(NSString *)codeType isCancelled:(BOOL)isCancelled{
    [self.preview removeFromSuperlayer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            if(self.completion){
                self.completion(scanResult,codeType,isCancelled);
            }
        }];
    });
}


- (UIImage *)bundleImageForName:(NSString *)fileName{
    NSBundle *resBundle=[NSBundle ac_bundleForPlugin:@"uexScanner"];
    
    return [UIImage imageWithContentsOfFile:[[resBundle resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",fileName]]];
}

- (CGRect)captureRect{
    return CGRectMake(SCREEN_WIDTH/2-kUexScannerCaptureWidth/2, SCREEN_HEIGHT/2-kUexScannerCaptureHeight/2, kUexScannerCaptureWidth, kUexScannerCaptureHeight);
}


- (UIBarButtonItem *)flexibleSpaceItem{
    return [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (UIBarButtonItem *)toolbarItemWithImageName:(NSString *)imageName action:(SEL)action{
    UIImage *image=[self bundleImageForName:imageName];
    UIBarButtonItem *item=[[UIBarButtonItem alloc]initWithImage:image style:UIBarButtonItemStylePlain target:self action:action];
    item.tintColor=[UIColor whiteColor];
    return item;
}

- (NSString *)barcodeFormatToString:(ZXBarcodeFormat)format {
    switch (format) {
        case kBarcodeFormatAztec:{
            return @"Aztec";
        }
        case kBarcodeFormatCodabar:{
            return @"CODABAR";
        }
        case kBarcodeFormatCode39:{
            return @"Code 39";
        }
        case kBarcodeFormatCode93:{
            return @"Code 93";
        }
        case kBarcodeFormatCode128:{
            return @"Code 128";
        }
        case kBarcodeFormatDataMatrix:{
            return @"Data Matrix";
        }
        case kBarcodeFormatEan8:{
            return @"EAN-8";
        }
        case kBarcodeFormatEan13:{
            return @"EAN-13";
        }
        case kBarcodeFormatITF:{
            return @"ITF";
        }
        case kBarcodeFormatPDF417:{
            return @"PDF417";
        }
        case kBarcodeFormatQRCode:{
            return @"QR Code";
        }
        case kBarcodeFormatRSS14:{
            return @"RSS 14";
        }
        case kBarcodeFormatRSSExpanded:{
            return @"RSS Expanded";
        }
        case kBarcodeFormatUPCA:{
            return @"UPCA";
        }
        case kBarcodeFormatUPCE:{
            return @"UPCE";
        }
        case kBarcodeFormatUPCEANExtension:{
            return @"UPC/EAN extension";
        }
        case kBarcodeFormatMaxiCode:{
            return @"Maxi Code";
        }
    }
}


#pragma mark - ZXing Delegate

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result{
    if(!result){
        return;
    }
    [self.ZXingCapture stop];
    [self dismissWithResult:result.text codeType:[self barcodeFormatToString:result.barcodeFormat] isCancelled:NO];

}

- (ZXDecodeHints *)decodeHints{
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    hints.tryHarder = YES;

    switch (self.charset) {
        case uexScannerEncodingCUTF8: {
            break;
        }
        case uexScannerEncodingCGBK: {
            NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            hints.encoding = gbkEncoding;
            break;
        }
    }
    
    return hints;
}


#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{
            [picker removeFromParentViewController];
            

        }];
    });
    
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];

    NSError *error = nil;
    

    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap hints:[self decodeHints] error:&error];
    if (result) {
        //[self dismissWithResult:result.text codeType:[self barcodeFormatToString:result.barcodeFormat] isCancelled:NO];
        //这里需要关闭动画，不然退出的时候动画有卡顿
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:^{
                if(self.completion){
                    self.completion(result.text,[self barcodeFormatToString:result.barcodeFormat],NO);
                }
            }];
        });
    }else{
        NSLog(@"%@",[error localizedDescription]);
    }
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{
            [picker removeFromParentViewController];
        }];
    });
}

#pragma mark - Private
- (void)applyOrientation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    float scanRectRotation;
    float captureRotation;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            captureRotation = 0;
            scanRectRotation = 90;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            captureRotation = 90;
            scanRectRotation = 180;
            break;
        case UIInterfaceOrientationLandscapeRight:
            captureRotation = 270;
            scanRectRotation = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            captureRotation = 180;
            scanRectRotation = 270;
            break;
        default:
            captureRotation = 0;
            scanRectRotation = 90;
            break;
    }
    [self applyRectOfInterest:orientation];
    CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat) (captureRotation / 180 * M_PI));
    [self.ZXingCapture setTransform:transform];
    [self.ZXingCapture setRotation:scanRectRotation];
    self.ZXingCapture.layer.frame = self.view.frame;
    
    [self.preview setAffineTransform:transform];
}


- (void)applyRectOfInterest:(UIInterfaceOrientation)orientation {
    CGFloat scaleVideo, scaleVideoX, scaleVideoY;
    CGFloat videoSizeX, videoSizeY;
    CGRect transformedVideoRect = self.view.frame;
//    if([self.ZXingCapture.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
//        videoSizeX = 1080;
//        videoSizeY = 1920;
//    }
//    else if([self.ZXingCapture.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
//        videoSizeX = 720;
//        videoSizeY = 1280;
//    }
//    else if([self.ZXingCapture.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
//        videoSizeX = 540;
//        videoSizeY = 960;
//    }
//    else if([self.ZXingCapture.sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
//        videoSizeX = 2160;
//        videoSizeY = 3840;
//    }
//    else{
//        CGFloat scale_screen = [UIScreen mainScreen].scale;
//        CGFloat width = SCREEN_WIDTH*scale_screen;
//        CGFloat height = SCREEN_HEIGHT*scale_screen;
//        videoSizeX = width>height ? height : width;
//        videoSizeY = width>height ? width : height;
    //    }
    CGFloat scale_screen = [UIScreen mainScreen].scale;
    CGFloat width = SCREEN_WIDTH*scale_screen;
    CGFloat height = SCREEN_HEIGHT*scale_screen;
    videoSizeX = width>height ? height : width;
    videoSizeY = width>height ? width : height;
    
    if(UIInterfaceOrientationIsPortrait(orientation)) {
        scaleVideoX = self.view.frame.size.width / videoSizeX;
        scaleVideoY = self.view.frame.size.height / videoSizeY;
        scaleVideo = MAX(scaleVideoX, scaleVideoY);
        if(scaleVideoX > scaleVideoY) {
            transformedVideoRect.origin.y += (scaleVideo * videoSizeY - self.view.frame.size.height) / 2;
        } else {
            transformedVideoRect.origin.x += (scaleVideo * videoSizeX - self.view.frame.size.width) / 2;
        }
    } else {
        scaleVideoX = self.view.frame.size.width / videoSizeY;
        scaleVideoY = self.view.frame.size.height / videoSizeX;
        scaleVideo = MAX(scaleVideoX, scaleVideoY);
        if(scaleVideoX > scaleVideoY) {
            transformedVideoRect.origin.y += (scaleVideo * videoSizeX - self.view.frame.size.height) / 2;
        } else {
            transformedVideoRect.origin.x += (scaleVideo * videoSizeY - self.view.frame.size.width) / 2;
        }
    }
    CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(1.2, 1.2);
    self.ZXingCapture.scanRect = CGRectApplyAffineTransform(transformedVideoRect, captureSizeTransform);
    
    self.preview.bounds = CGRectApplyAffineTransform(transformedVideoRect, captureSizeTransform);
}


#pragma mark -不支持转屏
- (BOOL)shouldAutorotate{
    return NO;
}
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
//    return UIInterfaceOrientationMaskPortrait;
//}



#pragma mark -AVCaptureOutput

-(void)loadAVCaptureOutput{
    self.device = [ AVCaptureDevice defaultDeviceWithMediaType : AVMediaTypeVideo ];
    self.input = [ AVCaptureDeviceInput deviceInputWithDevice : self.device error : nil ];
    self.output = [[ AVCaptureMetadataOutput alloc ] init ];
    [ self.output setMetadataObjectsDelegate : self queue : dispatch_get_main_queue ()];
    
    //扫描兴趣框
    //[ output setRectOfInterest : CGRectMake (( 124 )/ SCREEN_HEIGHT ,(( SCREEN_WIDTH - 220 )/ 2 )/ SCREEN_WIDTH , 220 / SCREEN_HEIGHT , 220 / SCREEN_WIDTH )];
    CGRect rect=[self captureRect];
    [ self.output setRectOfInterest : CGRectMake (rect.origin.y/ SCREEN_HEIGHT ,rect.origin.x/ SCREEN_WIDTH , rect.size.height / SCREEN_HEIGHT , rect.size.width / SCREEN_WIDTH )];
    
    // Session
    self.session = [[ AVCaptureSession alloc ] init ];
    [ self.session setSessionPreset : AVCaptureSessionPresetHigh ];
    if ([ self.session canAddInput : self.input ]){
        [ self.session addInput : self.input ];
    }
    if ([ self.session canAddOutput : self.output ]){
        [ self.session addOutput : self.output ];
    }
    // 条码类型 AVMetadataObjectTypeQRCode
    float phoneVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(phoneVersion<8.0){
        self.output . metadataObjectTypes = @[ AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code ,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code ,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypePDF417Code ,AVMetadataObjectTypeQRCode ,AVMetadataObjectTypeAztecCode ] ;
    }
    else{
        self.output . metadataObjectTypes = @[ AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code ,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code ,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypePDF417Code ,AVMetadataObjectTypeQRCode ,AVMetadataObjectTypeAztecCode ,AVMetadataObjectTypeInterleaved2of5Code , AVMetadataObjectTypeITF14Code , AVMetadataObjectTypeDataMatrixCode ] ;
    }
    
    // Preview
    self.preview =[ AVCaptureVideoPreviewLayer layerWithSession : self.session ];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspect ;
    self.preview.frame = self.view.layer.bounds ;
    [ self.view.layer insertSublayer : self.preview atIndex : 0 ];
    
    
    [ self.session startRunning ];
}
- ( void )captureOutput:( AVCaptureOutput *)captureOutput didOutputMetadataObjects:( NSArray *)metadataObjects fromConnection:( AVCaptureConnection *)connection
{
    if ([metadataObjects count ] > 0 )
    {
        // 停止扫描
        [ self.session stopRunning ];
        [self.lineView.layer removeAnimationForKey:@"move"];
        
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        NSString *resultStr = metadataObject.stringValue ;
        NSString *codeType=metadataObject.type;
        
        //NSLog(@"----%@",resultStr);
        NSArray *typeArray = [codeType componentsSeparatedByString:@"."];
        if(resultStr &&typeArray.count>=3){
            [self dismissWithResult:resultStr codeType:typeArray[2] isCancelled:NO];
        }
    }
}

@end
