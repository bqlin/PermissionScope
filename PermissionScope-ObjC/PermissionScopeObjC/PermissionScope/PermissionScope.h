//
//  PermissionScope.h
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Permission.h"

/// 授权结果回调
typedef void(^PermissionScopeAuthClosureType)(BOOL finished, NSArray<PermissionResult *> *results);

/// 取消回调
typedef void(^PermissionScopeCancelClosureType)(NSArray<PermissionResult *> *results);

@interface PermissionScope : UIViewController

/// Header UILabel with the message “Hey, listen!” by default.
@property (nonatomic, strong) UILabel *headerLabel;

/// Header UILabel with the message “We need a couple things\r\nbefore you get started.” by default.
@property (nonatomic, strong) UILabel *bodyLabel;

/// Color for the close button’s text color.
@property (nonatomic, strong) UIColor *closeButtonTextColor;

/// Color for the permission buttons’ text color.
@property (nonatomic, strong) UIColor *permissionButtonTextColor;

/// Color for the permission buttons’ border color.
@property (nonatomic, strong) UIColor *permissionButtonBorderColor;

/// Width for the permission buttons.
@property (nonatomic) CGFloat permissionButtonBorderWidth;

/// Corner radius for the permission buttons.
@property (nonatomic) CGFloat permissionButtonCornerRadius;

/// Color for the permission labels’ text color.
@property (nonatomic, strong) UIColor *permissionLabelColor;

/// Font used for all the UIButtons
@property (nonatomic, strong) UIFont *buttonFont;

/// Font used for all the UILabels
@property (nonatomic, strong) UIFont *labelFont;

/// Close button. By default in the top right corner.
@property (nonatomic, strong) UIButton *closeButton;

/// Offset used to position the Close button.
@property (nonatomic) CGSize closeOffset;

/// Color used for permission buttons with authorized status
@property (nonatomic, strong) UIColor *authorizedButtonColor;

/// Color used for permission buttons with unauthorized status. By default, inverse of <code>authorizedButtonColor</code>.
@property (nonatomic, strong) UIColor *unauthorizedButtonColor;

@property (nonatomic, readonly, strong) UIView *contentView;

/// Callback called when permissions status change.
@property (nonatomic, copy) PermissionScopeAuthClosureType onAuthChange;

/// Callback called when the user taps on the close button.
@property (nonatomic, copy) PermissionScopeCancelClosureType onCancel;

/// Called when the user has disabled or denied access to notifications, and we’re presenting them with a help dialog.
@property (nonatomic, copy) PermissionScopeCancelClosureType onDisabledOrDenied;

/// View controller to be used when presenting alerts. Defaults to self. You’ll want to set this if you are calling the <code>request*</code> methods directly.
@property (nonatomic, weak) UIViewController *viewControllerForAlerts;

/// Designated initializer.
/// \param backgroundTapCancels True if a tap on the background should trigger the dialog dismissal.
///
- (instancetype)initWithBackgroundTapCancels:(BOOL)backgroundTapCancels;

/// Adds a permission configuration to PermissionScope.
/// \param message Body label’s text on the presented dialog when requesting access.
///
- (void)addPermission:(id <Permission>)permission message:(NSString *)message;

/// Returns the current permission status for accessing LocationAlways.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusLocationAlways;

/// Requests access to LocationAlways, if necessary.
- (void)requestLocationAlways;

/// Returns the current permission status for accessing LocationWhileInUse.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusLocationInUse;

/// Requests access to LocationWhileInUse, if necessary.
- (void)requestLocationInUse;

/// Returns the current permission status for accessing Contacts.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusContacts;

/// Requests access to Contacts, if necessary.
- (void)requestContacts;

/// Returns the current permission status for accessing Notifications.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusNotifications;

/// Requests access to User Notifications, if necessary.
- (void)requestNotifications;

/// Returns the current permission status for accessing the Microphone.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusMicrophone;

/// Requests access to the Microphone, if necessary.
- (void)requestMicrophone;

/// Returns the current permission status for accessing the Camera.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusCamera;

/// Requests access to the Camera, if necessary.
- (void)requestCamera;

/// Returns the current permission status for accessing Photos.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusPhotos;

/// Requests access to Photos, if necessary.
- (void)requestPhotos;

/// Returns the current permission status for accessing Reminders.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusReminders;

/// Requests access to Reminders, if necessary.
- (void)requestReminders;

/// Returns the current permission status for accessing Events.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusEvents;

/// Requests access to Events, if necessary.
- (void)requestEvents;

/// Returns the current permission status for accessing Bluetooth.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusBluetooth;

/// Requests access to Bluetooth, if necessary.
- (void)requestBluetooth;
/// Returns the current permission status for accessing Core Motion Activity.
///
/// returns:
/// Permission status for the requested type.
- (PermissionStatus)statusMotion;

/// Requests access to Core Motion Activity, if necessary.
- (void)requestMotion;

/// Shows the modal viewcontroller for requesting access to the configured permissions and sets up the closures on it.
/// \param authChange Called when a status is detected on any of the permissions.
///
/// \param cancelled Called when the user taps the Close button.
///
- (void)show:(PermissionScopeAuthClosureType)authChange cancelled:(PermissionScopeCancelClosureType)cancelled;

/// Hides the modal viewcontroller with an animation.
- (void)hide;

@end
