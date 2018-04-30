//
//  Constants.h
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

static const CGFloat ConstantsUIContentWidth = 280.0;
static const CGFloat ConstantsUIDialogHeightSinglePermission = 260.0;
static const CGFloat ConstantsUIDialogHeightTwoPermissions = 360.0;
static const CGFloat ConstantsUIDialogHeightThreePermissions = 460.0;

static NSString * const ConstantsNSUserDefaultsKeysRequestedInUseToAlwaysUpgrade = @"PS_requestedInUseToAlwaysUpgrade";
static NSString * const ConstantsNSUserDefaultsKeysRequestedBluetooth = @"PS_requestedBluetooth";
static NSString * const ConstantsNSUserDefaultsKeysRequestedMotion = @"PS_requestedMotion";
static NSString * const ConstantsNSUserDefaultsKeysRequestedNotifications = @"PS_requestedNotifications";

static NSString * const ConstantsInfoPlistKeysLocationWhenInUse = @"NSLocationWhenInUseUsageDescription";
static NSString * const ConstantsInfoPlistKeysLocationAlways = @"NSLocationAlwaysUsageDescription";

#define Xcode9 __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000

#if Xcode9
#define BQ_AVAILABLE(v) @available(iOS v, *)

#else
#define BQ_AVAILABLE(v) ([UIDevice currentDevice].systemVersion.floatValue > (v))

#endif

#endif /* Constants_h */
