//
//  MISFileScanner.h
//  DuplicateFileKiller
//
//  Created by Mao on 2018/12/14.
//  Copyright © 2018 mao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MISFile : NSObject
@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, copy, readonly) NSString* path;
@property (nonatomic, assign, readonly) UInt64 size;
@end


@interface MISFileScanner : NSObject
@property (nonatomic, copy, readonly) NSArray <MISFile *>* files;
@property (nonatomic, copy, readonly) NSDictionary<NSString*, MISFile *>* filesInfo;


+ (MISFileScanner *)defaultScanner;

/*扫描文件*/
- (void)scanFilePath:(NSString *)filePath;
@end


