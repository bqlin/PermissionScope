//
//  PermissionScope.m
//  PermissionScope-ObjC
//
//  Created by Bq Lin on 2018/4/26.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "PermissionScope.h"
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <EventKit/EventKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <Contacts/Contacts.h>
#import "Extensions.h"
#import "Constants.h"
#import "Permission.h"

/// 配置处理
typedef void(^PermissionScopeResultsForConfigClosure)(NSArray<PermissionResult *> *results);

/// 权限请求回调
typedef void(^PermissionScopeStatusRequestClosure)(PermissionStatus status);

@interface PermissionScope () <CBPeripheralManagerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate>

/// Messages for the body label of the dialog presented when requesting access.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *permissionMessages;

@property (nonatomic, strong, readonly) UIView *baseView;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) CBPeripheralManager *bluetoothManager;

@property (nonatomic, strong) CMMotionActivityManager *motionManager;

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, assign) PermissionStatus motionPermissionStatus;

@property (nonatomic, strong) NSMutableArray<id<Permission>> *configuredPermissions;

@property (nonatomic, strong) NSMutableArray<UIButton *> *permissionButtons;

@property (nonatomic, strong) NSMutableArray<UILabel *> *permissionLabels;

/// Returns whether Bluetooth access was asked before or not.
@property (nonatomic, assign) BOOL askedBluetooth;

/// Returns whether PermissionScope is waiting for the user to enable/disable bluetooth access or not.
@property (nonatomic, assign) BOOL waitingForBluetooth;

/// Returns whether Bluetooth access was asked before or not.
@property (nonatomic, assign) BOOL askedMotion;

/// Returns whether PermissionScope is waiting for the user to enable/disable motion access or not.
@property (nonatomic, assign) BOOL waitingForMotion;


/**
 A timer that fires the event to let us know the user has asked for
 notifications permission.
 */
@property (nonatomic, strong) NSTimer *notificationTimer;

@end

@implementation PermissionScope

#pragma mark - dealloc & init

- (instancetype)init {
	if (self = [self initWithBackgroundTapCancels:YES]) {}
	return self;
}

- (instancetype)initWithBackgroundTapCancels:(BOOL)backgroundTapCancels {
	if (self = [super initWithNibName:nil bundle:nil]) {
		[self commonInit];
		self.viewControllerForAlerts = self;
		
		// Set up main view
		self.view.frame = [UIScreen mainScreen].bounds;
		self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
		[self.view addSubview:self.baseView];
		// Base View
		self.baseView.frame = self.view.frame;
		[self.baseView addSubview:self.contentView];
		if (backgroundTapCancels) {
			UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancel)];
			tap.delegate = self;
			[self.baseView addGestureRecognizer:tap];
		}
		// Content View
		self.contentView.backgroundColor = [UIColor whiteColor];
		self.contentView.layer.cornerRadius = 10;
		self.contentView.layer.masksToBounds = YES;
		self.contentView.layer.borderWidth = 0.5;
		
		// header label
		self.headerLabel.font = [UIFont systemFontOfSize:22];
		self.headerLabel.textColor = [UIColor blackColor];
		self.headerLabel.textAlignment = NSTextAlignmentCenter;
		self.headerLabel.text = @"Hey, listen!".localized;
		self.headerLabel.accessibilityIdentifier = @"permissionscope.headerlabel";
		
		[self.contentView addSubview:self.headerLabel];
		
		// body label
		self.bodyLabel.font = [UIFont boldSystemFontOfSize:16];
		self.bodyLabel.textColor = [UIColor blackColor];
		self.bodyLabel.textAlignment = NSTextAlignmentCenter;
		self.bodyLabel.text = @"We need a couple things\r\nbefore you get started.".localized;
		self.bodyLabel.numberOfLines = 2;
		self.bodyLabel.accessibilityIdentifier = @"permissionscope.bodylabel";
		
		[self.contentView addSubview:self.bodyLabel];
		
		// close button
		[self.closeButton setTitle:@"Close" forState:UIControlStateNormal];
		[self.closeButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
		self.closeButton.accessibilityIdentifier = @"permissionscope.closeButton";
		
		[self.contentView addSubview:self.closeButton];
		
		[self statusMotion]; //Added to check motion status on load
	}
	return self;
}

- (void)commonInit {
//	public var headerLabel                 = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
	_headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
//	public var bodyLabel                   = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 70))
	_bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 240, 70)];
//	public var closeButtonTextColor        = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
	_closeButtonTextColor = [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
//	public var permissionButtonTextColor   = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
	_permissionButtonTextColor = [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
//	public var permissionButtonBorderColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
	_permissionButtonBorderColor = [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1];
//	public var permissionButtonBorderWidth  : CGFloat = 1
	_permissionButtonBorderWidth = 1;
//	public var permissionButtonCornerRadius : CGFloat = 6
	_permissionButtonCornerRadius = 6;
//	public var permissionLabelColor:UIColor = .black
	_permissionLabelColor = [UIColor blackColor];
//	public var buttonFont:UIFont            = .boldSystemFont(ofSize: 14)
	_buttonFont = [UIFont boldSystemFontOfSize:14];
//	public var labelFont:UIFont             = .systemFont(ofSize: 14)
	_labelFont = [UIFont systemFontOfSize:14];
//	public var closeButton                  = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 32))
	_closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 32)];
