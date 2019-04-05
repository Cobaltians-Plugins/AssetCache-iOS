//
//  NSString+MD5.h
//  Forms
//
//  Created by Vincent Rifa on 04/04/2019.
//  Copyright © 2019 Kristal. All rights reserved.
//  import from https://stackoverflow.com/questions/2018550/how-do-i-create-an-md5-hash-of-a-string-in-cocoa

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MD5)

- (NSString *)MD5String;

@end

NS_ASSUME_NONNULL_END
