//
//  Permission.m
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "Permission.h"
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <EventKit/EventKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <Contacts/Contacts.h>

@implementation PermissionResult

- (instancetype)initWithType:(PermissionType)type status:(PermissionStatus)status {
	if (self = [super init]) {
		_type = type;
		_status = status;
	}
	return self;
}

@end


@implementation NotificationsPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeNotifications;
	}
	return self;
}

- (instancetype)initWithNotificationCategories:(NSSet<UIUserNotificationCategory *> *)notificationCategories {
	if (self = [self init]) {
		_notificationCategories = notificationCategories;
	}
	return self;
}

@end

@implementation LocationWhileInUsePermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeLocationInUse;
	}
	return self;
}

@end

@implementation LocationAlwaysPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeLocationAlways;
	}
	return self;
}

@end

@implementation ContactsPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeContacts;
	}
	return self;
}

@end

@implementation EventsPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeEvents;
	}
	return self;
}

@end

@implementation MicrophonePermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeMicrophone;
	}
	return self;
}

@end

@implementation CameraPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeCamera;
	}
	return self;
}

@end

@implementation PhotosPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypePhotos;
	}
	return self;
}

@end

@implementation RemindersPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeReminders;
	}
	return self;
}

@end

@implementation BluetoothPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeBluetooth;
	}
	return self;
}

@end

@implementation MotionPermission

- (instancetype)init {
	if (self = [super init]) {
		_type = PermissionTypeMotion;
	}
	return self;
}

@end
