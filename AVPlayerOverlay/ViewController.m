//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by Danilo Priore on 29/04/16.
//  Copyright © 2016 Danilo Priore. All rights reserved.
//

#import "ViewController.h"
#import "TableViewController.h"
#import "AVPlayerVC.h"

@interface ViewController () <AVPlayerOverlayVCDelegate, ChannelListDelegate>

@property (nonatomic, weak) AVPlayerVC *playerVC;
@property (nonatomic, weak) TableViewController *tableViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _playerVC.overlayVC.delegate = self;
    _tableViewController.delegate = self;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AVPlayerVC class]]) {
        _playerVC = segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[TableViewController class]]) {
        _tableViewController = segue.destinationViewController;
    }
}

- (void)dealloc
{
    _playerVC.overlayVC.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ChannelList Delegate

- (void)channeiList:(UIViewController *)viewController selectedVideoURL:(NSURL *)videoURL subtitlesURL:(NSURL *)subtitlesURL
{
    _playerVC.videoURL = videoURL;
    _playerVC.subtitlesURL = subtitlesURL;
}

#pragma mark - AVPlayerOverlayVC Delegate

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController willFullScreen:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController didFullScreen:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController willNormalScreen:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController didNormalScreen:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController airPlayInUse:(BOOL)inUse
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController airPlayBecomePresent:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController airPlayResignPresent:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController willPIPBecomeActive:(id)sender
{

}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController didPIPBecomeActive:(id)sender
{
    
}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController willPIPDeactivation:(id)sender
{

}

- (void)avPlayerOverlay:(AVPlayerOverlayVC *)viewController didPIPDeactivation:(id)sender
{
    
}

@end
