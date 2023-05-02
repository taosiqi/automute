#import "MJMenuBarController.h"
#import "MJUserDefaults.h"
#import "YLStatusItemPopupDisplayer.h"
#import "WelcomePopupView.h"
#import "NSImage+YLUtil.h"
#import "LaunchAtLoginPopupView.h"

static const NSInteger MENU_ITEM_DISABLE_MUTING = 101;
static const NSInteger MENU_ITEM_ENABLE_MUTING = 102;
static const NSInteger MENU_ITEM_LAUNCH_AT_LOGIN = 103;
static const NSInteger MENU_ITEM_MUTE_ON_SLEEP = 104;
static const NSInteger MENU_ITEM_MUTE_ON_HEADPHONES = 105;
static const NSInteger MENU_ITEM_MUTE_NOTIFICATIONS = 106;
static const NSInteger MENU_ITEM_MUTE_ON_LOCK = 107;
static const NSInteger MENU_ITEM_HIDE_MENU_BAR_ICON = 108;

static const NSInteger MENU_ITEM_DISABLE_1H = 201;
static const NSInteger MENU_ITEM_DISABLE_6H = 202;
static const NSInteger MENU_ITEM_DISABLE_12H = 203;
static const NSInteger MENU_ITEM_DISABLE_24H = 204;
static const NSInteger MENU_ITEM_DISABLE_FOREVER = 205;

@interface MJMenuBarController () <NSMenuDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) YLStatusItemPopupDisplayer *popoverDisplayer;
@property(nonatomic, weak) id <MJMenuBarControllerDelegate> delegate;
@end

@implementation MJMenuBarController

- (instancetype)initWithDelegate:(id<MJMenuBarControllerDelegate>)delegate
             headphonesConnected:(BOOL)headphonesConnected
{
    self = [super init];
    if (!self) return nil;

    self.delegate = delegate;

    [self createAndAddStatusBarItem:headphonesConnected];
    self.popoverDisplayer = [[YLStatusItemPopupDisplayer alloc] initWithStatusItem:self.statusItem];

    return self;
}

- (void)createAndAddStatusBarItem:(BOOL)headphonesConnected
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = [self createMenuWithItems];
    [self updateMenuIcon:headphonesConnected];
}

- (NSMenu *)createMenuWithItems
{
    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    [menu addItem:[self buildVersionMenuItem]];
    [menu addItem:[self buildMenuItemWithTitle:@"Welcome" action:@selector(showWelcomePopup)]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *triggersItem = [self buildMenuItemWithTitle:@"Mute Triggers" action:nil];
    NSMenu *muteOnSubmenu = [[NSMenu alloc] init];
    [muteOnSubmenu addItem:[self buildMenuItemWithTitle:@"Mac Goes to Sleep" action:@selector(muteOnSleepToggled) tag:MENU_ITEM_MUTE_ON_SLEEP]];
    [muteOnSubmenu addItem:[self buildMenuItemWithTitle:@"Mac Gets Locked / Enters Screen Saver" action:@selector(muteOnLockToggled) tag:MENU_ITEM_MUTE_ON_LOCK]];
    [muteOnSubmenu addItem:[self buildMenuItemWithTitle:@"Headphones Disconnected" action:@selector(muteOnHeadphonesToggled) tag:MENU_ITEM_MUTE_ON_HEADPHONES]];
    triggersItem.submenu = muteOnSubmenu;
    [menu addItem:triggersItem];
    [menu addItem:[self buildMenuItemWithTitle:@"Show Notifications" action:@selector(muteNotificationsToggled) tag:MENU_ITEM_MUTE_NOTIFICATIONS]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self buildMenuItemWithTitle:@"Enable" action:@selector(enableMute) tag:MENU_ITEM_ENABLE_MUTING]];
    NSMenuItem *disableItem = [self buildMenuItemWithTitle:@"Disable" action:@selector(disableMutingTimeClicked:) tag:MENU_ITEM_DISABLE_MUTING];
    NSMenu *disableSubmenu = [[NSMenu alloc] init];
    [disableSubmenu addItem:[self buildMenuItemWithTitle:@"Disable" action:@selector(disableMutingTimeClicked:) tag:MENU_ITEM_DISABLE_FOREVER]];
    [disableSubmenu addItem:[self buildMenuItemWithTitle:@"For 1 Hour" action:@selector(disableMutingTimeClicked:) tag:MENU_ITEM_DISABLE_1H]];
    [disableSubmenu addItem:[self buildMenuItemWithTitle:@"For 6 Hours" action:@selector(disableMutingTimeClicked:) tag:MENU_ITEM_DISABLE_6H]];
    [disableSubmenu addItem:[self buildMenuItemWithTitle:@"For 12 Hours" action:@selector(disableMutingTimeClicked:) tag:MENU_ITEM_DISABLE_12H]];
    [disableSubmenu addItem:[self buildMenuItemWithTitle:@"For 24 Hours" action:@selector(disableMutingTimeClicked:) tag:MENU_ITEM_DISABLE_24H]];
    disableItem.submenu = disableSubmenu;
    [menu addItem:disableItem];

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self buildMenuItemWithTitle:@"Hide Menu Bar Icon" action:@selector(hideMenuBarIconToggled) tag:MENU_ITEM_HIDE_MENU_BAR_ICON]];
    [menu addItem:[self buildMenuItemWithTitle:@"Launch at Login" action:@selector(launchAtLoginToggled) tag:MENU_ITEM_LAUNCH_AT_LOGIN]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self buildMenuItemWithTitle:@"Quit" action:@selector(quit)]];
    return menu;
}

