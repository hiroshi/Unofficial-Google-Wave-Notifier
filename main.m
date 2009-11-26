//
//  main.m
//  google-wave-notifier
//
//  Created by hiroshi on 09/10/16.
//  Copyright yakitara.com 2009. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#define SERVICE_NAME "Unofficial Google Wave Notifier" // FIXME: get from app
enum {
    MenuItemTagUnreadInsert = 1,
    MenuItemTagUnread = 2,
    MenuItemTagCheckNow = 3,
};
//TODO: yes, I should separate class implementation from main.m...
@interface AppDelegate : NSObject
{
    IBOutlet id menu;
    IBOutlet id preferencesWindow;
    NSStatusItem *statusItem;
    NSDate *checkedDate;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (IBAction)checkNotificationAsync:(id)sender;
- (void)checkNotification:(NSTimer*)theTimer;
- (void)updateSinceChecked:(NSTimer*)theTimer;

- (NSString *)password;
- (void)setPassword:(NSString *)value;

- (IBAction)openPreferences:(id)sender;
- (IBAction)goToInbox:(id)sender;
- (IBAction)goToWave:(id)sender;
- (IBAction)resetAdvancedPreferencesToDefaults:(id)sender;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // defaults
    NSDictionary *defaultsDict = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Defaults" ofType: @"plist"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultsDict];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultsDict];
    //NSLog(@"appliesImmediately: %d\n", [[NSUserDefaultsController sharedUserDefaultsController] appliesImmediately]);

    // menubar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    [statusItem setImage: [NSImage imageNamed: @"wave.png"]];
    [statusItem setHighlightMode: YES];
    [statusItem setMenu: menu];

    // check once first
    [self checkNotificationAsync: self];
    // schedule updateSinceChecked
    [NSTimer scheduledTimerWithTimeInterval: 60
             target: self
             selector: @selector(updateSinceChecked:)
             userInfo: nil
             repeats: YES];
    // schedule checkNotification
    [NSTimer scheduledTimerWithTimeInterval: 5.0 * 60 // TODO: preferences
             target: self
             selector: @selector(checkNotification:)
             userInfo: nil
             repeats: YES];
}

- (void)checkNotificationAsync:(id)sender
{
    // NOTE: Clicking button and performeClose will not end editing the first responder text field. So, force to end editing it.
    [preferencesWindow endEditingFor: [preferencesWindow firstResponder]];

    [preferencesWindow performClose: sender];
    [NSTimer scheduledTimerWithTimeInterval: 1.0
             target: self
             selector: @selector(checkNotification:)
             userInfo: nil
             repeats: NO];
}

- (void)checkNotification:(NSTimer*)theTimer
{
    checkedDate = [NSDate dateWithTimeIntervalSinceNow: -2.0]; // ensure that first call of scheduled updateSinceChecked is called a minutes later
    [self updateSinceChecked: NULL];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // first of all, check keychain for password
    NSString *email = [defaults objectForKey: @"Email"];
    if (!email)
    {
        [statusItem setTitle: @"x"];
        return;
    }
    NSString *password = [self password];
    if (!password)
    {
        [statusItem setTitle: @"x"];
        return;
    }
    //NSLog(@"e: %@, p: %@\n", email, password);

    NSString *pathToRuby = [defaults objectForKey: @"PathToRuby"];
    NSLog(@"checkNotification: start. (pathToRuby: %@)\n", pathToRuby);
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    [task setLaunchPath: pathToRuby];
    NSString *rbPath = [[NSBundle mainBundle] pathForResource: @"google-wave-notifier" ofType: @"rb"];
    [task setArguments: [NSArray arrayWithObjects: rbPath, email, password, nil]];
    [task setStandardOutput: pipe];
    @try {
        [task launch];
    }
    //NOTE: will catch NSInvalidArgumentException when launchPath not accesible
    @catch (NSException *e) {
        NSLog(@"launch failed: %@: %@", [e name], [e reason]);
        [statusItem setTitle: @"x"];
        return;
    }

    NSData *data = [handle readDataToEndOfFile];
    //NSLog([[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    //NSLog(@"\n");
    [task waitUntilExit];
    if ([task terminationStatus] != 0)
    {
        [statusItem setTitle: @"x"];
        return;
    }

    NSString *errorString = nil;
    NSPropertyListFormat format;
    id plist = [NSPropertyListSerialization propertyListFromData: data 
                                            mutabilityOption: NSPropertyListImmutable
                                            format: &format
                                            errorDescription: &errorString];
    if (errorString)
    {
        NSLog(@"checkNotification: failed. error: %@\n", *errorString);
    }
    else
    {
        //id count = [[[plist objectForKey: @"Items"] objectAtIndex: 0] objectForKey: @"Unread Count"];
        // First, remove previous unreads
        NSMenuItem *menuItem = nil;
        while (menuItem = [menu itemWithTag: MenuItemTagUnread])
        {
            [menu removeItem: menuItem];
        }
        // remove or replace total unread count as menubar title
        id totalCount = [plist objectForKey: @"Total Unread Count"];
        if ([totalCount isEqualToNumber: [NSNumber numberWithInt: 0]])
        {
            [statusItem setTitle: @""];
        }   
        else
        {
            [statusItem setTitle: [NSString stringWithFormat: @"%@", totalCount]];
            // Add new unreads
            NSInteger insertIndex = [menu indexOfItemWithTag: MenuItemTagUnreadInsert] + 1;
            //   separator
            NSMenuItem *separator = [NSMenuItem separatorItem];
            [separator setTag: MenuItemTagUnread];
            [menu insertItem: separator atIndex: insertIndex];
            //   unread waves
            NSEnumerator *enumerator = [[plist objectForKey: @"Items"] objectEnumerator];
            NSDictionary *item = nil;
            while (item = [enumerator nextObject])
            {
                NSString *title = [NSString stringWithFormat: @"%@ (%@)", [item objectForKey: @"Title"], [item objectForKey: @"Unread Count"]];
                NSMenuItem *menuItem = [menu insertItemWithTitle: title action: @selector(goToWave:) keyEquivalent: @"" atIndex: insertIndex];
                [menuItem setRepresentedObject: [item objectForKey: @"URL"]];
                [menuItem setTag: MenuItemTagUnread];
            }
        }
        NSLog(@"checkNotification: done. (total count: %@)\n", totalCount);
    }
}