//	public var closeOffset                  = CGSize.zero
	_closeOffset = CGSizeZero;
//	public var authorizedButtonColor        = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
	_authorizedButtonColor = [UIColor colorWithRed:0 green:.47 blue:1 alpha:1];
//	public var unauthorizedButtonColor:UIColor?
	
	// MARK: View hierarchy for custom alert
//	let baseView    = UIView()
	_baseView = [UIView new];
//	public let contentView = UIView()
	_contentView = [UIView new];
	
	_motionPermissionStatus = PermissionStatusUnknown;

	// MARK: - Internal state and resolution

	/// Permissions configured using `addPermission(:)`
//	var configuredPermissions: [Permission] = []
	_configuredPermissions = [NSMutableArray array];
//	var permissionButtons: [UIButton]       = []
	_permissionButtons = [NSMutableArray array];
//	var permissionLabels: [UILabel]         = []
	_permissionLabels = [NSMutableArray array];
}

#pragma mark - property

//	lazy var permissionMessages: [PermissionType : String] = [PermissionType : String]()
- (NSMutableDictionary<NSNumber *,NSString *> *)permissionMessages {
	if (!_permissionMessages) {
		_permissionMessages = [NSMutableDictionary dictionary];
	}
	return _permissionMessages;
}

- (CLLocationManager *)locationManager {
	if (!_locationManager) {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
	}
	return _locationManager;
}

- (CBPeripheralManager *)bluetoothManager {
	if (!_bluetoothManager) {
		_bluetoothManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(NO)}];
	}
	return _bluetoothManager;
}

- (CMMotionActivityManager *)motionManager {
	if (!_motionManager) {
		_motionManager = [[CMMotionActivityManager alloc] init];
	}
	return _motionManager;
}

- (NSUserDefaults *)defaults {
	if (!_defaults) {
		_defaults = [NSUserDefaults standardUserDefaults];
	}
	return _defaults;
}

- (BOOL)askedBluetooth {
	return [self.defaults boolForKey:ConstantsNSUserDefaultsKeysRequestedBluetooth];
}
- (void)setAskedBluetooth:(BOOL)askedBluetooth {
	[self.defaults setBool:askedBluetooth forKey:ConstantsNSUserDefaultsKeysRequestedBluetooth];
	[self.defaults synchronize];
}

- (BOOL)askedMotion {
	return [self.defaults boolForKey:ConstantsNSUserDefaultsKeysRequestedMotion];
}
- (void)setAskedMotion:(BOOL)askedMotion {
	[self.defaults setBool:askedMotion forKey:ConstantsNSUserDefaultsKeysRequestedMotion];
	[self.defaults synchronize];
}

