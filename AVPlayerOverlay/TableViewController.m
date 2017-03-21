//
//  TableViewController.m
//  CustomAVPlayer
//
//  Created by Danilo Priore on 29/04/16.
//  Copyright © 2016 Danilo Priore. All rights reserved.
//

#import "TableViewController.h"
#import "AVPlayerVC.h"

@interface TableViewController ()
{
    NSArray *channels;
}

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Channels" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    channels = dict[@"Channels"];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return channels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    NSDictionary *dict = channels[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:dict[@"Icon"]];
    cell.textLabel.text = dict[@"ChannelName"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = channels[indexPath.row];
    NSURL *videoURL = [NSURL URLWithString:dict[@"URL"]];
    
    NSURL *srtURL = [NSURL URLWithString:dict[@"Subtitles"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerVCSetVideoURLNotification object:videoURL userInfo:srtURL ? @{kAVPlayerVCSubtitleURL: srtURL} : nil];
}

@end
