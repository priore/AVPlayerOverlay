//
//  SubtitlePackage.m
//  APP4
//
//  Created by user on 12-11-9.
//  Modified by Danilo Priore on 3-21-16.
//  Copyright (c) 2012年 FreeBox. All rights reserved.
//

#import "SubtitlePackage.h"

typedef enum {
    
    SubtitleScannerPositionIndex,
    SubtitleScannerPositionTime,
    SubtitleScannerPositionChi,
    SubtitleScannerPositionEng
    
}SubtitleScanner;

@implementation SubtitlePackage
@synthesize subtitleItems;

- (SubtitlePackage *)initWithFile:(NSString *)filePath{
    
    NSString *context=[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    return [self initWithContext:context];
}

- (SubtitlePackage *)initWithContext:(NSString *)context{
    
    self.subtitleItems=[NSMutableArray arrayWithCapacity:0];
    
    //在subtitleItem的Array索引为0上，创建一个individualSubtitle，在这个里面把中文英文字幕都设置为空。以便在用CMTime检索字幕package时，没检索到时用空白显示
    IndividualSubtitle *blankSubtitle=[IndividualSubtitle new];
    blankSubtitle.EngSubtitle=@" ";
    blankSubtitle.ChiSubtitle=@" ";
    [self.subtitleItems addObject:blankSubtitle];
    
    [self makeIndividualSubtitle:context];
    
    return self;
}

#pragma mark - make individual subtitle item

- (void)makeIndividualSubtitle:(NSString *)context{
    
    NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet alphanumericCharacterSet];
    
    __block IndividualSubtitle *subtitle=[IndividualSubtitle new];
    __block SubtitleScanner scanner=SubtitleScannerPositionIndex;
    
    [context enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        
        NSRange r = [line rangeOfCharacterFromSet:alphanumericCharacterSet];
        
        if (r.location != NSNotFound) {
            
            BOOL actionAlreadyTaken = NO;
            
            if (scanner == SubtitleScannerPositionIndex) {
                
                scanner = SubtitleScannerPositionTime; 
                actionAlreadyTaken = YES;
            }
            
            if ((scanner == SubtitleScannerPositionTime) && (!actionAlreadyTaken)) {
                
                CMTime startTime = kCMTimeInvalid, endTime = kCMTimeInvalid;
                [self makeCMTimeStart:&startTime end:&endTime timeLine:line];

                subtitle.startTime = startTime;
                subtitle.endTime = endTime;
                
                scanner = SubtitleScannerPositionChi;
                actionAlreadyTaken = YES;
            }
            
            if ((scanner == SubtitleScannerPositionChi) && (!actionAlreadyTaken)) {
                
                subtitle.ChiSubtitle=[NSString stringWithString:line];
                
                scanner = SubtitleScannerPositionEng;
                actionAlreadyTaken = YES;
            }
            
            if ((scanner == SubtitleScannerPositionEng) && (!actionAlreadyTaken)) {
                
                NSString *current;
                if ([line length]) {
                    current=[NSString stringWithString:line];
                }else{
                    current=@" ";
                }
                
                NSString *prev=subtitle.EngSubtitle;
                if (prev==nil) {
                    subtitle.EngSubtitle=current;
                }else{
                    subtitle.EngSubtitle=[subtitle.EngSubtitle stringByAppendingFormat:@"\n%@",current];
                }
                
                scanner = SubtitleScannerPositionEng;
            }
        }
        else {
            [self.subtitleItems addObject:subtitle];
            subtitle = [IndividualSubtitle new];
            scanner = SubtitleScannerPositionIndex;
        }
    }];
    
    if (scanner == SubtitleScannerPositionEng) {
        
        [self.subtitleItems addObject:subtitle];
    }
    
    /*
    NSArray *contextLine=[context componentsSeparatedByString:@"\n"];
    
    for (int i=0; i<[contextLine count]; i++)
    {
        
        NSRange firstCharRange=NSMakeRange(0, 1);
        NSString *lineIndex=[contextLine objectAtIndex:i];
        
        if ([lineIndex length])  //to skip over blank lines
        {
            
            if ([[lineIndex substringWithRange:firstCharRange] intValue]>=1 &&
                [[lineIndex substringWithRange:firstCharRange] intValue]<=9) // the index line
            {
                NSLog(@"cccccc");
                NSString *lineTime=[contextLine objectAtIndex:i+1];
                if ([[lineTime substringWithRange:firstCharRange] isEqualToString:@"0"]) //the time line
                {
                    IndividualSubtitle *subtitle=[IndividualSubtitle new];
                    NSString *lineChi=[contextLine objectAtIndex:i+2];
                    NSString *lineEng=[contextLine objectAtIndex:i+3];
                    
                    subtitle.startTime=[self makeCMTimeStart:lineTime];
                    subtitle.endTime=[self makeCMTimeEnd:lineTime];
                    subtitle.ChiSubtitle=[NSString stringWithString:lineChi];
                    
                    if ([lineEng length]) {
                        subtitle.EngSubtitle=[NSString stringWithString:lineEng];
                    }else{
                        subtitle.EngSubtitle=@" ";
                    }
                    [self.subtitleItems addObject:subtitle];
                }
                else
                {
                    //如果字幕索引下不是时间轴，则出错
                    NSLog(@"subtitle package wrong");
                }
            }
        }
    }
     
     */
}

