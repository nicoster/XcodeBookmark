//
//  XcodeBookmark.h
//  XcodeBookmark
//
//  Created by Nick Xiao on 4/18/15.
//  Copyright (c) 2015 Nick Xiao. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface XcodeBookmark : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end