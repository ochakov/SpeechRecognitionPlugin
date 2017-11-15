//
//  Created by jcesarmobile on 30/11/14.
//
//

#import "SpeechRecognition.h"
#import "iSpeechSDK.h"
#import <AVFoundation/AVFoundation.h>

@implementation SpeechRecognition


- (void) init:(CDVInvokedUrlCommand*)command {
    NSLog(@"init");
    NSString * key = [self.commandDelegate.settings objectForKey:[@"apiKey" lowercaseString]];
    if (!key) {
        key = @"developerdemokeydeveloperdemokey";
    }
    iSpeechSDK *sdk = [iSpeechSDK sharedSDK];
    sdk.APIKey = key;
}


- (void) start:(CDVInvokedUrlCommand*)command {
    
    self.command = command;
    
#ifndef __IPHONE_7_0
    typedef void (^PermissionBlock)(BOOL granted);
#endif
    
    PermissionBlock permissionBlock = ^(BOOL granted) {
        [self recognize];
    };
    
    // iOS7+
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:)
                                              withObject:permissionBlock];
    }
    else
    {
        [self recognize];
    }
}

- (void)recognize {

    NSString * lang = [self.command argumentAtIndex:0];
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:@"start" forKey:@"type"];
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    self.pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
    [self recognize:lang];
    
}

- (void)recognize:(NSString*)lang {
    ISSpeechRecognition *recognition = [[ISSpeechRecognition alloc] init];
    [recognition setDelegate:self];
    if (lang) {
        NSLog(@"lang %@",lang);
        if ([lang isEqualToString:@"en"]) {
            lang = @"en-US";
        }
        [recognition setLocale:lang];
    }
    [recognition setFreeformType:ISFreeFormTypeDictation];

    if ([self isMicrophoneAvailable]) {
        NSError *error;
        
        if(![recognition listenAndRecognizeWithTimeout:10 error:&error]) {
            NSLog(@"ERROR: %@", error);
        }
    }
    else {
        NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
        [event setValue:@"error" forKey:@"type"];
        [event setValue:[NSNumber numberWithInt:7] forKey:@"error"];
        [event setValue:@"Microphone access not allowed" forKey:@"message"];
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:event];
        self.pluginResult.keepCallback = [NSNumber numberWithBool:YES];
        [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
    }
}

- (void)recognition:(ISSpeechRecognition *)speechRecognition didGetRecognitionResult:(ISSpeechRecognitionResult *)result {
    
    NSMutableDictionary * resultDict = [[NSMutableDictionary alloc]init];
    [resultDict setValue:result.text forKey:@"transcript"];
    [resultDict setValue:[NSNumber numberWithBool:YES] forKey:@"final"];
    [resultDict setValue:[NSNumber numberWithFloat:result.confidence]forKey:@"confidence"];
    NSArray * alternatives = @[resultDict];
    NSArray * results = @[alternatives];
    
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:@"result" forKey:@"type"];
    [event setValue:nil forKey:@"emma"];
    [event setValue:nil forKey:@"interpretation"];
    [event setValue:results forKey:@"results"];
    
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    self.pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
    
}

- (void)recognition:(ISSpeechRecognition *)speechRecognition didFailWithError:(NSError *)error {
    
    if (error.code == 28) {
        NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
        [event setValue:@"error" forKey:@"type"];
        [event setValue:[NSNumber numberWithInt:7] forKey:@"error"];
        [event setValue:[error localizedDescription] forKey:@"message"];
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:event];
        self.pluginResult.keepCallback = [NSNumber numberWithBool:YES];
        [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
    }
    
}

- (BOOL)isMicrophoneAvailable {

    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    return (permission == AVAudioSessionRecordPermissionGranted);
}

@end
