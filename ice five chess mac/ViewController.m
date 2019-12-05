//
//  ViewController.m
//  ice five chess mac
//
//  Created by 王子诚 on 2019/5/24.
//  Copyright © 2019 王子诚. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak) IBOutlet NSTextField *db_texter;
@property (weak, nonatomic) IBOutlet NSButton *player_chess_choice;
@property (weak, nonatomic) IBOutlet NSSegmentedControl *player_choice_seg;
@property (weak, nonatomic) IBOutlet NSButton *player_sure_btn;
@property (weak, nonatomic) IBOutlet NSSegmentedControl *difficulty_choice_seg;
@property (weak, nonatomic) IBOutlet NSSegmentedControl *ban_choice;
@property (weak) IBOutlet NSProgressIndicator* rotater;
@end

@implementation ViewController
-(void) initial
{
    keyer=0;
    ScreenWidth=900;
    ScreenHeight=800;
    int smal=0;
    if(ScreenWidth>ScreenHeight)
        smal=ScreenHeight;
    else smal=ScreenWidth;
    
    NSString* lange = [self usr_lang];
    current_lang=2; // 英语
    if([lange characterAtIndex: 0]=='z')
        current_lang=1; // 汉语
    
    if(current_lang==2){
        NSArray* DA = @[@"Forbidden off ⭕️",@"Forbidden on 🚫"];
        for(int i=0;i<2;i++)
            [_ban_choice setLabel:DA[i] forSegment:i];

        DA=@[@"Black ⚫️",@"White ⚪️"];
        for(int i=0;i<2;i++)
            [_player_choice_seg setLabel:DA[i] forSegment:i];
    }
    else{
        NSArray* DA = @[@"禁手关闭 ⭕️",@"禁手开启 🚫"];
        for(int i=0;i<2;i++)
            [_ban_choice setLabel:DA[i] forSegment:i];
        DA=@[@"黑棋 ⚫️",@"白棋 ⚪️"];
        for(int i=0;i<2;i++)
            [_player_choice_seg setLabel:DA[i] forSegment:i];
    }
    
    perwidth=(smal)/17;
    perheight=perwidth;
    focus_y=focus_x=0;
    player_chess_id=1;
    teacher_on=0;
    ice_fiver=[[doublethree alloc] init];
    file_controller=[[filer alloc]init];
    _player_sure_btn.tag=1001;

}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initial];
    
    for(int i=0;i<15;i++)
        for(int j=0;j<15;j++)
        {
            [self set_chess_map_btn_with_x:i y:j];
            map_state[i][j]=0;
        }
    [self read_all_from_file:@"autosave"];
    think_flag=0;
    srand(time(0));
    
    thread_num=2;
    for(int p=0;p<thread_num;p++)
    {
        threader[p] = [[NSThread alloc] initWithTarget:self selector:@selector(createRunloopByNormal) object:nil] ;
        [threader[p] start];
    }
    
    [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.01];
    NSApplication *app=[NSApplication sharedApplication];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:app];
    // Do any additional setup after loading the view.
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}
-(void)keyDown:(NSEvent *)event{
   // NSLog(@"%d",event.keyCode);
    keyer^=1;
    if(keyer==1)
    {
        switch (event.keyCode) {
            case 49:
                [self undo_act:_player_sure_btn];
                break;
            case 15:
                [self restart_funct];
                break;
            case 14:
                [self helping_predict:_player_sure_btn];
                break;
            default:
                break;
        }
    }
}
-(NSString*) usr_lang
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    return language;
}
- (void)createRunloopByNormal{
    @autoreleasepool {
        
        //添加port源，保证runloop正常轮询，不会创建后直接退出。
        [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        
        //开启runloop
        [[NSRunLoop currentRunLoop] run];
        //  NSLog(@"hel %d",rand()%100);
    }
}

-(void)awakeFromNib{
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull aEvent) {
        [self keyDown:aEvent];
        return aEvent;
    }];
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent * _Nullable(NSEvent * _Nonnull aEvent) {
        [self flagsChanged:aEvent];
        return aEvent;
    }];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskPeriodic handler:^NSEvent * _Nullable(NSEvent * _Nonnull aEvent) {
        [self try_next_step];
        return aEvent;
    }];
}

