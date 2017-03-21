//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by Danilo Priore on 29/04/16.
//  Copyright © 2016 Danilo Priore. All rights reserved.
//

#import "ViewController.h"
#import "AVPlayerVC.h"

@interface ViewController ()

@property (nonatomic, weak) AVPlayerVC *playerVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AVPlayerVC class]]) {
        _playerVC = segue.destinationViewController;
    }
}

@end