- (NSMenuItem *)buildMenuItemWithTitle:(NSString *)title action:(SEL)action tag:(const NSInteger)tag
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
    item.tag = tag;
    item.target = self;
    return item;
}

- (NSMenuItem *)buildMenuItemWithTitle:(NSString *)title action:(SEL)action
{
    return [self buildMenuItemWithTitle:title action:action tag:nil];
}

- (NSMenuItem *)buildVersionMenuItem
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *versionTitle = [NSString stringWithFormat:@"%@ v%@ [%@]", info[@"CFBundleName"], info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"] ];
    NSMenuItem *versionItem = [self buildMenuItemWithTitle:versionTitle action:nil];
    versionItem.enabled = NO;
    return versionItem;
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [self.popoverDisplayer hidePopoverWithAnimate:NO];
}

- (void)disableMutingTimeClicked:(NSView *)sender
{
    int hoursUntilEnabled;
    switch (sender.tag) {
        case MENU_ITEM_DISABLE_1H:
            hoursUntilEnabled = 1;
            break;
        case MENU_ITEM_DISABLE_6H:
            hoursUntilEnabled = 6;
            break;
        case MENU_ITEM_DISABLE_12H:
            hoursUntilEnabled = 12;
            break;
        case MENU_ITEM_DISABLE_24H:
            hoursUntilEnabled = 24;
            break;
        case MENU_ITEM_DISABLE_FOREVER:
            hoursUntilEnabled = -1;
            break;
        default:
            return;
    }
    [self.popoverDisplayer hidePopoverWithAnimate:YES];

    [self.delegate menuBarController_disableMutingFor:hoursUntilEnabled];
}

- (void)enableMute
{
    [self.delegate menuBarController_enableMuting];
}

- (void)muteOnSleepToggled
{
    [self.delegate menuBarController_setMuteOnSleep:![self.delegate menuBarController_isSetToMuteOnSleep]];
}

- (void)muteOnLockToggled
{
    [self.delegate menuBarController_setMuteOnLock:![self.delegate menuBarController_isSetToMuteOnLock]];
}

- (void)muteOnHeadphonesToggled
{
    [self.delegate menuBarController_setMuteOnHeadphones:![self.delegate menuBarController_isSetToMuteOnHeadphones]];
}

- (void)launchAtLoginToggled
{
    [self.delegate menuBarController_setLaunchAtLogin:![self.delegate menuBarController_isSetToLaunchAtLogin]];
}

- (void)muteNotificationsToggled
{
    [self.delegate menuBarController_toggleMuteNotifications];
}

- (void)hideMenuBarIconToggled
{
    [self.delegate menuBarController_toggleHideMenuBarIcon];
}

- (void)showWelcomePopup
{
    NSArray *topLevelObjects;
    [[NSBundle mainBundle] loadNibNamed:@"WelcomePopup" owner:self topLevelObjects:&topLevelObjects];
    WelcomePopupView *popup = topLevelObjects[[topLevelObjects indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isKindOfClass:[WelcomePopupView class]];
    }]];
    popup.gotItButton.target = self;
    popup.gotItButton.action = @selector(welcomeGotItClicked);

    [self.popoverDisplayer displayPopoverWithView:popup shouldCloseOnOutsideTouches:YES];
}