#pragma mark - view controller

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	// Set background frame
	self.view.frame = (CGRect){self.view.frame.origin, screenSize};
	// Set frames
	CGFloat x = (screenSize.width - ConstantsUIContentWidth) / 2;

	CGFloat dialogHeight;
	switch (self.configuredPermissions.count) {
		case 2:{
			dialogHeight = ConstantsUIDialogHeightTwoPermissions;
		} break;
		case 3:{
			dialogHeight = ConstantsUIDialogHeightThreePermissions;
		} break;
		default:{
			dialogHeight = ConstantsUIDialogHeightSinglePermission;
		} break;
	}
	
	CGFloat y = (screenSize.height - dialogHeight) / 2;
	self.contentView.frame = CGRectMake(x, y, ConstantsUIContentWidth, dialogHeight);
	
	// offset the header from the content center, compensate for the content's offset
	self.headerLabel.center = self.contentView.center;
	self.headerLabel.frame = CGRectOffset(self.headerLabel.frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
	self.headerLabel.frame = CGRectOffset(self.headerLabel.frame, 0, -((dialogHeight/2)-50));
	
	// ... same with the body
	self.bodyLabel.center = self.contentView.center;
	self.bodyLabel.frame = CGRectOffset(self.bodyLabel.frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
	self.bodyLabel.frame = CGRectOffset(self.bodyLabel.frame, 0, -((dialogHeight/2)-100));
	
	self.closeButton.center = self.contentView.center;
	self.closeButton.frame = CGRectOffset(self.closeButton.frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
	self.closeButton.frame = CGRectOffset(self.closeButton.frame, 105, -((dialogHeight/2)-20));
	self.closeButton.frame = CGRectOffset(self.closeButton.frame, self.closeOffset.width, self.closeOffset.height);
	if (self.closeButton.imageView.image) [self.closeButton setTitle:@"" forState:UIControlStateNormal];
	[self.closeButton setTitleColor:self.closeButtonTextColor forState:UIControlStateNormal];
	
	CGFloat baseOffset = 95;
	__block NSInteger index = 0;
	for (UIButton *button in self.permissionButtons) {
		button.center = self.contentView.center;
		button.frame = CGRectOffset(button.frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
		button.frame = CGRectOffset(button.frame, 0, -((dialogHeight/2)-160) + index * baseOffset);
		
		PermissionType type = self.configuredPermissions[index].type;
		
		[self statusForPermission:type completion:^(PermissionStatus currentStatus) {
			NSString *prettyDescription = PrettyDescriptionWithPermissionType(type);
			if (currentStatus == PermissionStatusAuthorized) {
				[self setButtonAuthorizedStyle:button];
				[button setTitle:[NSString stringWithFormat:@"Allowed %@", prettyDescription].localized.uppercaseString forState:UIControlStateNormal];
			} else if (currentStatus == PermissionStatusUnauthorized) {
				[self setButtonUnauthorizedStyle:button];
				[button setTitle:[NSString stringWithFormat:@"Denied %@", prettyDescription].localized.uppercaseString forState:UIControlStateNormal];
			} else if (currentStatus == PermissionStatusDisabled) {
				//                setButtonDisabledStyle(button)
				[button setTitle:[NSString stringWithFormat:@"%@ Disabled", prettyDescription].localized.uppercaseString forState:UIControlStateNormal];
			}
			
			UILabel *label = self.permissionLabels[index];
			label.center = self.contentView.center;
			label.frame = CGRectOffset(label.frame, -self.contentView.frame.origin.x, -self.contentView.frame.origin.y);
			label.frame = CGRectOffset(label.frame, 0, -((dialogHeight/2)-205) + index * baseOffset);
			
			index = index + 1;
		}];
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - public

// MARK: UI

/**
 Shows the modal viewcontroller for requesting access to the configured permissions and sets up the closures on it.
 
 - parameter authChange: Called when a status is detected on any of the permissions.
 - parameter cancelled:  Called when the user taps the Close button.
 */
- (void)show:(PermissionScopeAuthClosureType)authChange cancelled:(PermissionScopeCancelClosureType)cancelled {
	NSAssert(self.configuredPermissions.count, @"Please add at least one permission");
	self.onAuthChange = authChange;
	self.onCancel = cancelled;
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		while (self.waitingForBluetooth || self.waitingForMotion) { }
		// call other methods that need to wait before show
		// no missing required perms? callback and do nothing
		[self requiredAuthorized:^(BOOL areAuthorized) {
			if (areAuthorized) {
				[weakSelf getResultsForConfig:^(NSArray<PermissionResult *> *results) {
					if (weakSelf.onAuthChange) self.onAuthChange(YES, results);
				}];
			} else {
				[weakSelf showAlert];
			}
		}];
	});
}
/**
 Hides the modal viewcontroller with an animation.
 */
- (void)hide {
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	dispatch_async(dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:0.2 animations:^{
			CGRect baseViewFrame = self.baseView.frame;
			baseViewFrame.origin.y = window.center.y + 400;
			self.baseView.frame = baseViewFrame;
			self.view.alpha = 0;
		} completion:^(BOOL finished) {
			[self.view removeFromSuperview];
		}];
	});
	
	[self.notificationTimer invalidate];
	self.notificationTimer = nil;
}

// MARK: - Status and Requests for each permission

// MARK: Location

/**
 Returns the current permission status for accessing LocationAlways.
 
 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusLocationAlways {
	if (![CLLocationManager locationServicesEnabled]) return PermissionStatusDisabled;
	
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	switch (status) {
		case kCLAuthorizationStatusAuthorizedAlways:{
			return PermissionStatusAuthorized;
		} break;
		case kCLAuthorizationStatusRestricted:
		case kCLAuthorizationStatusDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case kCLAuthorizationStatusAuthorizedWhenInUse:{
			// Curious why this happens? Details on upgrading from WhenInUse to Always:
			// [Check this issue](https://github.com/nickoneill/PermissionScope/issues/24)
			if ([self.defaults boolForKey:ConstantsNSUserDefaultsKeysRequestedInUseToAlwaysUpgrade]) {
				return PermissionStatusUnauthorized;
			} else {
				return PermissionStatusUnknown;
			}
		} break;
		case kCLAuthorizationStatusNotDetermined:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to LocationAlways, if necessary.
 */
- (void)requestLocationAlways {
	BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:ConstantsInfoPlistKeysLocationAlways] != nil;
	NSAssert(hasAlwaysKey, @"%@ not found in Info.plist.", ConstantsInfoPlistKeysLocationAlways);
	
	PermissionStatus status = [self statusLocationAlways];
	switch (status) {
		case PermissionStatusUnknown:{
			if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
				[self.defaults setBool:YES forKey:ConstantsNSUserDefaultsKeysRequestedInUseToAlwaysUpgrade];
				[self.defaults synchronize];
			}
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeLocationAlways];
		} break;
		case PermissionStatusDisabled:{
			[self showDeniedAlert:PermissionTypeLocationInUse];
		} break;
		default:{} break;
	}
}

/**
 Returns the current permission status for accessing LocationWhileInUse.
 
 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusLocationInUse {
	if (![CLLocationManager locationServicesEnabled]) return PermissionStatusDisabled;

	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	// if you're already "always" authorized, then you don't need in use
	// but the user can still demote you! So I still use them separately.
	switch (status) {
		case kCLAuthorizationStatusAuthorizedWhenInUse:
		case kCLAuthorizationStatusAuthorizedAlways:{
			return PermissionStatusAuthorized;
		} break;
		case kCLAuthorizationStatusRestricted:
		case kCLAuthorizationStatusDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case kCLAuthorizationStatusNotDetermined:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to LocationWhileInUse, if necessary.
 */
