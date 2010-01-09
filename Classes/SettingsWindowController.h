//
//  SettingsWindowController.h
//  google-wave-notifier
//
//  Created by Brandon Tennant on 10-01-01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
extern NSString *WaveClientBundleIDKey;

@interface SettingsWindowController : NSWindowController {
    NSPopUpButton *waveClientPopUpButton;
    NSArray *appBundleIds;
}

- (void)loadBrowsersIntoList;
- (void)saveSelection:(id)sender;

@property (nonatomic, retain) IBOutlet NSPopUpButton *waveClientPopUpButton;

@end
