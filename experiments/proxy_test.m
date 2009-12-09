//#import <ApplicationServices/ApplicationServices.h>
//#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SCDynamicStoreCopySpecific.h>
//#import <SystemConfiguration/SCDynamicStore.h>
//#import <AppKit/AppKit>

int main(int argc, char *argv[])
{
    CFDictionaryRef proxySettings = SCDynamicStoreCopyProxies((SCDynamicStoreRef)NULL);
    NSLog(@"proxySettings: %@", proxySettings);

    NSURL *url = [NSURL URLWithString: @"https://wave.google.com/wave/"];
    NSArray *proxies = (NSArray*)CFNetworkCopyProxiesForURL((CFURLRef)url, proxySettings);
    NSLog(@"proxies: %@", proxies);
    for (NSDictionary *dict in proxies)
    {
        if ([[dict objectForKey: @"kCFProxyTypeKey"] isEqualToString: @"kCFProxyTypeHTTPS"])
        {
            NSString *proxy = [NSString stringWithFormat: @"%@:%@",
                                        [dict objectForKey: @"kCFProxyHostNameKey"],
                                        [dict objectForKey: @"kCFProxyPortNumberKey"]];
            NSLog(@"proxy: %@\n", proxy);
        }
    }
    return 0;
}
