//
//  AVPlayerVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#import "AVPlayerVC.h"

@import CoreMedia;
@import AVFoundation;

@interface AVPlayerVC ()

@property (nonatomic, strong) NSTimer *timerVisibility;

@end

@implementation AVPlayerVC

__strong static id _deallocDisabled; // used in PIP mode

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        _videoBackground = NO;
        _PIPStoryboardId = @"AVPlayerPIPOverlayVC";
        _overlayStoryboardId = @"AVPlayerOverlayVC";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsPlaybackControls = NO;
    
    if (_videoBackground) {
        // audio/video background
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActiveNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForegroundNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avPlayerVCSetVideoURLNotification:)
                                                 name:AVPlayerVCSetVideoURLNotification
                                               object:nil];

    if (_overlayStoryboardId.length > 0)
    {
        _overlayVC = [self.storyboard instantiateViewControllerWithIdentifier:_overlayStoryboardId];
        [_overlayVC loadSubtitlesWithURL:_subtitlesURL];
        
        [self addChildViewController:_overlayVC];
        [self.view addSubview:_overlayVC.view];
        [_overlayVC didMoveToParentViewController:self];
        
        [_overlayVC addTarget:self action:@selector(disableDealloc) forEvents:AVPlayerOverlayEventDidPIPBecomeActive];
        [_overlayVC addTarget:self action:@selector(enableDealloc) forEvents:AVPlayerOverlayEventDidPIPDeactivation];
        [_overlayVC addTarget:self action:@selector(didPeriodicTimeObserver:) forEvents:AVPlayerOverlayEventPeriodicTimeObserver];
    }
    
    if (_PIPStoryboardId.length > 0)
    {
        _pipOverlayVC = [self.storyboard instantiateViewControllerWithIdentifier:_PIPStoryboardId];
        
        [_pipOverlayVC addTarget:self action:@selector(enableDealloc) forEvents:AVPlayerOverlayEventPIPClosed];
        [_pipOverlayVC addTarget:_overlayVC action:@selector(pipDeactivate) forEvents:AVPlayerOverlayEventPIPDeactivationRequest];
        
        [self addChildViewController:_pipOverlayVC];
        [self.view addSubview:_pipOverlayVC.view];
        [_pipOverlayVC didMoveToParentViewController:self];
        
        [_overlayVC addTarget:_pipOverlayVC action:@selector(showControls) forEvents:AVPlayerOverlayEventDidPIPBecomeActive];
        [_overlayVC addTarget:_pipOverlayVC action:@selector(hideControls) forEvents:AVPlayerOverlayEventWillPIPDeactivation];
    }
    
    // visibility notification
    _timerVisibility = [NSTimer timerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        static BOOL visibility = NO;
        CGRect rect = [self.view.window convertRect:self.view.frame fromView:self.view];
        if (rect.size.width > 0 && rect.size.height > 0) {
            if (CGRectContainsRect(self.view.window.frame, rect) && !visibility) {
                visibility = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerVCVisibilityNotification object:@(YES)];
            } else if (!CGRectContainsRect(self.view.window.frame, rect) && visibility) {
                visibility = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerVCVisibilityNotification object:@(NO)];
            }
        }
    }];
    [[NSRunLoop currentRunLoop] addTimer:_timerVisibility forMode:NSRunLoopCommonModes];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _overlayVC.view.frame = self.view.bounds;
    _pipOverlayVC.view.frame = self.view.bounds;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setPlayer:(AVPlayer *)player
{
    [super setPlayer:player];
    
    _overlayVC.player = self.player;
    _pipOverlayVC.player = self.player;
}

- (void)setVideoURL:(NSURL *)videoURL
{
    @synchronized (self) {
        _videoURL = videoURL;

        if (_videoURL != nil) {
            
            AVAsset *asset = [self.player.currentItem asset];
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                NSURL *current_url = [(AVURLAsset*)asset URL];
                if ([current_url.absoluteString isEqualToString:_videoURL.absoluteString])
                    return;
            }
            
            @try {
                [self.player.currentItem removeObserver:_overlayVC forKeyPath:@"status"];
            } @catch (NSException *exception) { }
            
            NSDictionary *options = _userAgent.length > 0 ? @{@"AVURLAssetHTTPHeaderFieldsKey" : @{@"User-Agent": _userAgent}} : nil;
            AVURLAsset *url_asset = [AVURLAsset URLAssetWithURL:_videoURL options:options];
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:url_asset];
            
            // workaround for iOS 8.0 video error -11800
            if(self.player == nil || SYSTEM_VERSION_LESS_THAN(@"9.0")) {
                self.player = [AVPlayer playerWithPlayerItem:item];
            } else {
                [self.player replaceCurrentItemWithPlayerItem:item];
            }
        } else {
            [self.player replaceCurrentItemWithPlayerItem:nil];
        }
        
    }
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    
#ifdef DEBUG
    NSLog(@"Remote control event %i subtype %i", (int)event.type, (int)event.subtype);
#endif

    if (event.type == UIEventTypeRemoteControl && self.player) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlStop:
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [_overlayVC didPlayButtonSelected:self];
                break;
            default:
                break;
        }
    }
}

- (void)dealloc
{
    [_overlayVC.player pause];
    [_overlayVC setPlayer:nil];
    
    [_overlayVC removeFromParentViewController], _overlayVC = nil;
    [_pipOverlayVC removeFromParentViewController], _pipOverlayVC = nil;
    
    [_timerVisibility invalidate], _timerVisibility = nil;
    
    [self.player pause], self.player = nil;
}

#pragma mark - Video (only audio) on background

- (void)playInBackground:(BOOL)play
{
    static BOOL isPlay;
    
    isPlay = self.player.rate != 0;
    AVPlayerItem *playerItem = [self.player currentItem];
    
    NSArray *tracks = [playerItem tracks];
    for (AVPlayerItemTrack *playerItemTrack in tracks)
    {
        // find video tracks
        if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual])
        {
            playerItemTrack.enabled = !play;
            break;
        }
    }
    
    if (isPlay)
        [self.player performSelector:@selector(play) withObject:nil afterDelay:1.0];
}

#pragma mark - PIP Events

- (void)disableDealloc
{
    _deallocDisabled = self;
}

- (void)enableDealloc
{
    _deallocDisabled = nil;
}

#pragma mark - Overlay Events

- (void)didPeriodicTimeObserver:(NSValue*)value
{
    CMTime time = [value CMTimeValue];
    [self.pipOverlayVC setCurrentTimeValue:time];
}

#pragma mark - Notifications

- (void)applicationWillResignActiveNotification:(NSNotification*)note
{
    [self playInBackground:YES];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification*)note
{
    [self playInBackground:NO];
}

- (void)avPlayerVCSetVideoURLNotification:(NSNotification*)note
{
    self.videoURL = note.object;
    self.subtitlesURL = note.userInfo[kAVPlayerVCSubtitleURL];
    
    [_overlayVC loadSubtitlesWithURL:_subtitlesURL];
}

@end
