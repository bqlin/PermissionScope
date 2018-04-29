//
//  Permission.h
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Permissions currently supportes by PermissionScope
typedef NS_ENUM(NSInteger, PermissionType) {
	PermissionTypeContacts = 0,
	PermissionTypeLocationAlways = 1,
	PermissionTypeLocationInUse = 2,
	PermissionTypeNotifications = 3,
	PermissionTypeMicrophone = 4,
	PermissionTypeCamera = 5,
	PermissionTypePhotos = 6,
	PermissionTypeReminders = 7,
	PermissionTypeEvents = 8,
	PermissionTypeBluetooth = 9,
	PermissionTypeMotion = 10,
};

NS_INLINE NSString *NSStringFromPermissionType(PermissionType type) {
	switch (type) {
		case PermissionTypeLocationAlways:{
			return @"LocationAlways";
		}break;
		case PermissionTypeLocationInUse:{
			return @"LocationInUse";
		} break;
		case PermissionTypeBluetooth:{
			return @"Bluetooth";
		} break;
		case PermissionTypeCamera:{
			return @"Camera";
		} break;
		case PermissionTypeContacts:{
			return @"Contacts";
		} break;
		case PermissionTypeEvents:{
			return @"Events";
		} break;
		case PermissionTypeMicrophone:{
			return @"Microphone";
		} break;
		case PermissionTypeMotion:{
			return @"Motion";
		} break;
		case PermissionTypeNotifications:{
			return @"Notifications";
		} break;
		case PermissionTypePhotos:{
			return @"Photos";
		} break;
		case PermissionTypeReminders:{
			return @"Reminders";
		} break;
	}
}

NS_INLINE NSString *PrettyDescriptionWithPermissionType(PermissionType type) {
	switch (type) {
		case PermissionTypeLocationAlways:
		case PermissionTypeLocationInUse:{
			return @"Location";
		} break;
		case PermissionTypeBluetooth:{
			return @"Bluetooth";
		} break;
		case PermissionTypeCamera:{
			return @"Camera";
		} break;
		case PermissionTypeContacts:{
			return @"Contacts";
		} break;
		case PermissionTypeEvents:{
			return @"Events";
		} break;
		case PermissionTypeMicrophone:{
			return @"Microphone";
		} break;
		case PermissionTypeMotion:{
			return @"Motion";
		} break;
		case PermissionTypeNotifications:{
			return @"Notifications";
		} break;
		case PermissionTypePhotos:{
			return @"Photos";
		} break;
		case PermissionTypeReminders:{
			return @"Reminders";
		} break;
	}
}

/// Possible statuses for a permission.
typedef NS_ENUM(NSInteger, PermissionStatus) {
	PermissionStatusAuthorized = 0,
	PermissionStatusUnauthorized = 1,
	PermissionStatusUnknown = 2,
	PermissionStatusDisabled = 3,
};

@interface PermissionResult : NSObject

@property (nonatomic, readonly) PermissionType type;
@property (nonatomic, readonly) PermissionStatus status;

- (instancetype)initWithType:(PermissionType)type status:(PermissionStatus)status;

@end

@protocol Permission
/// Permission type
@property (nonatomic, readonly) PermissionType type;
@end

typedef void(^PermissionRequestPermissionUnknownResult)(void);
typedef void(^PermissionRequestPermissionShowAlert)(PermissionType);

@class UIUserNotificationCategory;
@interface NotificationsPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;
@property (nonatomic, strong) NSSet<UIUserNotificationCategory *> *notificationCategories;

- (instancetype)initWithNotificationCategories:(NSSet<UIUserNotificationCategory *> *)notificationCategories;

@end

@interface LocationWhileInUsePermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface LocationAlwaysPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface ContactsPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface EventsPermission :NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface MicrophonePermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface CameraPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface PhotosPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface RemindersPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface BluetoothPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end

@interface MotionPermission : NSObject <Permission>

@property (nonatomic, readonly) PermissionType type;

@end
