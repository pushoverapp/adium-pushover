#import <Adium/AIActionDetailsPane.h>

@class AILocalizationTextField;

@interface PushoverDetailPane : AIActionDetailsPane {
	IBOutlet	NSTextField	*pushover_key;
	IBOutlet	NSTextField	*pushover_device_name;
	IBOutlet	NSTextField	*pushover_link_label;
	IBOutlet	NSButton	*only_when_away;
	IBOutlet	NSButton	*only_when_locked;
	IBOutlet	NSPopUpButton	*sound;

	BOOL		when_away;
	BOOL		when_locked;
}

+ (void)fetchSoundList;
+ (NSDictionary *)soundList;

- (IBAction)awayClicked:(id)sender;
- (IBAction)lockedClicked:(id)sender;

@end
