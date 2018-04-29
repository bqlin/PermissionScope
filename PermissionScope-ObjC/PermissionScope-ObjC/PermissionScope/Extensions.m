//
//  Extensions.m
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "Extensions.h"

@implementation UIColor (Extensions)

- (UIColor *)inverseColor {
	CGFloat r = .0, g = .0, b = .0, a = .0;
	if ([self getRed:&r green:&g blue:&b alpha:&a]) {
		return [UIColor colorWithRed:1 - r green:1 - g blue:1 - b alpha:a];
	}
	return self;
}

@end


@implementation NSString (Extensions)

- (NSString *)localized {
	return NSLocalizedString(self, "");
}

@end