-(void) applicationWillResignActive:(NSNotification*)notification
{
    [self save_all_to_file:@"autosave"];
}

-(void) try_next_step
{
    if(think_flag==1)
    {
        if(player_chess_id==1)
        {
            int res=[ice_fiver add_a_chess:focus_x pl_y:focus_y mode:1];
            
            if(res!=1)
            {
                
                [self analysis_next_step];
                
                if([ice_fiver win_state]==-1)
                {
                    _db_texter.placeholderString=@" 🎉🎉";
                    //[self White_win_restart_funct];
                }
            }
            else{
                _db_texter.placeholderString=@" 😬😬";
                //[self Black_win_restart_funct];
            }
        }
        else{
            int res=[ice_fiver add_a_chess:focus_x pl_y:focus_y mode:-1];
            if(res!=-1)
            {
                [self analysis_next_step];
                
                if([ice_fiver win_state]==1)
                {
                    _db_texter.placeholderString=@"  🎉🎉";
                    // [self Black_win_restart_funct];
                }
            }
            else{
                _db_texter.placeholderString=@" 😬😬";
                // [self White_win_restart_funct];
            }
        }
        [self think_finish];
    }
}

-(void) save_all_to_file:(NSString*)filename
{
    NSString* pack_cont=[file_controller pack_chessboard:map_state];
    NSString* main_title=[[NSString alloc]initWithFormat:@"%@_player_main",filename];
    NSString* player_ch_title=[[NSString alloc]initWithFormat:@"%@_player_ch",filename];
    NSString* player_df_title=[[NSString alloc]initWithFormat:@"%@_player_df",filename];
    NSString* player_ban_title=[[NSString alloc]initWithFormat:@"%@_player_ban",filename];
    NSString* player_stack_title=[[NSString alloc]initWithFormat:@"%@_player_stack",filename];
    
    int ban_choice=(int)_ban_choice.selectedSegment;
    //NSLog(@"ban %d",ban_choice);
    NSString* pl_ch=[[NSString alloc]initWithFormat:@"%d",player_chess_id];
    NSString* pl_df=[[NSString alloc]initWithFormat:@"%d",player_prefer_difficulty];
    NSString* pl_ban=[[NSString alloc]initWithFormat:@"%d",ban_choice];
    
    [file_controller File_Save:pack_cont to:main_title];
    [file_controller File_Save:pl_ch to:player_ch_title];
    [file_controller File_Save:pl_df to:player_df_title];
    [file_controller File_Save:pl_ban to:player_ban_title];
    
    
    int stacker[225][2];
    int stack_height;
    stack_height=[ice_fiver export_stack:stacker];
    
    NSString* stack_contents=[file_controller pack_chess_stack:stacker height:stack_height];
    // NSLog(@"height %d : %@",stack_height,stack_contents);
    [file_controller File_Save:stack_contents to:player_stack_title];
    
}
-(int) read_all_from_file:(NSString*)filename
{
    NSString* main_title=[[NSString alloc]initWithFormat:@"%@_player_main",filename];
    NSString* str=[file_controller File_read:main_title];
    if(str.length<220)
        return 0;
    
    [file_controller release_chessboard:map_state data:str];
    [ice_fiver import_from_board:map_state];
    
    NSString* player_ch_title=[[NSString alloc]initWithFormat:@"%@_player_ch",filename];
    NSString* player_df_title=[[NSString alloc]initWithFormat:@"%@_player_df",filename];
    NSString* player_ban_title=[[NSString alloc]initWithFormat:@"%@_player_ban",filename];
    NSString* player_stack_title=[[NSString alloc]initWithFormat:@"%@_player_stack",filename];
    NSString* pl_ch=[file_controller File_read:player_ch_title];
    NSString* pl_df=[file_controller File_read:player_df_title];
    NSString* pl_ban=[file_controller File_read:player_ban_title];
    
    if(pl_ch!=nil)
    player_chess_id=(int)pl_ch.integerValue;
    else player_chess_id=-1;
    
    if(player_chess_id==-1)
    {
        _player_choice_seg.selectedSegment=1;
    }
    else{
        _player_choice_seg.selectedSegment=0;
    }
    
    if(pl_df!=nil)
    player_prefer_difficulty=(int)pl_df.integerValue;
    else player_prefer_difficulty=0;
    
    _difficulty_choice_seg.selectedSegment=player_prefer_difficulty;
    
        if(pl_ban!=nil)
        _ban_choice.selectedSegment=pl_ban.integerValue;
        else{
            _ban_choice.selectedSegment=0;
            pl_ban=@"0";
        }
        [ice_fiver set_banmode:(int)pl_ban.integerValue];
    
    NSString* stack_contents=[file_controller File_read:player_stack_title];
    int stacker[225][2];
    int stack_height;
    stack_height=[file_controller release_chess_stack:stacker data:stack_contents];

    [ice_fiver import_stack:stacker height:stack_height];

    [self flush_chess_map_according_to:map_state];
    return 1;
}
-(void) set_chess_map_btn_with_x:(int)x y:(int)y
{
    [self set_base_block:0 x:x y:y back_color:NSColor.whiteColor title_color:NSColor.lightGrayColor];
}
-(void) paint_chess_map_with_x:(long)x y:(long)y val:(int)val
{
    if(val==1){
        [chess_map[x][y] setImage:[NSImage imageNamed:@"black_chess_pic"]];
    }
    if(val==-1){
        [chess_map[x][y] setImage:[NSImage imageNamed:@"white_chess_pic"]];
    }
    if(val==0){
        [chess_map[x][y] setImage:[NSImage imageNamed:@"aimed_pic"]];
    }
    [self.view addSubview:chess_map[x][y]];
}
-(void) clear_chess_map_with_x:(int)x y:(int)y
{

    [chess_map[x][y] setImage:[NSImage imageNamed:@"aimed_pic"]];
}
-(void) flush_chess_map_according_to:(int[15][15])row_map
{
    for(int i=0;i<15;i++)
    {
        for(int j=0;j<15;j++)
        {
            [self paint_chess_map_with_x:i y:j val:row_map[i][j]];
        }
    }
    if(ice_fiver!=nil)
    {
        int pos[2];
        int lcolor;
        lcolor=[ice_fiver get_last_pos_return_color:pos];
        
        
        if(row_map[pos[0]][pos[1]]==lcolor)
            [self paint_focus_chess_map_with_x:pos[0] y:pos[1] val:lcolor];
    }
}
-(void) paint_focus_chess_map_with_x:(long)x y:(long)y val:(int)val
{
    if(x>0&&map_state[x-1][y]==0)
        [chess_map[x-1][y] setImage:[NSImage imageNamed:@"d_righter"]];
    else if(x<14&&map_state[x+1][y]==0)
        [chess_map[x+1][y] setImage:[NSImage imageNamed:@"d_lefter"]];
    else if(y<14&&map_state[x][y+1]==0)
        [chess_map[x][y+1] setImage:[NSImage imageNamed:@"d_downer"]];
    else if(y>0&&map_state[x][y-1]==0)
        [chess_map[x][y-1] setImage:[NSImage imageNamed:@"d_upper"]];
    else{
        if(val==1){
            [chess_map[x][y] setImage:[NSImage imageNamed:@"black_chess_pic_l"]];
           // [self.view addSubview:chess_map[x][y]];
        }
        if(val==-1){
            [chess_map[x][y] setImage:[NSImage imageNamed:@"white_chess_pic_l"]];
         //   [self.view addSubview:chess_map[x][y]];
        }
    }
}
-(void) copy_state_map:(int[15][15])aimed_map from:(int[15][15])map_ext
{
    for(int i=0;i<15;i++)
        for(int j=0;j<15;j++)
            aimed_map[i][j]=map_ext[i][j];
    
}
-(void) set_base_block:(int)val x:(int)x y:(int)y back_color:(NSColor*)background_color title_color:(NSColor*)title_color
{
    
    CGRect position=CGRectMake(0, 0, 0, 0);
    if(chess_map[x][y]==nil)
        position=CGRectMake(x*perwidth+(ScreenWidth-15*perwidth)/2+perwidth, ScreenHeight/2+(y-7.5)*perheight, perwidth,perheight);
    
    chess_map[x][y]=[self AddBlockBtn:chess_map[x][y] frame:position action:@selector(focus_click:) val:val blockrow:x blockcol:y Backgroundcolor:background_color TitleColor:title_color];
    
    [chess_map[x][y] setImage:[NSImage imageNamed:@"aimed_pic"]];
    [chess_map[x][y] setState:NSControlStateValueOn];
  //  [chess_map[x][y] setTitle:@"0"];
    [chess_map[x][y] setImageScaling:NSImageScaleAxesIndependently];
    
}
-(NSButton*) AddBlockBtn:(NSButton*)btn frame:(CGRect)frame
                  action:(SEL)action val:(int)val blockrow:(int)row blockcol:(int)col Backgroundcolor:(NSColor*)backcolor TitleColor:(NSColor*)titlecolor
{
    if(btn==nil)
    {
        btn=[[NSButton alloc] init];
        btn.tag=row*15+col;
      //  [btn setShowsBorderOnlyWhileMouseInside:true];
        btn.image=[NSImage imageNamed:@"aimed_pic"];
        [btn setBordered:false];
        [btn setAction:action];
        [btn setTarget:self];
        btn.frame = frame;
        if(btn.tag>100)
            btn.font=[NSFont systemFontOfSize:23 weight:NSFontWeightRegular];
        else
            btn.font=[NSFont systemFontOfSize:23 weight:NSFontWeightLight];
    }
    if(val!=0)
    {
        NSString* td=[[NSString alloc] initWithFormat:@"%d",val];
        [btn setTitle:td];
    }
    else{
        [btn setTitle:@""];
    }
    [btn setBezelColor:backcolor];
    [btn setContentTintColor:titlecolor];
    
    //监听btn
    [self.view addSubview:btn];
    return btn;
}
- (IBAction)clear_btn_act:(NSButton *)sender {
    [self restart_funct];
}
-(void)restart_funct
{
    for(int i=0;i<15;i++)
        for(int j=0;j<15;j++)
        {
            map_state[i][j]=0;
        }
    [ice_fiver import_from_board:map_state];
    [ice_fiver clear_all_data];
    
    
    if(player_chess_id==-1)
    {
        [ice_fiver add_a_chess:7 pl_y:7 mode:1];
        map_state[7][7]=1;
    }
    [self flush_chess_map_according_to:map_state];
    [self following_act_with_x:100 y:0];
}

