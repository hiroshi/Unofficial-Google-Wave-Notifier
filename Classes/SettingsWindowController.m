//
//  SettingsWindowController.m
//  google-wave-notifier
//
//  Created by Brandon Tennant on 10-01-01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsWindowController.h"
NSString *WaveClientBundleIDKey = @"WaveClientBundleID";

@implementation SettingsWindowController
@synthesize waveClientPopUpButton;

- (void)awakeFromNib 
{
	[self loadBrowsersIntoList];
}

- (void) dealloc
{
	self.waveClientPopUpButton = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Wave Client Pref Management
- (void)loadBrowsersIntoList
{
    appBundleIds = (NSArray *)LSCopyAllHandlersForURLScheme(CFSTR("https"));
    NSMenu *popupMenu = self.waveClientPopUpButton.menu;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *storedBundleId =  [[NSUserDefaults standardUserDefaults] objectForKey:WaveClientBundleIDKey];
    
	NSImage *browserImage = nil;
	NSString *browserAppName = nil;
	NSString *appPath = nil;
	NSBundle *bundle = nil;
	
	[self.waveClientPopUpButton removeAllItems];
	
	for(NSString *bundleId in appBundleIds)
	{
		appPath = [ws absolutePathForAppBundleWithIdentifier: bundleId];
		bundle = [NSBundle bundleWithPath:appPath];
        
		browserImage = [ws iconForFile:appPath];
		browserAppName = [[bundle infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
		
		if(!browserAppName)
			browserAppName = [appPath lastPathComponent];
        
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:browserAppName 
                                                           action:@selector(saveSelection:) 
                                                    keyEquivalent:@""] autorelease];
		[menuItem setImage:browserImage];
		[popupMenu addItem:menuItem];
		
		if ([storedBundleId isEqual: bundleId]) {
			[self.waveClientPopUpButton selectItem:menuItem];
		}
	}
}

- (void)saveSelection:(id)sender
{
    NSInteger selection = [self.waveClientPopUpButton indexOfItem:sender];
    NSString *bundleId = [appBundleIds objectAtIndex:selection];
    
    [[NSUserDefaults standardUserDefaults] setObject:bundleId forKey:WaveClientBundleIDKey]; 
}


@end
