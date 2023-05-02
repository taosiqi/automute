#import "MJUserDefaults.h"


static NSString *const SAW_WELCOME = @"SAW_WELCOME";
static NSString *const SAW_LAUNCH_AT_LOGIN_POPUP = @"SAW_LAUNCH_AT_LOGIN_POPUP";
static NSString *const MUTING_DISABLED = @"MUTING_DISABLED";
static NSString *const SCHEDULED_TIME_TO_ENABLE_MUTING = @"SCHEDULED_TIME_TO_ENABLE_MUTING";
static NSString *const MUTE_ON_SLEEP = @"MUTE_ON_SLEEP";
static NSString *const MUTE_ON_LOCK = @"MUTE_ON_LOCK";
static NSString *const MUTE_ON_HEADPHONES = @"MUTE_ON_HEADPHONES";
static NSString *const MUTE_NOTIFICATIONS_ENABLED = @"MUTE_NOTIFICATIONS_ENABLED";
static NSString *const MENU_BAR_ICON_HIDDEN = @"MENU_BAR_ICON_HIDDEN";

@interface MJUserDefaults ()
@property(nonatomic, strong) NSUserDefaults *defaults;
@end

@implementation MJUserDefaults

+ (instancetype)shared
{
    static MJUserDefaults *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.defaults registerDefaults:@{
            MUTE_ON_SLEEP: @(YES),
            MUTE_ON_LOCK: @(YES),
            MUTE_ON_HEADPHONES: @(YES),
            MUTE_NOTIFICATIONS_ENABLED: @(YES),
            MENU_BAR_ICON_HIDDEN: @(NO),
    }];


    return self;
}

-(void)setSawWelcomeScreen
{
    [self.defaults setBool:YES forKey:SAW_WELCOME];
    [self.defaults synchronize];
}

-(BOOL)didSeeWelcomeScreen
{
    return [self.defaults boolForKey:SAW_WELCOME];
}

- (void)setSawLaunchAtLoginPopup
{
    [self.defaults setBool:YES forKey:SAW_LAUNCH_AT_LOGIN_POPUP];
    [self.defaults synchronize];
}

- (BOOL)didSeeLaunchAtLoginPopup
{
    return [self.defaults boolForKey:SAW_LAUNCH_AT_LOGIN_POPUP];
}

- (void)setMutingDisabled:(BOOL)disabled
{
    [self.defaults setBool:disabled forKey:MUTING_DISABLED];
    [self.defaults synchronize];
}

- (BOOL)isMutingDisabled
{
    return [self.defaults boolForKey:MUTING_DISABLED];
}

- (void)setScheduledTimeToEnableMuting:(NSTimeInterval)date
{
    [self.defaults setDouble:date forKey:SCHEDULED_TIME_TO_ENABLE_MUTING];
    [self.defaults synchronize];
}

- (NSTimeInterval)getScheduledTimeToEnableMuting
{
    return [self.defaults doubleForKey:SCHEDULED_TIME_TO_ENABLE_MUTING];
}

- (BOOL)isSetToMuteOnSleep
{
    return [self.defaults boolForKey:MUTE_ON_SLEEP];
}

- (void)setMuteOnSleep:(BOOL)muteOnSleep
{
    [self.defaults setBool:muteOnSleep forKey:MUTE_ON_SLEEP];
    [self.defaults synchronize];
}

- (BOOL)isSetToMuteOnLock
{
    return [self.defaults boolForKey:MUTE_ON_LOCK];
}

- (void)setMuteOnLock:(BOOL)muteOnLock
{
    [self.defaults setBool:muteOnLock forKey:MUTE_ON_LOCK];
    [self.defaults synchronize];
}

- (BOOL)isSetToMuteOnHeadphones
{
    return [self.defaults boolForKey:MUTE_ON_HEADPHONES];
}

- (void)setMuteOnHeadphones:(BOOL)muteOnHeadphones
{
    [self.defaults setBool:muteOnHeadphones forKey:MUTE_ON_HEADPHONES];
    [self.defaults synchronize];
}

- (BOOL)areMuteNotificationsEnabled
{
    return [self.defaults boolForKey:MUTE_NOTIFICATIONS_ENABLED];
}

- (void)setMuteNotificationsEnabled:(BOOL)muteNotificationsEnabled
{
    [self.defaults setBool:muteNotificationsEnabled forKey:MUTE_NOTIFICATIONS_ENABLED];
    [self.defaults synchronize];
}

- (BOOL)isMenuBarIconHidden
{
    return [self.defaults boolForKey:MENU_BAR_ICON_HIDDEN];
}

- (void)setMenuBarIconHidden:(BOOL)menuBarIconHidden
{
    [self.defaults setBool:menuBarIconHidden forKey:MENU_BAR_ICON_HIDDEN];
    [self.defaults synchronize];
}

@end