#pragma mark - choose proper subtitle by given CMTime

- (NSUInteger)indexOfProperSubtitleWithGivenCMTime:(CMTime)time{
    
    double timeInSeconds=CMTimeGetSeconds(time);
    NSUInteger theIndex=[self.subtitleItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if (timeInSeconds>=CMTimeGetSeconds([obj startTime]) && timeInSeconds<=CMTimeGetSeconds([obj endTime])) {
            return YES;
        }else{
            return NO;
        }
    }];
    if (theIndex==NSNotFound) {
        return 0;
    }else{
        return theIndex;
    }
    
}


- (NSInteger)indexOfBackForWard:(CMTime)time{
    
    double timeInSeconds=CMTimeGetSeconds(time);
    NSInteger currentIndex=[self indexOfProperSubtitleWithGivenCMTime:time];
    NSInteger indexToMove=currentIndex;
    
    if (!currentIndex) {
        if (timeInSeconds<CMTimeGetSeconds([[self.subtitleItems objectAtIndex:1] startTime])) {
            indexToMove=1;
        }else if (timeInSeconds>CMTimeGetSeconds([[self.subtitleItems lastObject] endTime])) {
            indexToMove=[self.subtitleItems count];
        }else{
            for (int i=1; i<self.subtitleItems.count-1; i++) {
                double lastEnd=CMTimeGetSeconds([[self.subtitleItems objectAtIndex:i] endTime]);
                double nextStart=CMTimeGetSeconds([[self.subtitleItems objectAtIndex:i+1] startTime]);            
                if (lastEnd < timeInSeconds && timeInSeconds < nextStart) {
                    indexToMove=i+1;
                }
            }
        }
    }

    return indexToMove;
}


#pragma mark - save

- (NSString *)makeSaveName:(CMTime)time {
    float timeInSecond=CMTimeGetSeconds(time);
    
    NSString *hour;
    if (timeInSecond/3600>0) {
        hour=[NSString stringWithFormat:@"0%d-",(int)timeInSecond/3600];
    }
    else{
        hour=@"00-";
    }
    
    NSString *min;
    if ((int)timeInSecond%3600/60<10) {
        min=[NSString stringWithFormat:@"0%d-",(int)timeInSecond%3600/60];
    }else{
        min=[NSString stringWithFormat:@"%d-",(int)timeInSecond%3600/60];
    }
    
    
    NSString *sec;
    if ((int)timeInSecond%3600%60<10) {
        sec=[NSString stringWithFormat:@"0%d-",(int)timeInSecond%3600%60];
    }else{
        sec=[NSString stringWithFormat:@"%d-",(int)timeInSecond%3600%60];
    }
    
    float fract=(timeInSecond-(int)timeInSecond)*100;
    NSString *fra;
    if (fract<10) {
        fra=[NSString stringWithFormat:@"0%d",(int)fract];
    }else{
        fra=[NSString stringWithFormat:@"%d",(int)fract];
    }
    
    
    NSString *saveName=[[[hour stringByAppendingString:min] stringByAppendingString:sec] stringByAppendingString:fra];
    return saveName;
}


- (void)saveSubtitleWithTime:(CMTime)time inPath:(NSString *)path{
    
    NSUInteger index=[self indexOfProperSubtitleWithGivenCMTime:time];
    
    IndividualSubtitle *currentSubtitle=[self.subtitleItems objectAtIndex:index];
    
    NSMutableData *data=[[NSMutableData alloc]init];
    NSKeyedArchiver *archiver=[[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:currentSubtitle forKey:@"subtitle"];
    [archiver finishEncoding];
    
    NSString *savePath=[path stringByAppendingPathExtension:@"txt"];
    
    [data writeToFile:savePath atomically:YES];
    
}



#pragma mark - make CMTime from String

- (void)makeCMTimeStart:(CMTime*)start end:(CMTime*)end timeLine:(NSString*)timeline {

    NSArray *values = [timeline componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@": "]];
    if (values.count >= 7) {
        *start = [self makeCMTimeFromSperatedTime:[values subarrayWithRange:NSMakeRange(0, 3)]];
        *end = [self makeCMTimeFromSperatedTime:[values subarrayWithRange:NSMakeRange(4, 3)]];
    }
}

