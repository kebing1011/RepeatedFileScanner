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
	printf("       rfs [file_path]\n");
}


int main(int argc, const char * argv[]) {
	if (argc < 2) {
		showUsage();
		return 0;
	}
	
	@autoreleasepool {
		[MISFileScanner.defaultScanner scanFilePath:[NSString stringWithUTF8String:argv[1]]];
	}
	return 0;
}
