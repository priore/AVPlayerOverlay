//
//  TableViewController.h
//  CustomAVPlayer
//
//  Created by Danilo Priore on 29/04/16.
//  Copyright © 2016 Danilo Priore. All rights reserved.
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
