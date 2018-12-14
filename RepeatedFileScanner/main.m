//
//  main.m
//  DuplicateFileKiller
//
//  Created by Mao on 2018/12/14.
//  Copyright © 2018 mao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MISFileScanner.h"

void showUsage()
{
	printf("-------------------------------------------------------------\n");
	printf("rfs \n");
	printf("Repeated files scanner\n");
	printf("Author : Maokebing\n");
	printf("Version : 1.0\n");
	printf("-------------------------------------------------------------\n");
	printf("Usage:\n");
	printf("       rfs [-fsp] [args]\n");
	printf("      -f [file_path]\n");
	printf("      -s [size eg. only scan size of file > this arg]\n");
	printf("      -d [use delete flag it will del the repeated files]\n");
}

const char *short_opts = "f:s:d";

int main(int argc, const char * argv[]) {
	if (argc < 2) {
		showUsage();
		return 0;
	}
	
	char *arg_file     = NULL;
	char *arg_size     = NULL;
	BOOL delFlag = NO;
	char opt = 0;
	
	while ((opt = getopt(argc, argv, short_opts))!= -1 ) {
		switch (opt) {
			case 'f' :
				arg_file = optarg;
				break;
			case 's' :
				arg_size = optarg;
				break;
			case 'd' :
				delFlag = YES;
				break;
			default :
				return 1;
		}
	}
	
	if (arg_file == NULL) {
		showUsage();
		return 0;
	}
	
	//filepath
	NSString* filePath = [NSString stringWithUTF8String:arg_file];
	
	
	//size
	UInt64 size = 1;
	if (arg_size != NULL) {
		UInt64 kb = 1000;//for mac is 1000 for windows is 1024
		UInt64 mb = kb * kb;
		UInt64 gb = kb * kb * kb;
		
		NSString* sizeString = [NSString stringWithUTF8String:arg_size];
		sizeString = sizeString.uppercaseString;
		UInt64 value = [sizeString longLongValue];
		if (value == 0) {
			value = 1;
		}
		
		if ([sizeString hasSuffix:@"G"]) {
			size = value * gb;
		}else if ([sizeString hasSuffix:@"M"]) {
			size = value * mb;
		}else if ([sizeString hasSuffix:@"K"]) {
			size = value * kb;
		}else {
			size = value;
		}
	}
	
	@autoreleasepool {
		[MISFileScanner.defaultScanner scanFilePath:filePath size:size delFlag:delFlag];
	}
	return 0;
}
