//
//  ViewController.h
//  ice five chess mac
//
//  Created by 王子诚 on 2019/5/24.
//  Copyright © 2019 王子诚. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "doublethree.h"
#import "file.h"
#ifndef ViewController_h
#define ViewController_h
@interface ViewController : NSViewController
{
    int map_state[15][15];
    NSButton* chess_map[15][15];
    doublethree* ice_fiver;
    filer* file_controller;
    int thread_num;
    NSThread* threader[4];
    long focus_x,focus_y;
    bool position_changed;
    long current_lang;
    int player_prefer_difficulty;
    int keyer;
    int think_flag;
@protected
    CGRect Screensize;
    int ScreenWidth;
    int ScreenHeight;
    int perwidth;
    int perheight;
    int player_chess_id;
    int teacher_on;
}
-(void)restart_funct;
-(void)change_chess_and_restart;

@end
#endif