- (void)requestLocationInUse {
	bool hasWhenInUseKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:ConstantsInfoPlistKeysLocationWhenInUse] != nil;
	NSAssert(hasWhenInUseKey, @"%@ not found in Info.plist.", ConstantsInfoPlistKeysLocationWhenInUse);

	PermissionStatus status = [self statusLocationInUse];
	switch (status) {
		case PermissionStatusUnknown:{
			[self.locationManager requestWhenInUseAuthorization];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeLocationInUse];
		} break;
		case PermissionStatusDisabled:{
			[self showDisabledAlert:PermissionTypeLocationInUse];
		} break;
		default:{} break;
	}
}

// MARK: - Customizing the permissions

/**
 Adds a permission configuration to PermissionScope.
 
 - parameter message: Body label's text on the presented dialog when requesting access.
 */
- (void)addPermission:(id<Permission>)permission message:(NSString *)message {
	NSAssert(message.length, @"Including a message about your permission usage is helpful");
	NSAssert(self.configuredPermissions.count < 3, @"Ask for three or fewer permissions at a time");
	for (id<Permission> configuredPermission in self.configuredPermissions) {
		NSCAssert(configuredPermission.type != permission.type, @"Permission for %@ already set", PrettyDescriptionWithPermissionType(permission.type));
	}
	[self.configuredPermissions addObject:permission];
	self.permissionMessages[@(permission.type)] = message;
	
	if (permission.type == PermissionTypeBluetooth && self.askedBluetooth) {
		[self triggerBluetoothStatusUpdate];
	} else if (permission.type == PermissionTypeMotion && self.askedMotion) {
		[self triggerMotionStatusUpdate];
	}
}

// use the code we have to see permission status
- (NSDictionary<NSNumber *, NSNumber *> *)permissionStatuses:(NSArray<NSNumber *> *)permissionTypes {
	NSMutableDictionary *statuses = [NSMutableDictionary dictionary];
	NSArray *types = permissionTypes ? permissionTypes :
  @[
	@(PermissionTypeContacts),
	@(PermissionTypeLocationAlways),
	@(PermissionTypeLocationInUse),
	@(PermissionTypeNotifications),
	@(PermissionTypeMicrophone),
	@(PermissionTypeCamera),
	@(PermissionTypePhotos),
	@(PermissionTypeReminders),
	@(PermissionTypeEvents),
	@(PermissionTypeBluetooth),
	@(PermissionTypeMotion),
	];
	
	for (NSNumber *type in types) {
		[self statusForPermission:type.integerValue completion:^(PermissionStatus status) {
			statuses[type] = @(status);
		}];
	}
	return statuses;
}

// MARK: Contacts

/**
 Returns the current permission status for accessing Contacts.
 
 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusContacts {
	if (BQ_AVAILABLE(9)) {
		CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
		switch (status) {
			case CNAuthorizationStatusAuthorized:{
				return PermissionStatusAuthorized;
			} break;
			case CNAuthorizationStatusRestricted:
			case CNAuthorizationStatusDenied:{
				return PermissionStatusUnauthorized;
			} break;
			case CNAuthorizationStatusNotDetermined:{
				return PermissionStatusUnknown;
			} break;
		}
	} else {
		// Fallback on earlier versions
		ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
		switch (status) {
			case kABAuthorizationStatusAuthorized:{
				return PermissionStatusAuthorized;
			} break;
			case kABAuthorizationStatusRestricted:
			case kABAuthorizationStatusDenied:{
				return PermissionStatusUnauthorized;
			} break;
			case kABAuthorizationStatusNotDetermined:{
				return PermissionStatusUnknown;
			} break;
		}
	}
}

/**
 Requests access to Contacts, if necessary.
 */
- (void)requestContacts {
	PermissionStatus status = [self statusContacts];
	switch (status) {
		case PermissionStatusUnknown:{
			__weak typeof(self) weakSelf = self;
			if (BQ_AVAILABLE(9)) {
				[[[CNContactStore alloc] init] requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
					[weakSelf detectAndCallback];
				}];
			} else {
				ABAddressBookRequestAccessWithCompletion(nil, ^(bool granted, CFErrorRef error) {
					[weakSelf detectAndCallback];
				});
			}
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeContacts];
		} break;
		default:{} break;
	}
}

// MARK: Notifications

/**
 Returns the current permission status for accessing Notifications.
 
 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusNotifications {
	UIUserNotificationSettings *settings = [UIApplication sharedApplication].currentUserNotificationSettings;
	if (settings.types || settings.types != UIUserNotificationTypeNone) {
		return PermissionStatusAuthorized;
	} else {
		if ([self.defaults boolForKey:ConstantsNSUserDefaultsKeysRequestedNotifications]) {
			return PermissionStatusUnauthorized;
		} else {
			return PermissionStatusUnknown;
		}
	}
}

/**
 To simulate the denied status for a notifications permission,
 we track when the permission has been asked for and then detect
 when the app becomes active again. If the permission is not granted
 immediately after becoming active, the user has cancelled or denied
 the request.
 
 This function is called when we want to show the notifications
 alert, kicking off the entire process.
 */
- (void)showingNotificationPermission {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedShowingNotificationPermission) name:UIApplicationDidBecomeActiveNotification object:nil];
	[self.notificationTimer invalidate];
}

/**
 This function is triggered when the app becomes 'active' again after
 showing the notification permission dialog.
 
 See `showingNotificationPermission` for a more detailed description
 of the entire process.
 */
