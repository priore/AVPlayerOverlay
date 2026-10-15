//
//  TableViewController.h
//  CustomAVPlayer
//
//  Created by Priore on 29/04/16.
//  Copyright © 2016 Priore. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChannelListDelegate;

@interface TableViewController : UITableViewController

@property (nonatomic, assign) id<ChannelListDelegate> delegate;

@end

@protocol ChannelListDelegate <NSObject>

@optional

- (void)channeiList:(UIViewController*)viewController selectedVideoURL:(NSURL*)videoURL subtitlesURL:(NSURL*)subtitlesURL;

@end
