//#import <ApplicationServices/ApplicationServices.h>
//#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
//#import <AppKit/AppKit>

int main(int argc, char *argv[])
{
    NSDictionary *proxySettings = (NSDictionary*)SCDynamicStoreCopyProxies(NULL);
    NSLog(@"proxySettings: %@", proxySettings);
    return 0;
}