- (void)finishedShowingNotificationPermission {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[self.notificationTimer invalidate];
	
	[self.defaults setBool:YES forKey:ConstantsNSUserDefaultsKeysRequestedNotifications];
	[self.defaults synchronize];
	
	// callback after a short delay, otherwise notifications don't report proper auth
	__weak typeof(self) weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
		[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
			PermissionResult *notificationResult = nil;
			for (PermissionResult *result in results) {
				if (result.type == PermissionTypeNotifications) {
					notificationResult = result;
					break;
				}
			}
			if (!notificationResult) return;
			if (notificationResult.status == PermissionStatusUnknown) {
				[weakSelf showDeniedAlert:notificationResult.type];
			} else {
				[weakSelf detectAndCallback];
			}
		}];
	});

}

/**
 Requests access to User Notifications, if necessary.
 */
- (void)requestNotifications {
	PermissionStatus status = [self statusNotifications];
	switch (status) {
		case PermissionStatusUnknown:{
			NotificationsPermission *notificationsPermission = nil;
			for (NSObject<Permission> *permission in self.configuredPermissions) {
				if ([permission isKindOfClass:[NotificationsPermission class]]) {
					notificationsPermission = (NotificationsPermission *)permission;
					break;
				}
			}
			NSSet<UIUserNotificationCategory *> *notificationsPermissionSet = notificationsPermission.notificationCategories;
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showingNotificationPermission) name:UIApplicationWillResignActiveNotification object:nil];
			self.notificationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(finishedShowingNotificationPermission) userInfo:nil repeats:NO];
			[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge categories:notificationsPermissionSet]];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeNotifications];
		} break;
		case PermissionStatusDisabled:{
			[self showDisabledAlert:PermissionTypeNotifications];
		} break;
		case PermissionStatusAuthorized:{
			[self detectAndCallback];
		} break;
	}
}

// MARK: Microphone

/**
 Returns the current permission status for accessing the Microphone.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusMicrophone {
	AVAudioSessionRecordPermission recordPermission = [AVAudioSession sharedInstance].recordPermission;
	switch (recordPermission) {
		case AVAudioSessionRecordPermissionDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case AVAudioSessionRecordPermissionGranted:{
			return PermissionStatusAuthorized;
		} break;
		default:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to the Microphone, if necessary.
 */
- (void)requestMicrophone {
	PermissionStatus status = [self statusMicrophone];
	switch (status) {
		case PermissionStatusUnknown:{
			__weak typeof(self) weakSelf = self;
			[[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
				[weakSelf detectAndCallback];
			}];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeMicrophone];
		} break;
		case PermissionStatusDisabled:{
			[self showDisabledAlert:PermissionTypeMicrophone];
		} break;
		case PermissionStatusAuthorized:{} break;
	}
}

// MARK: Camera

/**
 Returns the current permission status for accessing the Camera.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusCamera {
	AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	switch (status) {
		case AVAuthorizationStatusAuthorized:{
			return PermissionStatusAuthorized;
		} break;
		case AVAuthorizationStatusRestricted:
		case AVAuthorizationStatusDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case AVAuthorizationStatusNotDetermined:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to the Camera, if necessary.
 */
- (void)requestCamera {
	PermissionStatus status = [self statusCamera];
	switch (status) {
		case PermissionStatusUnknown:{
			__weak typeof(self) weakSelf = self;
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
				[weakSelf detectAndCallback];
			}];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeCamera];
		} break;
		case PermissionStatusDisabled:{
			[self showDisabledAlert:PermissionTypeCamera];
		} break;
		case PermissionStatusAuthorized:{} break;
	}
}

// MARK: Photos

/**
 Returns the current permission status for accessing Photos.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusPhotos {
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	switch (status) {
		case PHAuthorizationStatusAuthorized:{
			return PermissionStatusAuthorized;
		} break;
		case PHAuthorizationStatusDenied:
		case PHAuthorizationStatusRestricted:{
			return PermissionStatusUnauthorized;
		} break;
		case PHAuthorizationStatusNotDetermined:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to Photos, if necessary.
 */
- (void)requestPhotos {
	PermissionStatus status = [self statusPhotos];
	switch (status) {
		case PermissionStatusUnknown:{
			__weak typeof(self) weakSelf = self;
			[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
				[weakSelf detectAndCallback];
			}];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypePhotos];
		} break;
		case PermissionStatusDisabled:{
			[self showDisabledAlert:PermissionTypePhotos];
		} break;
		case PermissionStatusAuthorized:{} break;
	}
}

// MARK: Reminders

/**
 Returns the current permission status for accessing Reminders.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusReminders {
	EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
	switch (status) {
		case EKAuthorizationStatusAuthorized:{
			return PermissionStatusAuthorized;
		} break;
		case EKAuthorizationStatusRestricted:
		case EKAuthorizationStatusDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case EKAuthorizationStatusNotDetermined:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to Reminders, if necessary.
 */
- (void)requestReminders {
	PermissionStatus status = [self statusReminders];
	switch (status) {
		case PermissionStatusUnknown:{
			__weak typeof(self) weakSelf = self;
			[[[EKEventStore alloc] init] requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
				[weakSelf detectAndCallback];
			}];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeReminders];
		} break;
		default:{} break;
	}
}

// MARK: Events