- (CMTime)makeCMTimeFromSperatedTime:(NSArray*)separatedTime {
    
    int hour = [[separatedTime objectAtIndex:0] intValue];
    int min = [[separatedTime objectAtIndex:1] intValue];
    double sec = [[[separatedTime objectAtIndex:2] stringByReplacingOccurrencesOfString:@"," withString:@"."] doubleValue];
    
    double timeInSeconds = (sec * 1000 + min * 60 * 1000 + hour * 60 * 60 * 1000) / 1000.00 * 600.00;
    CMTime time = CMTimeMake(timeInSeconds, 600);
    return time;
}

#pragma mark - using in setting

- (CGFloat)imageTimeWithName:(NSString *)name{
    
    NSArray *component=[name componentsSeparatedByString:@"-"];
    
    int hour=[[component objectAtIndex:0] intValue];
    int min=[[component objectAtIndex:1] intValue];
    int sec=[[component objectAtIndex:2] intValue];
    int fra=[[component objectAtIndex:3] intValue];
    
    float seconds=hour*3600+min*60+sec+fra/100.0;

    return seconds;
}

- (CGFloat)audioStartTimeWithName:(NSString *)name{
    
    CGFloat seconds=[self imageTimeWithName:name];
    CMTime imageTime=CMTimeMakeWithSeconds(seconds, 600);
    
    NSUInteger index=[self indexOfProperSubtitleWithGivenCMTime:imageTime];
    IndividualSubtitle *subtitle=[self.subtitleItems objectAtIndex:index];
    CGFloat startTime=CMTimeGetSeconds(subtitle.startTime);
    
    return startTime;
}

- (CGFloat)audioEndTimeWithName:(NSString *)name{
    
    CGFloat seconds=[self imageTimeWithName:name];
    CMTime imageTime=CMTimeMakeWithSeconds(seconds, 600);
    
    NSUInteger index=[self indexOfProperSubtitleWithGivenCMTime:imageTime];
    IndividualSubtitle *subtitle=[self.subtitleItems objectAtIndex:index];
    CGFloat endTime=CMTimeGetSeconds(subtitle.endTime);
    
    return endTime;

}

#pragma mark - NSCoding & NSCopying

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:subtitleItems forKey:@"subtitleItems"];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self=[super init]) {
        subtitleItems=[aDecoder decodeObjectForKey:@"subtitleItems"];
    }
    return self;
}

@end



#pragma mark -


@implementation IndividualSubtitle
@synthesize startTime, endTime;
@synthesize EngSubtitle, ChiSubtitle;

- (IndividualSubtitle *)initSubtitle{
    IndividualSubtitle *subtitle=[IndividualSubtitle new];
    subtitle.startTime=kCMTimeZero;
    subtitle.endTime=kCMTimeZero;
    return subtitle;
}

- (void)savesubtitleInPath:(NSString *)path{
    
    NSMutableData *data=[[NSMutableData alloc]init];
    NSKeyedArchiver *archiver=[[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:self forKey:@"subtitle"];
    [archiver finishEncoding];
    
    [data writeToFile:path atomically:YES];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeCMTime:startTime forKey:@"startTime"];
    [aCoder encodeCMTime:endTime forKey:@"endTime"];
    [aCoder encodeObject:EngSubtitle forKey:@"EngSubtitle"];
    [aCoder encodeObject:ChiSubtitle forKey:@"ChiSubtitle"];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self=[super init]) {
        startTime=[aDecoder decodeCMTimeForKey:@"startTime"];
        endTime=[aDecoder decodeCMTimeForKey:@"endTime"];
        EngSubtitle=[aDecoder decodeObjectForKey:@"EngSubtitle"];
        ChiSubtitle=[aDecoder decodeObjectForKey:@"ChiSubtitle"];
        
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    IndividualSubtitle *copy=[[[self class] allocWithZone:zone]init];
    copy.startTime=self.startTime;
    copy.endTime=self.endTime;
    copy.EngSubtitle=[self.EngSubtitle copyWithZone:zone];
    copy.ChiSubtitle=[self.ChiSubtitle copyWithZone:zone];
    return copy;
}

@end
