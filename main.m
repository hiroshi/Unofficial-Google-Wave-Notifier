//
//  main.m
//  google-wave-notifier
//
//  Created by hiroshi on 09/10/16.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#define SERVICE_NAME "Unofficial Google Wave Notifier" // FIXME: get from app

@interface AppDelegate : NSObject
{
    IBOutlet id menu;
    IBOutlet id preferencesWindow;
    NSStatusItem *statusItem;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (IBAction)checkNotificationAsync:(id)sender;
- (void)checkNotification:(NSTimer*)theTimer;

- (NSString *)password;
- (void)setPassword:(NSString *)value;

- (IBAction)openPreferences:(id)sender;
- (IBAction)goToInbox:(id)sender;
- (IBAction)resetAdvancedPreferencesToDefaults:(id)sender;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // defaults
    NSDictionary *defaultsDict = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Defaults" ofType: @"plist"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultsDict];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultsDict];

    // menubar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    [statusItem setTitle: @"w"];
    [statusItem setHighlightMode: YES];
    [statusItem setMenu: menu];

    // check once first
    [self checkNotificationAsync: self];
    // schedule checkNotification
    [NSTimer scheduledTimerWithTimeInterval: 5.0 * 60 // TODO: preferences
             target: self
             selector: @selector(checkNotification:)
             userInfo: nil
             repeats: YES];
}

- (void)checkNotificationAsync:(id)sender
{
    [preferencesWindow performClose: sender];
    [NSTimer scheduledTimerWithTimeInterval: 1.0
             target: self
             selector: @selector(checkNotification:)
             userInfo: nil
             repeats: NO];
}

- (void)checkNotification:(NSTimer*)theTimer
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // first of all, check keychain for password
    NSString *email = [defaults objectForKey: @"Email"];
    if (!email)
    {
        [statusItem setTitle: @"w(x)"];
        return;
    }
    NSString *password = [self password];
    if (!password)
    {
        [statusItem setTitle: @"w(x)"];
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
    //NSLog(@"rbPath: %@\n", rbPath);
    [task setArguments: [NSArray arrayWithObjects: rbPath, email, password, nil]];
    [task setStandardOutput: pipe];
    [task launch];

    NSData *data = [handle readDataToEndOfFile];
    //NSLog([[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    //NSLog(@"\n");
    [task waitUntilExit];
    if ([task terminationStatus] != 0)
    {
        [statusItem setTitle: @"w(x)"];
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
        id count = [plist objectForKey: @"Total Unread Count"];
        if ([count isEqualToNumber: [NSNumber numberWithInt: 0]])
        {
            [statusItem setTitle: @"w"];
        }   
        else
        {
            [statusItem setTitle: [NSString stringWithFormat: @"w(%@)", count]];
        }
        NSLog(@"checkNotification: done. (count: %@)\n", count);
    }
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
