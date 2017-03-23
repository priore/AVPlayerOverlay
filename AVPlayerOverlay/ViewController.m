//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by Danilo Priore on 29/04/16.
//  Copyright © 2016 Danilo Priore. All rights reserved.
//

#import "ViewController.h"
#import "AVPlayerVC.h"

@interface ViewController () <AVPlayerOverlayVCDelegate>

@property (nonatomic, weak) AVPlayerVC *playerVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _playerVC.overlayVC.delegate = self;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AVPlayerVC class]]) {
        _playerVC = segue.destinationViewController;
    }
}

- (void)dealloc
{
    _playerVC.overlayVC.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