-(void) analysis_next_step
{
    
    [ice_fiver import_from_board:map_state];
    switch (player_prefer_difficulty) {
        case 0:
            [ice_fiver harsh_analysisboard:-player_chess_id];
            break;
        case 1:
            [ice_fiver easy_analysisboard:-player_chess_id];
            break;
        case 2:
            [ice_fiver egg_analysisboard:-player_chess_id];
            break;
        default:
            [ice_fiver harsh_analysisboard:-player_chess_id];
            break;
    }
    [ice_fiver export_current_board:map_state];
    _db_texter.placeholderString=[ice_fiver get_now_tech];
    
    [self flush_chess_map_according_to:map_state];
    [self save_all_to_file:@"autosave"];
}
-(IBAction) focus_click:(NSButton *)sender
{
    if([ice_fiver win_state]!=0)
        return;
    
    //NSLog(@"clicked %d",sender.tag);
    long tager=[sender tag];
    srand(time(0));
    if(focus_x==tager/15&&focus_y==tager%15)
    {
        if(map_state[focus_x][focus_y]==0&&think_flag==0)
        {
            if(player_chess_id==1)
            {
                [self paint_chess_map_with_x:focus_x y:focus_y val:1];
                if([ice_fiver current_banmode]==1)
                {
                    if([ice_fiver banned_point:focus_x j:focus_y]==1)
                    {
                        //[window_controller Simple_alertMessage_With_Title:@"🚫" andMessage:@"禁手警告⚠️"];
                        if(current_lang==1){
                            _db_texter.placeholderString=@"禁手警告 ⚠️";
                        }
                        else{
                            _db_texter.placeholderString=@"Forbidden warning ⚠️";
                        }
 
                        return;
                    }
                }
                //   [self following_act_with_x:100 y:0];
                map_state[focus_x][focus_y]=1;
                [self flush_chess_map_according_to:map_state];
                [self think_start];
                /*
                int res=[ice_fiver add_a_chess:focus_x pl_y:focus_y mode:1];
                
                if(res!=1)
                {
                    
                    [self analysis_next_step];
                    
                    if([ice_fiver win_state]==-1)
                    {
                        _db_texter.placeholderString=@"白棋胜利 🎉🎉";
                        //[self White_win_restart_funct];
                    }
                }
                else{
                     _db_texter.placeholderString=@"黑棋胜利 😯😯";
                    //[self Black_win_restart_funct];
                }
                 */
            }
            else{
                [self paint_chess_map_with_x:focus_x y:focus_y val:-1];
                //  [self following_act_with_x:100 y:0];
                map_state[focus_x][focus_y]=-1;
                [self flush_chess_map_according_to:map_state];
                [self think_start];

                /*
                int res=[ice_fiver add_a_chess:focus_x pl_y:focus_y mode:-1];
                if(res!=-1)
                {
                    [self analysis_next_step];
                    
                    if([ice_fiver win_state]==1)
                    {
                         _db_texter.placeholderString=@"黑棋胜利  🎉🎉";
                       // [self Black_win_restart_funct];
                    }
                }
                else{
                     _db_texter.placeholderString=@"白棋胜利 😯😯";
                   // [self White_win_restart_funct];
                }
                 */
            }
        }
        position_changed=false;
        return;
    }
    else{
        position_changed=true;
        if(map_state[focus_x][focus_y]==0)
            [self clear_chess_map_with_x:focus_x y:focus_y];
    }
    focus_x=tager/15;
    focus_y=tager%15;
    if(map_state[focus_x][focus_y]==0)
    {
        [sender setImage:[NSImage imageNamed:@"focus_aimed_pic"]];
    }
    else{
        
        int elt=0;
        bool dis_empty[4]={};
        if(focus_y>1 && map_state[focus_x][focus_y-1]==0)
        {
            dis_empty[0]=true;
        }
        else if(focus_y<14 && map_state[focus_x][focus_y+1]==0){
            dis_empty[1]=true;
        }
        else if(focus_x>1 &&map_state[focus_x-1][focus_y]==0){
            dis_empty[2]=true;
        }
        else if(focus_x<14 &&map_state[focus_x+1][focus_y]==0){
            dis_empty[3]=true;
        }
        
        for(int i=0;i<4;i++)
        {
            if(dis_empty[i]==true)
                elt=1;
        }
        if(elt==1)
        {
            elt=rand()%4;
            while (dis_empty[elt]==false) {
                elt=rand()%4;
            }
            switch (elt) {
                case 0:
                    focus_y-=1;
                    [chess_map[focus_x][focus_y] setImage:[NSImage imageNamed:@"focus_aimed_pic"]  ];
                    break;
                case 1:
                    focus_y+=1;
                    [chess_map[focus_x][focus_y] setImage:[NSImage imageNamed:@"focus_aimed_pic"]  ];
                    break;
                case 2:
                    focus_x-=1;
                    [chess_map[focus_x][focus_y] setImage:[NSImage imageNamed:@"focus_aimed_pic"]  ];
                    break;
                case 3:
                    focus_x+=1;
                    [chess_map[focus_x][focus_y] setImage:[NSImage imageNamed:@"focus_aimed_pic"]  ];
                    break;
                default:
                    break;
            }
        }
        
    }
    //  [self following_act_with_x:focus_x y:focus_y];
    
}
-(void)think_start
{
    [_rotater setHidden:false];
    [_rotater startAnimation:_rotater];
    think_flag=1;
}
-(void)think_finish
{
    [_rotater setHidden:true];
    [_rotater stopAnimation:_rotater];
    think_flag=0;
}
- (IBAction)helping_predict:(NSButton *)sender {
    teacher_on^=1;
    if(teacher_on==1)
    {
        int mapper[15][15]={};
        [ice_fiver teaching_current_step:mapper];
        for(int i=0;i<15;i++)
            for(int j=0;j<15;j++)
            {
                if(mapper[i][j]==0)
                    continue;
                
                if(mapper[i][j]>0)
                {
                    NSString* pic_name=[[NSString alloc]initWithFormat:@"blk%d",mapper[i][j]];
                    [chess_map[i][j] setImage:[NSImage imageNamed:pic_name] ];
                }
                else{
                    NSString* pic_name=[[NSString alloc]initWithFormat:@"whi%d",-mapper[i][j]];
                    [chess_map[i][j] setImage:[NSImage imageNamed:pic_name] ];
                }
            }
    }
    else{
        [self flush_chess_map_according_to:map_state];
    }
    
}
- (IBAction)ban_choice_change:(NSSegmentedControl *)sender {
    [ice_fiver set_banmode:(int)sender.selectedSegment];
    [self restart_funct];
}
- (IBAction)player_chess_change:(NSSegmentedControl *)sender {
    if(sender.selectedSegment==0)
        player_chess_id=1;
    else{
        player_chess_id=-1;
    }
    [self restart_funct];
}
- (IBAction)diff_change:(NSSegmentedControl *)sender {
    player_prefer_difficulty=(int)[sender selectedSegment];
}
-(void)change_chess_and_restart
{
    if(player_chess_id==1)
    {
        player_chess_id=-1;
        _player_choice_seg.selectedSegment=1;
    }
    else{
        player_chess_id=1;
        _player_choice_seg.selectedSegment=0;
    }
    [self restart_funct];
}
- (IBAction)sure_here:(NSButton *)sender {
    [self focus_click:chess_map[focus_x][focus_y]];
}
- (IBAction)undo_act:(NSButton *)sender {
    if(teacher_on==1){
        [self helping_predict:_player_sure_btn];
        return;
    }
    
    
    [ice_fiver withdraw_two_steps];
    [ice_fiver export_current_board:map_state];
    _db_texter.placeholderString=@"😤😤";
    [self flush_chess_map_according_to:map_state];
}
-(void) following_act_with_x:(int)x y:(int)y
{
    
    _player_sure_btn.frame=CGRectMake(2000, 1000, 40, 40);
    if(x>90 || map_state[x][y]!=0)
        return;
    
    if(y>1 && map_state[x][y-1]==0)
    {
        [ _player_sure_btn setImage :[NSImage imageNamed:@"d_downer"] ];
        float px = x*perwidth-perwidth/3+5;
        float py = ScreenHeight/2+(y-9.1)*perheight+5;
        _player_sure_btn.frame=CGRectMake(px, py, 30, 30);
    }
    else if(y<14 && map_state[x][y+1]==0)
    {
        [ _player_sure_btn setImage :[NSImage imageNamed:@"d_upper"] ];
        float px = x*perwidth-perwidth/3+5;
        float py = ScreenHeight/2+(y-6.9)*perheight+5;
        _player_sure_btn.frame=CGRectMake(px, py, 30, 30);
    }
    else if(x<14&& map_state[x+1][y]==0)
    {
        [ _player_sure_btn setImage :[NSImage imageNamed:@"d_lefter"] ];
        float px = x*perwidth-perwidth/3+perwidth*1.1+5;
        float py = ScreenHeight/2+(y-8)*perheight+5;
        _player_sure_btn.frame=CGRectMake(px, py, 30, 30);
    }
    else if(x>1&& map_state[x-1][y]==0)
    {
        [ _player_sure_btn setImage :[NSImage imageNamed:@"d_righter"] ];
        float px = x*perwidth-perwidth/3-perwidth*1.1+5;
        float py = ScreenHeight/2+(y-8)*perheight+5;
        _player_sure_btn.frame=CGRectMake(px, py, 40, 40);
    }
    
    [self.view addSubview:_player_sure_btn];
}
@end
