//#import <ApplicationServices/ApplicationServices.h>
//#import <Foundation/Foundation.h>
//#import <Cocoa/Cocoa.h>
//#import <AppKit/AppKit>

int main(int argc, char *argv[])
{
    CFStringRef default_id = LSCopyDefaultHandlerForURLScheme(CFSTR("http"));
    NSLog(@"default: %@", default_id);
//     NSBundle *default_bundle = [NSBundle bundleWithIdentifier: default_id];
//     NSLog(@"  bundle: %@", default_bundle);
//     NSLog(@"  path: %@", [default_bundle bundlePath]);
//     CFURLRef outAppURL;
//     OSStatus osstat = LSFindApplicationForInfo(
//         kLSUnknownCreator,
//         default_id,
//         NULL,
//         NULL,
//         &outAppURL);
//     NSLog(@"  url: %@", outAppURL);
    NSLog(@"workspace: %@", [NSWorkspace sharedWorkspace]);
    BOOL result = [[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject: [NSURL URLWithString: @"http://www.google.com"]]
                                                 withAppBundleIdentifier: @"org.mozilla.firefox"
                                                 options: NSWorkspaceLaunchDefault
                                                 additionalEventParamDescriptor: nil
                                                 launchIdentifiers: nil];

//     CFArrayRef browsers = LSCopyAllHandlersForURLScheme(CFSTR("http"));
//     NSLog(@"browsers: %@", browsers);
    return 0;
}
