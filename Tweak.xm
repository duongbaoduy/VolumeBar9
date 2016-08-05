/*
 * Tweak.xm
 * VolumeBar9
 *
 * Created by cgm616
 * Copyright (c) 2016 cgm616. All rights reserved.
 */

#import "Tweak.h"

static BOOL active;
static BOOL enabled;
static BOOL animate;
static BOOL userInteraction;
static BOOL showRouteButton;
static BOOL blur;
static BOOL drop;
static BOOL statusBar;
static BOOL slide;
static BOOL label;
static double delayTime;
static double speed;
static double height;
static int blurStyle;
static UIColor *color;

static void preferenceUpdate(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	CFStringRef appID = CFSTR("me.cgm616.volumebar9");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

  if (!keyList) {
		HBLogError(@"There's been an error getting the key list!");
		return;
	}

	NSDictionary *preferences = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

  if (!preferences) {
		HBLogError(@"There's been an error getting the preferences dictionary!");
	}

  HBLogDebug(@"Prefs dictionary has been updated to: %@", preferences);
	CFRelease(keyList);

  NSNumber *key = preferences[@"enabled"];
  enabled = key ? [key boolValue] : 1;

  key = preferences[@"animation"];
  animate = key ? [key boolValue] : 1;

  key = preferences[@"interaction"];
  userInteraction = key ? [key boolValue] : 1;

  key = preferences[@"routebutton"];
  showRouteButton = key ? [key boolValue] : 0;

  key = preferences[@"blur"];
  blur = key ? [key boolValue] : 1;

	key = preferences[@"drop"];
  drop = key ? [key boolValue] : 0;

	key = preferences[@"statusBar"];
	statusBar = key ? [key boolValue] : 0;

	key = preferences[@"slide"];
	slide = key ? [key boolValue] : 1;

	key = preferences[@"label"];
	label = key ? [key boolValue] : 0;

  key = preferences[@"timeon"];
  delayTime = key ? [key doubleValue] : 5.0;

  key = preferences[@"animatetime"];
  speed = key ? [key doubleValue] : 0.2;

	key = preferences[@"height"];
  height = key ? [key doubleValue] : 1.0;

  key = preferences[@"blurstyle"];
  blurStyle = key ? [key intValue] : 2;

	color = [LCPParseColorString([preferences objectForKey:@"bannercolor"], @"#FFFFFF") retain];

	[preferences release];
}

%hook SBHUDController

%new(v@:);
-(void)presentVolumeBarWithView:(id)view {
  HBLogDebug(@"Volume view succesfully hooked");
  // TODO: pass in prefs as dictionary and handle defaults some other way
  if(!active) {
    active = true;
    VolumeBar *vbar = [[VolumeBar alloc] init];
  	vbar.color = color;
  	vbar.animate = animate;
  	vbar.userInteraction = userInteraction;
  	vbar.showRouteButton = showRouteButton;
  	vbar.blur = blur;
  	vbar.drop = drop;
  	vbar.statusBar = statusBar;
  	vbar.slide = slide;
  	vbar.label = label;
  	vbar.delayTime = delayTime;
  	vbar.speed = speed;
  	vbar.height = height;
  	vbar.blurStyle = blurStyle;
    vbar.completion = ^{
      HBLogDebug(@"Completion block called");
      [vbar release];
      active = false;
    };
  	[vbar loadHUDWithView:view];
  }
}

-(void)presentHUDView:(id)view autoDismissWithDelay:(double)delay {
  if([view isKindOfClass:objc_getClass("SBVolumeHUDView")]) {
    [self presentVolumeBarWithView:view];
  } else {
    %orig;
  }
}

-(void)presentHUDView:(id)view {
  if([view isKindOfClass:objc_getClass("SBVolumeHUDView")]) {
    [self presentVolumeBarWithView:view];
  } else {
    %orig;
  }
}

%end

%ctor {
  preferenceUpdate(nil,nil,nil,nil,nil);
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferenceUpdate, CFSTR("me.cgm616.volumebar9/preferences.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%dtor {
  [color release];
}