- (void)welcomeGotItClicked
{
    [MJUserDefaults.shared setSawWelcomeScreen];
    [self showLaunchAtLoginPopup];
}

- (void)showLaunchAtLoginPopup
{
    NSArray *topLevelObjects;
    [[NSBundle mainBundle] loadNibNamed:@"LaunchAtLoginPopup" owner:self topLevelObjects:&topLevelObjects];
    LaunchAtLoginPopupView *popup = topLevelObjects[[topLevelObjects indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isKindOfClass:[LaunchAtLoginPopupView class]];
    }]];
    popup.yesButton.target = popup.noButton.target = self;
    popup.yesButton.action = @selector(launchAtLoginYesClicked);
    popup.noButton.action = @selector(launchAtLoginNoClicked);

    [self.popoverDisplayer displayPopoverWithView:popup shouldCloseOnOutsideTouches:YES];
}

- (void)launchAtLoginYesClicked
{
    [MJUserDefaults.shared setSawLaunchAtLoginPopup];
    [self.popoverDisplayer hidePopoverWithAnimate:YES];
    [self.delegate menuBarController_setLaunchAtLogin:YES];
}

- (void)launchAtLoginNoClicked
{
    [MJUserDefaults.shared setSawLaunchAtLoginPopup];
    [self.popoverDisplayer hidePopoverWithAnimate:YES];
    [self.delegate menuBarController_setLaunchAtLogin:NO];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (MJUserDefaults.shared.isMutingDisabled) {
        if (menuItem.tag == MENU_ITEM_DISABLE_MUTING) {
            return NO;
        }
    } else {
        if (menuItem.tag == MENU_ITEM_ENABLE_MUTING) {
            return NO;
        }
    }
    if (menuItem.tag == MENU_ITEM_LAUNCH_AT_LOGIN) {
        menuItem.state = [self.delegate menuBarController_isSetToLaunchAtLogin] ? NSOnState : NSOffState;
    }
    if (menuItem.tag == MENU_ITEM_MUTE_NOTIFICATIONS) {
        menuItem.state = MJUserDefaults.shared.areMuteNotificationsEnabled ? NSOnState : NSOffState;
    }
    if (menuItem.tag == MENU_ITEM_HIDE_MENU_BAR_ICON) {
        menuItem.state = MJUserDefaults.shared.isMenuBarIconHidden ? NSOnState : NSOffState;
    }
    if (menuItem.tag == MENU_ITEM_MUTE_ON_SLEEP) {
        menuItem.state = [self.delegate menuBarController_isSetToMuteOnSleep] ? NSOnState : NSOffState;
    }
    if (menuItem.tag == MENU_ITEM_MUTE_ON_LOCK) {
        menuItem.state = [self.delegate menuBarController_isSetToMuteOnLock] ? NSOnState : NSOffState;
    }
    if (menuItem.tag == MENU_ITEM_MUTE_ON_HEADPHONES) {
        menuItem.state = [self.delegate menuBarController_isSetToMuteOnHeadphones] ? NSOnState : NSOffState;
    }

    return YES;
}

- (void)updateMenuIcon:(BOOL)headphonesConnected
{
    self.statusItem.button.image = [self generateMenuIconImage:headphonesConnected];
}

- (NSImage *)generateMenuIconImage:(BOOL)headphonesConnected
{
    if (MJUserDefaults.shared.isMutingDisabled) {
        return [[NSImage imageNamed:headphonesConnected ? @"hp_connected" : @"hp_disconnected_noalpha"]
                imageTintedWithColor:[NSColor colorWithRed:1 green:0.3 blue:0.2 alpha:1.0]];
    } else {
        return [NSImage imageNamed:headphonesConnected ? @"hp_connected" : @"hp_disconnected"];
    }
}

-(void)quit
{
    [self.delegate menuBarController_quit];
}

- (void)forceRemoveFromMenuBar
{
    // Note: this causes the menu bar item to lose its current position.
    //  Next time it shows it'll reset to the leftmost position.
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

@end