/**
 Returns the current permission status for accessing Events.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusEvents {
	EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
	switch (status) {
		case EKAuthorizationStatusAuthorized:{
			return PermissionStatusAuthorized;
		} break;
		case EKAuthorizationStatusRestricted:
		case EKAuthorizationStatusDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case EKAuthorizationStatusNotDetermined:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to Events, if necessary.
 */
- (void)requestEvents {
	PermissionStatus status = [self statusEvents];
	switch (status) {
		case PermissionStatusUnknown:{
			__weak typeof(self) weakSelf = self;
			[[[EKEventStore alloc] init] requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
				[weakSelf detectAndCallback];
			}];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeEvents];
		} break;
		default:{} break;
	}
}

// MARK: Bluetooth

/**
 Returns the current permission status for accessing Bluetooth.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusBluetooth {
	// if already asked for bluetooth before, do a request to get status, else wait for user to request
	if (self.askedBluetooth) {
		[self triggerBluetoothStatusUpdate];
	} else {
		return PermissionStatusUnknown;
	}

	CBPeripheralManagerAuthorizationStatus authorizationStatus = [CBPeripheralManager authorizationStatus];
	switch (authorizationStatus) {
		case CBPeripheralManagerAuthorizationStatusRestricted:{
			return PermissionStatusDisabled;
		} break;
		case CBPeripheralManagerAuthorizationStatusDenied:{
			return PermissionStatusUnauthorized;
		} break;
		case CBPeripheralManagerAuthorizationStatusAuthorized:{
			return PermissionStatusAuthorized;
		} break;
		default:{} break;
	}
	CBPeripheralManagerState state = (CBPeripheralManagerState)self.bluetoothManager.state;
	switch (state) {
		case CBPeripheralManagerStateUnsupported:
		case CBPeripheralManagerStatePoweredOff:{
			return PermissionStatusDisabled;
		} break;
		case CBPeripheralManagerStateUnauthorized:{
			return PermissionStatusUnauthorized;
		} break;
		case CBPeripheralManagerStatePoweredOn:{
			return PermissionStatusAuthorized;
		} break;
		default:{
			return PermissionStatusUnknown;
		} break;
	}
}

/**
 Requests access to Bluetooth, if necessary.
 */
- (void)requestBluetooth {
	PermissionStatus status = [self statusBluetooth];
	switch (status) {
		case PermissionStatusDisabled:{
			[self showDisabledAlert:PermissionTypeBluetooth];
		} break;
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeBluetooth];
		} break;
		case PermissionStatusUnknown:{
			[self triggerBluetoothStatusUpdate];
		} break;
		default:{} break;
	}
}

// MARK: Core Motion Activity

/**
 Returns the current permission status for accessing Core Motion Activity.

 - returns: Permission status for the requested type.
 */
- (PermissionStatus)statusMotion {
	if (self.askedMotion) {
		[self triggerMotionStatusUpdate];
	}
	return self.motionPermissionStatus;
}

/**
 Requests access to Core Motion Activity, if necessary.
 */
- (void)requestMotion {
	PermissionStatus status = [self statusMotion];
	switch (status) {
		case PermissionStatusUnauthorized:{
			[self showDeniedAlert:PermissionTypeMotion];
		} break;
		case PermissionStatusUnknown:{
			[self triggerMotionStatusUpdate];
		} break;
		default:{} break;
	}
}

#pragma mark - private

// MARK: - UI

/**
 Creates the modal viewcontroller and shows it.
 */
- (void)showAlert {
	// add the backing views
	UIWindow *window = [UIApplication sharedApplication].keyWindow;

	//hide KB if it is shown
	[window endEditing:YES];

	[window addSubview:self.view];
	self.view.frame = window.bounds;
	self.baseView.frame = window.bounds;

	for (UIButton *button in self.permissionButtons) {
		[button removeFromSuperview];
	}
	self.permissionButtons = [NSMutableArray array];

	for (UILabel *label in self.permissionLabels) {
		[label removeFromSuperview];
	}
	self.permissionLabels = [NSMutableArray array];

	// create the buttons
	for (id<Permission> permission in self.configuredPermissions) {
		UIButton *button = [self permissionStyledButton:permission.type];
		[self.permissionButtons addObject:button];
		[self.contentView addSubview:button];

		UILabel *label = [self permissionStyledLabel:permission.type];
		[self.permissionLabels addObject:label];
		[self.contentView addSubview:label];
	}

	[self.view setNeedsLayout];

	// slide in the view
	CGRect baseViewFrame = self.baseView.frame;
	baseViewFrame.origin.y = self.view.bounds.origin.y - self.baseView.frame.size.height;
	self.baseView.frame = baseViewFrame;
	self.view.alpha = 0;

	[UIView animateWithDuration:0.2 animations:^{
		CGPoint baseViewCenter = self.baseView.center;
		baseViewCenter.y = window.center.y + 15;
		self.baseView.center = baseViewCenter;
		self.view.alpha = 1;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.2 animations:^{
			self.baseView.center = window.center;
		}];
	}];
}

// MARK: - Delegates

// MARK: Gesture delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	// this prevents our tap gesture from firing for subviews of baseview
	if (touch.view == self.baseView) {
		return YES;
	}
	return NO;
}

// MARK: Location delegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	[self detectAndCallback];
}

// MARK: Bluetooth delegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
	self.waitingForBluetooth = NO;
	[self detectAndCallback];
}

// MARK: - UI Helpers

