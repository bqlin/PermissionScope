//
//  Extensions.h
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extensions)

@property (nonatomic, strong, readonly) UIColor *inverseColor;

@end


@interface NSString (Extensions)

@property (nonatomic, strong, readonly) NSString *localized;

@end
