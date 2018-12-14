//
//  MISFileScanner.m
//  DuplicateFileKiller
//
//  Created by Mao on 2018/12/14.
//  Copyright © 2018 mao. All rights reserved.
//

#import "MISFileScanner.h"
#import <CommonCrypto/CommonCrypto.h>


@interface MISFile()
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* path;
@property (nonatomic, assign) UInt64 size;
@end

@implementation MISFile

@end

@interface MISFileScanner()
@property (nonatomic, assign) BOOL delFlag;
@property (nonatomic, assign) UInt64 size;
@end

@implementation MISFileScanner

+ (MISFileScanner *)defaultScanner {
	static MISFileScanner* instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = MISFileScanner.new;
	});
	return instance;
}


/*列出文件目录*/
- (void)listFilesWithFilePath:(NSString* )filePath
			   toSizeFileInfo:(NSMutableDictionary *)sizeFilesInfo {
	NSError* error = nil;
	NSArray* names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:&error];
	if (error) {
		printf("** Error : %s **\n", error.localizedDescription.UTF8String);
		return;
	}
	
	for (NSString* name in names) {
		NSString* aFilePath = [filePath stringByAppendingPathComponent:name];
		BOOL flag = NO;
		if ([[NSFileManager defaultManager] fileExistsAtPath:aFilePath isDirectory:&flag]) {
			//文件夹，递归
			if (flag) {
				[self listFilesWithFilePath:aFilePath toSizeFileInfo:sizeFilesInfo];
			}else {
				NSError* error = nil;
				NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:aFilePath error:&error];
				UInt64 size = [fileAttributes[NSFileSize] longLongValue];
				
				//limit size fillter
				if (size < self.size) {
					continue;
				}
				
				MISFile* file = [[MISFile alloc] init];
				file.name  = name;
				file.path  = aFilePath;
				file.size = size;
				
				NSMutableArray* array = sizeFilesInfo[@(file.size)];
				if (!array) {
					array = NSMutableArray.array;
					sizeFilesInfo[@(file.size)] = array;
				}
				[array addObject:file];
				
				printf("%s   %s\n", [self stringWithSize:file.size].UTF8String, file.path.UTF8String);
			}
		}
	}
}

- (NSString *)stringWithSize:(UInt64)size {
	UInt64 kb = 1000;//for mac is 1000 for windows is 1024
	UInt64 mb = kb * kb;
	UInt64 gb = kb * kb * kb;
	
	//文件大小
	if (size > gb) {
		return [NSString stringWithFormat:@"%5.2fG", size / (double)gb];
	}else if (size > mb) {
		return [NSString stringWithFormat:@"%5.1fM", size / (double)(mb)];
	}else if (size > kb) {
		return [NSString stringWithFormat:@"%5.lldK", size / kb];
	}else {
		return [NSString stringWithFormat:@"%5lldB", size];
	}
}


/*扫描文件*/
- (void)scanFilePath:(NSString *)filePath
				size:(UInt64)size
			 delFlag:(BOOL)delFlag {
	//移除末尾多的"/"
	while ([filePath hasSuffix:@"/"]) {
		filePath = [filePath substringToIndex:filePath.length - 1];
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		printf("%s is not exists.\n", filePath.UTF8String);
		return;
	}
	
	//flag
	self.delFlag = delFlag;
	
	//size
	self.size = size;
	
	//文档根目录
	NSMutableDictionary* sizeFilesInfo = [NSMutableDictionary dictionary];
	
	//递归成一列
	printf("Scaning Files...\n");
	[self listFilesWithFilePath:filePath toSizeFileInfo:sizeFilesInfo];
	printf("\n");
	printf("Searching Repeated Files...\n");
	
	//find now
	NSArray* keys = [sizeFilesInfo.allKeys sortedArrayUsingSelector:@selector(compare:)];
	BOOL hasRepeated = NO;
	for (NSNumber* key in keys) {
		NSArray* files = sizeFilesInfo[key];
		if (files.count > 1) {
			//相同的文件大小的文件多于1个，可能重复 && 继续校验 hash
			NSMutableDictionary* md5FilesInfo = NSMutableDictionary.dictionary;
			for (MISFile* file in files) {
				NSData* md5 = [self md5With:file];
				NSMutableArray* array = md5FilesInfo[md5];
				if (!array) {
					array = NSMutableArray.array;
					md5FilesInfo[md5] = array;
				}
				[array addObject:file];
			}
			
			//超过2个的就是重复的
			for (NSArray* repeatedFiles in md5FilesInfo.allValues) {
				if (repeatedFiles.count > 1) {
					hasRepeated = YES;
					printf("---------------------------------------------------------------------------------------\n");
					if (self.delFlag) {
						MISFile* file = repeatedFiles.firstObject;
						printf("[+] %s\n", file.path.UTF8String);
						for (int i = 1; i < repeatedFiles.count; ++i) {
							file = repeatedFiles[i];
							NSError* error = nil;
							if ([NSFileManager.defaultManager removeItemAtPath:file.path error:&error]) {
								printf("[-] %s\n", file.path.UTF8String);
							}else {
								printf("** Delete error: %s **\n", error.localizedDescription.UTF8String);
							}
						}
					}else {
						for (int i = 0; i < repeatedFiles.count; ++i) {
							MISFile* file = repeatedFiles[i];
							printf("[%d] %s\n", (i + 1), file.path.UTF8String);
						}
					}
				}
			}
		}
	}
	
	if (!hasRepeated) {
		printf("No Repeated Files.\n");
	}else {
		printf("---------------------------------------------------------------------------------------\n");
	}
	
	printf("Done.\n");
}


- (NSData *)md5With:(MISFile *)file {
	//not null
	if (file.size == 0)
		return NSData.data;
	
	UInt8 MD5[CC_MD5_DIGEST_LENGTH];
	bzero(MD5, CC_MD5_DIGEST_LENGTH);
	CC_MD5_CTX ctx;
	CC_MD5_Init(&ctx);
	
	NSInteger bufferSize = 1024 * 1024 * 4;
	NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:file.path];
	UInt64 filesize = file.size;
	NSData* data = nil;
	UInt64 location = 0;
	do {
		@autoreleasepool {
			data = [handle readDataOfLength:bufferSize];
			CC_MD5_Update(&ctx, data.bytes, (CC_LONG)data.length);
			location += bufferSize;
		}
	} while (location < filesize);
	
	[handle closeFile];
	
	CC_MD5_Final(MD5, &ctx);
	
	return [NSData dataWithBytes:MD5 length:CC_MD5_DIGEST_LENGTH];
}


@end
