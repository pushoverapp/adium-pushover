#import <Adium/AIActionDetailsPane.h>

@class AILocalizationTextField;

@interface PushoverDetailPane : AIActionDetailsPane {
	IBOutlet	NSTextField	*pushover_key;
	IBOutlet	NSTextField	*pushover_device_name;
	IBOutlet	NSTextField	*pushover_link_label;
	IBOutlet	NSButton	*only_when_away;
	IBOutlet	NSButton	*only_when_locked;

	BOOL		when_away;
	BOOL		when_locked;
}

- (IBAction)awayClicked:(id)sender;
- (IBAction)lockedClicked:(id)sender;

@end
