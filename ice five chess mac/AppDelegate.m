//
//  AppDelegate.m
//  ice five chess mac
//
//  Created by 王子诚 on 2019/5/24.
//  Copyright © 2019 王子诚. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    

  //  [[_window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    
    
    //[_window standardWindowButton:NSWindowCloseButton]
    //[NSApp hide:_window];
    //[NSApp endSheet:_window];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return true;
}
@end
