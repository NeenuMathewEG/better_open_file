#import "OpenFilePlugin.h"
#import <better_open_file/better_open_file-Swift.h>

@interface OpenFilePlugin ()<UIDocumentInteractionControllerDelegate>
@end

static NSString *const CHANNEL_NAME = @"open_file";

@implementation OpenFilePlugin{
    FlutterResult _result;
    UIViewController *_viewController;
    UIDocumentInteractionController *_documentController;
    UIDocumentInteractionController *_interactionController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:CHANNEL_NAME
                                     binaryMessenger:[registrar messenger]];
    OpenFilePlugin* instance = [[OpenFilePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (UIViewController *)resolvedPresentingViewController {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
            if (keyWindow) break;
        }
    }
    if (!keyWindow) {
        // Fallback for pre-Scene lifecycle apps (or iOS < 13).
        keyWindow = [UIApplication sharedApplication].delegate.window;
    }
    UIViewController *rootVC = keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController; // present on top of any existing modal
    }
    return rootVC;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"open_file" isEqualToString:call.method]) {
        _result = result;
        _viewController = [self resolvedPresentingViewController];
        if (!_viewController) {
            NSDictionary *dict = @{@"message":@"no view controller available to present the file", @"type":@-4};
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            result(json);
            return;
        }
        NSString *msg = call.arguments[@"file_path"];
        if(msg==nil){
            NSDictionary * dict = @{@"message":@"the file path cannot be null", @"type":@-4};
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
            NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            result(json);
            return;
        }
        NSFileManager *fileManager=[NSFileManager defaultManager];
        BOOL fileExist=[fileManager fileExistsAtPath:msg];
        if(fileExist){
            //            NSURL *resourceToOpen = [NSURL fileURLWithPath:msg];
//            NSString *exestr = [[msg pathExtension] lowercaseString];
            NSString *uti = call.arguments[@"uti"];
            BOOL isBlank = [self isBlankString:uti];
            NSString *ext = [[msg pathExtension] lowercaseString];
            BOOL isPdf = (!isBlank && [uti isEqualToString:@"com.adobe.pdf"]) || [ext isEqualToString:@"pdf"];
            if(isPdf){
                NSString *displayName = call.arguments[@"display_name"];
                if ([self isBlankString:displayName]) {
                    displayName = [msg lastPathComponent];
                }
                PdfPreviewViewController *pdfViewController = [[PdfPreviewViewController alloc] initWithFileURL:[NSURL fileURLWithPath:msg] displayName:displayName];
                __weak OpenFilePlugin *weakSelf = self;
                pdfViewController.onDismiss = ^{
                    __strong OpenFilePlugin *strongSelf = weakSelf;
                    if (!strongSelf) return;
                    NSDictionary * dict = @{@"message":@"done", @"type":@0};
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                    NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    strongSelf->_result(json);
                };
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:pdfViewController];
                [_viewController presentViewController:navController animated:YES completion:nil];
                return;
            }
            _documentController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:msg]];
            _documentController.delegate = self;
            if(!isBlank){
                _documentController.UTI = uti;
            }
//             else{
//                 if([exestr isEqualToString:@"rtf"]){
//                     _documentController.UTI=@"public.rtf";
//                 }else if([exestr isEqualToString:@"txt"]){
//                     _documentController.UTI=@"public.plain-text";
//                 }else if([exestr isEqualToString:@"html"]||
//                          [exestr isEqualToString:@"htm"]){
//                     _documentController.UTI=@"public.html";
//                 }else if([exestr isEqualToString:@"xml"]){
//                     _documentController.UTI=@"public.xml";
//                 }else if([exestr isEqualToString:@"tar"]){
//                     _documentController.UTI=@"public.tar-archive";
//                 }else if([exestr isEqualToString:@"gz"]||
//                          [exestr isEqualToString:@"gzip"]){
//                     _documentController.UTI=@"org.gnu.gnu-zip-archive";
//                 }else if([exestr isEqualToString:@"tgz"]){
//                     _documentController.UTI=@"org.gnu.gnu-zip-tar-archive";
//                 }else if([exestr isEqualToString:@"jpg"]||
//                          [exestr isEqualToString:@"jpeg"]){
//                     _documentController.UTI=@"public.jpeg";
//                 }else if([exestr isEqualToString:@"png"]){
//                     _documentController.UTI=@"public.png";
//                 }else if([exestr isEqualToString:@"avi"]){
//                     _documentController.UTI=@"public.avi";
//                 }else if([exestr isEqualToString:@"mpg"]||
//                          [exestr isEqualToString:@"mpeg"]){
//                     _documentController.UTI=@"public.mpeg";
//                 }else if([exestr isEqualToString:@"mp4"]){
//                     _documentController.UTI=@"public.mpeg-4";
//                 }else if([exestr isEqualToString:@"3gpp"]||
//                          [exestr isEqualToString:@"3gp"]){
//                     _documentController.UTI=@"public.3gpp";
//                 }else if([exestr isEqualToString:@"mp3"]){
//                     _documentController.UTI=@"public.mp3";
//                 }else if([exestr isEqualToString:@"zip"]){
//                     _documentController.UTI=@"com.pkware.zip-archive";
//                 }else if([exestr isEqualToString:@"gif"]){
//                     _documentController.UTI=@"com.compuserve.gif";
//                 }else if([exestr isEqualToString:@"bmp"]){
//                     _documentController.UTI=@"com.microsoft.bmp";
//                 }else if([exestr isEqualToString:@"ico"]){
//                     _documentController.UTI=@"com.microsoft.ico";
//                 }else if([exestr isEqualToString:@"doc"]){
//                     _documentController.UTI=@"com.microsoft.word.doc";
//                 }else if([exestr isEqualToString:@"xls"]){
//                     _documentController.UTI=@"com.microsoft.excel.xls";
//                 }else if([exestr isEqualToString:@"ppt"]){
//                     _documentController.UTI=@"com.microsoft.powerpoint.​ppt";
//                 }else if([exestr isEqualToString:@"wav"]){
//                     _documentController.UTI=@"com.microsoft.waveform-​audio";
//                 }else if([exestr isEqualToString:@"wm"]){
//                     _documentController.UTI=@"com.microsoft.windows-​media-wm";
//                 }else if([exestr isEqualToString:@"wmv"]){
//                     _documentController.UTI=@"com.microsoft.windows-​media-wmv";
//                 }else if([exestr isEqualToString:@"pdf"]){
//                     _documentController.UTI=@"com.adobe.pdf";
//                 }else {
//                     NSLog(@"doc type not supported for preview");
//                     NSLog(@"%@", exestr);
//                 }
//             }
            @try {
                BOOL previewSucceeded = [_documentController presentPreviewAnimated:YES];
                if(!previewSucceeded){
                    [_documentController presentOpenInMenuFromRect:CGRectMake(500,20,100,100) inView:_viewController.view animated:YES];
                }
            }@catch (NSException *exception) {
                NSDictionary * dict = @{@"message":@"File opened incorrectly。", @"type":@-4};
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                result(json);
            }
        }else{
            NSDictionary * dict = @{@"message":@"the file does not exist", @"type":@-2};
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
            NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

            result(json);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSDictionary * dict = @{@"message":@"done", @"type":@0};
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    _result(json);
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
      NSDictionary * dict = @{@"message":@"done", @"type":@0};
      NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
      NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

      _result(json);
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return  _viewController;
}

- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0){
        return YES;
    }
    return NO;
}
@end
