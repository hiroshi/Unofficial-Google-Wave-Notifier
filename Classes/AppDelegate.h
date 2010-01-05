// -*-Objc-*-
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <GrowlApplicationBridgeDelegate>
{
    IBOutlet id menu;
    IBOutlet id preferencesWindow;
    NSStatusItem *statusItem;
    NSDate *checkedDate;
    NSMutableDictionary *growlNotified;
	NSTimer *mainChecker;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (IBAction)checkNotificationAsync:(id)sender;
- (void)checkNotification:(NSTimer*)theTimer;
- (void)updateSinceChecked:(NSTimer*)theTimer;
- (void)updateStatusItemWithCount:(int)count;

- (NSString *)password;
- (void)setPassword:(NSString *)value;
- (NSString *)webProxy;

- (void)closePreferences:(id)sender;
- (IBAction)openPreferences:(id)sender;- (IBAction)goToInbox:(id)sender;
- (IBAction)goToWave:(id)sender;
- (IBAction)goToInbox:(id)sender;
- (void) createMainTimer:(NSUserDefaults *) defaults;
- (void) growlNotificationWasClicked:(id)clickContext;
@end