/**
 Called when the users taps on the close button.
 */
- (void)cancel {
	[self hide];
	
	if (self.onCancel) {
		__weak typeof(self) weakSelf = self;
		[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
			weakSelf.onCancel(results);
		}];
	}
}

/**
 Shows an alert for a permission which was Denied.
 
 - parameter permission: Permission type.
 */
- (void)showDeniedAlert:(PermissionType)permission {
	// compile the results and pass them back if necessary
	if (self.onDisabledOrDenied) {
		__weak typeof(self) weakSelf = self;
		[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
			weakSelf.onDisabledOrDenied(results);
		}];
	}

	NSString *title = [NSString stringWithFormat:@"Permission for %@ was denied.", PrettyDescriptionWithPermissionType(permission)].localized;
	NSString *message = [NSString stringWithFormat:@"Please enable access to %@ in the Settings app", PrettyDescriptionWithPermissionType(permission)].localized;
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK".localized style:UIAlertActionStyleCancel handler:nil]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Show me".localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appForegroundedAfterSettings) name:UIApplicationDidBecomeActiveNotification object:nil];
		
		NSURL *settingsUrl = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
		[[UIApplication sharedApplication] openURL:settingsUrl];
	}]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.viewControllerForAlerts presentViewController:alert animated:YES completion:nil];
	});
}

/**
 Shows an alert for a permission which was Disabled (system-wide).
 
 - parameter permission: Permission type.
 */
- (void)showDisabledAlert:(PermissionType)permission {
	// compile the results and pass them back if necessary
	if (self.onDisabledOrDenied) {
		__weak typeof(self) weakSelf = self;
		[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
			weakSelf.onDisabledOrDenied(results);
		}];
	}
	
	NSString *title = [NSString stringWithFormat:@"%@ is currently disabled.", PrettyDescriptionWithPermissionType(permission)].localized;
	NSString *message = [NSString stringWithFormat:@"Please enable access to %@ in the Settings app", PrettyDescriptionWithPermissionType(permission)].localized;
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK".localized style:UIAlertActionStyleCancel handler:nil]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Show me".localized style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appForegroundedAfterSettings) name:UIApplicationDidBecomeActiveNotification object:nil];
		
		NSURL *settingsUrl = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
		[[UIApplication sharedApplication] openURL:settingsUrl];
	}]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.viewControllerForAlerts presentViewController:alert animated:YES completion:nil];
	});
}

/**
 Permission button factory. Uses the custom style parameters such as `permissionButtonTextColor`, `buttonFont`, etc.
 
 - parameter type: Permission type
 
 - returns: UIButton instance with a custom style.
 */
- (UIButton *)permissionStyledButton:(PermissionType)type {
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
	[button setTitleColor:self.permissionButtonTextColor forState:UIControlStateNormal];
	button.titleLabel.font = [self buttonFont];
	
	button.layer.borderWidth = self.permissionButtonBorderWidth;
	button.layer.borderColor = self.permissionButtonBorderColor.CGColor;
	button.layer.cornerRadius = self.permissionButtonCornerRadius;
	
	// this is a bit of a mess, eh?
	switch (type) {
		case PermissionTypeLocationAlways:
		case PermissionTypeLocationInUse:{
			[button setTitle:[NSString stringWithFormat:@"Enable %@", PrettyDescriptionWithPermissionType(type)].localized.uppercaseString forState:UIControlStateNormal];
		} break;
		default:{
			[button setTitle:[NSString stringWithFormat:@"Allow %@", DescriptionWithPermissionType(type)].localized.uppercaseString forState:UIControlStateNormal];
		} break;
	}

	[button addTarget:self action:NSSelectorFromString([NSString stringWithFormat:@"request%@", DescriptionWithPermissionType(type)]) forControlEvents:UIControlEventTouchUpInside];
	button.accessibilityIdentifier = [NSString stringWithFormat:@"permissionscope.button.%@", DescriptionWithPermissionType(type)].lowercaseString;
	
	return button;
}

/**
 Permission label factory, located below the permission buttons.
 
 - parameter type: Permission type
 
 - returns: UILabel instance with a custom style.
 */
- (UILabel *)permissionStyledLabel:(PermissionType)type {
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 50)];
	label.font = self.labelFont;
	label.numberOfLines = 2;
	label.textAlignment = NSTextAlignmentCenter;
	label.text = self.permissionMessages[@(type)];
	label.textColor = self.permissionLabelColor;
	
	return label;
}

/**
 Prompts motionManager to request a status update. If permission is not already granted the user will be prompted with the system's permission dialog.
 */
- (void)triggerMotionStatusUpdate {
	PermissionStatus tmpMotionPermissionStatus = self.motionPermissionStatus;
	self.askedMotion = YES;
	
	NSDate *today = [NSDate date];
	__weak typeof(self) weakSelf = self;
	[self.motionManager queryActivityStartingFromDate:today toDate:today toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray<CMMotionActivity *> * _Nullable activities, NSError * _Nullable error) {
		if (error || error.code == CMErrorMotionActivityNotAuthorized) {
			weakSelf.motionPermissionStatus = PermissionStatusUnauthorized;
		} else {
			weakSelf.motionPermissionStatus = PermissionStatusAuthorized;
		}
		
		[weakSelf.motionManager stopActivityUpdates];
		if (tmpMotionPermissionStatus != weakSelf.motionPermissionStatus) {
			weakSelf.waitingForMotion = NO;
			[weakSelf detectAndCallback];
		}
	}];
	self.askedMotion = YES;
	self.waitingForMotion = YES;
}