- (void)updateSinceChecked:(NSTimer*)theTimer
{
    NSFont *font = [NSFont menuBarFontOfSize: 0];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObject: font forKey: NSFontAttributeName];
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString: @"Check Now" attributes: attrs];
    [attrs setObject: [NSColor grayColor] forKey: NSForegroundColorAttributeName];
    [attrs setObject: [NSFont menuBarFontOfSize: [font pointSize] - 2] forKey: NSFontAttributeName];

    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate: checkedDate];
    NSLog(@"updateSinceChecked: seconds: %f", seconds);
    NSString *appendTitle = NULL;
    if (seconds < 60)
    {
        appendTitle = @" - Checked less than 1 min ago";
    }
    else if (seconds < 60 * 60)
    {
        appendTitle = [NSString stringWithFormat: @" - Checked %d min ago", (int)(seconds / 60)];
    }
    else // more than an hour
    {
        appendTitle = [NSString stringWithFormat: @" - Checked %d h ago", (int)(seconds / (60 * 60))];
    }
    [title appendAttributedString: [[NSAttributedString alloc] initWithString: appendTitle attributes: attrs]];
    [[menu itemWithTag: MenuItemTagCheckNow] setAttributedTitle: title];
}

- (NSString *)password
{
    NSString *email = [[NSUserDefaults standardUserDefaults] objectForKey: @"Email"];
    if (email)
    {
        void *passwordData;
        UInt32 passwordLength;
        OSStatus status = SecKeychainFindGenericPassword(
            NULL,           // default keychain
            strlen(SERVICE_NAME),             // length of service name
            SERVICE_NAME,   // service name
            [email lengthOfBytesUsingEncoding: NSUTF8StringEncoding], // length of account name
            [email UTF8String],   // account name
            &passwordLength,  // length of password
            &passwordData,   // pointer to password data
            NULL // the item reference
            );
        if (status != noErr)
        {
            NSLog(@"SecKeychainFindGenericPassword: failed. (OSStatus: %d)\n", status); // FIXME: handle the errror
            return nil;//@"";
        }
        //NSString *passwd = [NSString stringWithUTF8String: passwordData];
        NSString *passwd = [[NSString alloc] initWithBytes: passwordData length: passwordLength encoding: NSUTF8StringEncoding];
        status = SecKeychainItemFreeContent(NULL, passwordData);
        if (status != noErr)
        {
            NSLog(@"SeSecKeychainItemFreeContent: failed. (OSStatus: %d)\n", status); // FIXME: handle the errror
        }
        return passwd;
    }
    else
    {
        return nil; //@"";
    }
}
- (void)setPassword:(NSString *)value
{
    NSString *email = [[NSUserDefaults standardUserDefaults] objectForKey: @"Email"];
    if (email)
    {
        OSStatus status = SecKeychainAddGenericPassword (
            NULL,           // default keychain
            strlen(SERVICE_NAME),             // length of service name
            SERVICE_NAME,   // service name
            [email lengthOfBytesUsingEncoding: NSUTF8StringEncoding], // length of account name
            [email UTF8String],   // account name
            [value lengthOfBytesUsingEncoding: NSUTF8StringEncoding], // length of password
            [value UTF8String],   // password
            NULL
            );
        if (status != noErr)
        {
            NSLog(@"SecKeychainAddGenericPassword: failed. (OSStatus: %d)\n", status); // FIXME: handle the errror
        }
    }
}

- (IBAction)openPreferences:(id)sender
{
    [preferencesWindow makeKeyAndOrderFront: sender];
    [preferencesWindow setLevel: NSTornOffMenuWindowLevel];
}

- (IBAction)goToInbox:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"https://wave.google.com/wave/"]];
}

- (IBAction)goToWave:(id)sender
{
    NSString *url = [sender representedObject];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
}

- (IBAction)resetAdvancedPreferencesToDefaults:(id)sender
{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    //[[defaultsController values] removeObjectForKey: @"PathToRuby"];
    //[[defaultsController values] setNilValueForKey: @"PathToRuby"];
    //[[defaultsController values] setValue: @"" forKey: @"PathToRuby"];
//    [[defaultsController defaults] removeObjectForKey: @"PathToRuby"];
}
    
// for Cocoa binding key path
// NOTE: Key of Info.plist is not as is. (e.g. "Bundle version" => "CFBundleVersion")
- (NSDictionary *)infoDictionary
{
    return [[NSBundle mainBundle] infoDictionary];
}
@end





int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
