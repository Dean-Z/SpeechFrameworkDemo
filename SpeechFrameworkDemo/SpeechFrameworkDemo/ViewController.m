//
//  ViewController.m
//  SpeechFrameworkDemo
//
//  Created by Z on 2018/7/19.
//  Copyright © 2018年 DS. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>

@interface ViewController ()<SFSpeechRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *contentTextView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;

@property (nonatomic, strong) SFSpeechRecognizer *recognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recoginitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) AVAudioEngine *audioEngine;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recognizer = [[SFSpeechRecognizer alloc]initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    self.recognizer.delegate = self;
    self.audioEngine = [[AVAudioEngine alloc] init];
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        BOOL buttonEnable = NO;
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                buttonEnable = YES;
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                buttonEnable = NO;
                NSLog(@"SFSpeechRecognizerAuthorizationStatusRestricted");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                buttonEnable = NO;
                NSLog(@"SFSpeechRecognizerAuthorizationStatusDenied");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                buttonEnable = NO;
                NSLog(@"SFSpeechRecognizerAuthorizationStatusNotDetermined");
                break;
            default:
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordButton.enabled = buttonEnable;
        });
    }];
}


- (IBAction)recordAction:(id)sender {
    if (self.recordButton.selected) {
        if (self.audioEngine.isRunning) {
            [self.audioEngine stop];
            [self.recoginitionRequest endAudio];
            self.recordButton.selected = NO;
        }
    } else {
        self.recordButton.selected = YES;
        [self startRecord];
    }
}

- (void)startRecord {
    if (self.recognitionTask != nil) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error1;
    NSError *error2;
    NSError *error3;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error1];
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error2];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error3];
    
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    if (inputNode == nil) {
        NSLog(@"Audio engine has no input node");
    }
    
    self.recoginitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
    self.recoginitionRequest.shouldReportPartialResults = YES;
    self.recognitionTask = [self.recognizer recognitionTaskWithRequest:self.recoginitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result != nil) {
            self.contentTextView.text = result.bestTranscription.formattedString;
            isFinal = result.isFinal;
        }
        
        if (error != nil || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            
            self.recoginitionRequest = nil;
            self.recognitionTask = nil;
            self.recordButton.selected = NO;
        }
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recoginitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [self.audioEngine prepare];
    NSError *startError;
    if (![self.audioEngine startAndReturnError:&startError]) {
        NSLog(@"%@",startError.localizedDescription);
    }
    self.contentTextView.text = @"Say something, I'm listening!";
}

#pragma mark - SFSpeechRecognizerDelegate

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (available) {
        self.recordButton.enabled = YES;
    } else {
        self.recordButton.enabled = NO;
        NSLog(@"unavailable!!");
    }
}


@end