/**
 Start and immediately stop bluetooth advertising to trigger
 its permission dialog.
 */
- (void)triggerBluetoothStatusUpdate {
	if (!self.waitingForBluetooth && self.bluetoothManager.state == CBPeripheralManagerStateUnknown) {
		[self.bluetoothManager startAdvertising:nil];
		[self.bluetoothManager stopAdvertising];
		self.askedBluetooth = YES;
		self.waitingForBluetooth = YES;
	}
}

/**
 Sets the style for permission buttons with unauthorized status.
 
 - parameter button: Permission button
 */
- (void)setButtonUnauthorizedStyle:(UIButton *)button {
	button.layer.borderWidth = 0;
	button.backgroundColor = self.unauthorizedButtonColor ? self.unauthorizedButtonColor : self.authorizedButtonColor.inverseColor;
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

/**
 Sets the style for permission buttons with authorized status.
 
 - parameter button: Permission button
 */
- (void)setButtonAuthorizedStyle:(UIButton *)button {
	button.layer.borderWidth = 0;
	button.backgroundColor = self.authorizedButtonColor;
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

/**
 Checks whether all the configured permission are authorized or not.
 
 - parameter completion: Closure used to send the result of the check.
 */
- (void)allAuthorized:(void (^)(BOOL))completion {
	[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
		BOOL result = YES;
		for (PermissionResult *resultItem in results) {
			if (resultItem.status != PermissionStatusAuthorized) {
				result = NO;
				break;
			}
		}
		if (completion) completion(result);
	}];
}

/**
 Checks whether all the required configured permission are authorized or not.
 **Deprecated** See issues #50 and #51.
 
 - parameter completion: Closure used to send the result of the check.
 */
- (void)requiredAuthorized:(void (^)(BOOL))completion {
	[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
		BOOL result = YES;
		for (PermissionResult *resultItem in results) {
			if (resultItem.status != PermissionStatusAuthorized) {
				result = NO;
				break;
			}
		}
		if (completion) completion(result);
	}];
}

// MARK: Helpers

/**
 This notification callback is triggered when the app comes back
 from the settings page, after a user has tapped the "show me"
 button to check on a disabled permission. It calls detectAndCallback
 to recheck all the permissions and update the UI.
 */
- (void)appForegroundedAfterSettings {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[self detectAndCallback];
}

/**
 Requests the status of any permission.
 
 - parameter type:       Permission type to be requested
 - parameter completion: Closure called when the request is done.
 */

- (void)statusForPermission:(PermissionType)type completion:(PermissionScopeStatusRequestClosure)completion {
	// Get permission status
	PermissionStatus permissionStatus;
	switch (type) {
		case PermissionTypeLocationAlways:{
			permissionStatus = [self statusLocationAlways];
		} break;
		case PermissionTypeLocationInUse:{
			permissionStatus = [self statusLocationInUse];
		} break;
		case PermissionTypeContacts:{
			permissionStatus = [self statusContacts];
		} break;
		case PermissionTypeNotifications:{
			permissionStatus = [self statusNotifications];
		} break;
		case PermissionTypeMicrophone:{
			permissionStatus = [self statusMicrophone];
		} break;
		case PermissionTypeCamera:{
			permissionStatus = [self statusCamera];
		} break;
		case PermissionTypePhotos:{
			permissionStatus = [self statusPhotos];
		} break;
		case PermissionTypeReminders:{
			permissionStatus = [self statusReminders];
		} break;
		case PermissionTypeEvents:{
			permissionStatus = [self statusEvents];
		} break;
		case PermissionTypeBluetooth:{
			permissionStatus = [self statusBluetooth];
		} break;
		case PermissionTypeMotion:{
			permissionStatus = [self statusMotion];
		} break;
	}
	
	// Perform completion
	if (completion) completion(permissionStatus);
}

/**
 Rechecks the status of each requested permission, updates
 the PermissionScope UI in response and calls your onAuthChange
 to notifiy the parent app.
 */
- (void)detectAndCallback {
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		// compile the results and pass them back if necessary
		if (self.onAuthChange) {
			[self getResultsForConfig:^(NSArray<PermissionResult *> *results) {
				[weakSelf allAuthorized:^(BOOL areAuthorized) {
					weakSelf.onAuthChange(areAuthorized, results);
				}];
			}];
		}
		
		[self.view setNeedsLayout];
		
		// and hide if we've sucessfully got all permissions
		[self allAuthorized:^(BOOL areAuthorized) {
			if (areAuthorized) [self hide];
		}];
	});
}

/**
 Calculates the status for each configured permissions for the caller
 */
- (void)getResultsForConfig:(PermissionScopeResultsForConfigClosure)completionBlock {
	NSMutableArray<PermissionResult *> *results = [NSMutableArray array];
	
	for (id<Permission> config in self.configuredPermissions) {
		[self statusForPermission:config.type completion:^(PermissionStatus status) {
			PermissionResult *result = [[PermissionResult alloc] initWithType:config.type status:status];
			[results addObject:result];
		}];
	}
	
	if (completionBlock) completionBlock(results);
}

@end
