#import "PushoverPlugin.h"
#import "PushoverDetailPane.h"

@implementation PushoverDetailPane

- (NSString *)nibName{
    return @"Pushover";    
}

- (void)configureForActionDetails:(NSDictionary *)inDetails
	listObject:(AIListObject *)inObject
{
	NSString *key = [inDetails objectForKey:KEY_PUSHOVER_KEY];
	[pushover_key setStringValue:(key ? key : @"")];

	NSString *device = [inDetails objectForKey:KEY_PUSHOVER_DEVICE_NAME];
	[pushover_device_name setStringValue:(device ? device : @"")];

	when_away = [(NSNumber *)[inDetails objectForKey:KEY_ONLY_WHEN_AWAY]
		boolValue];
	[only_when_away setState:when_away];

	when_locked = [(NSNumber *)[inDetails objectForKey:KEY_ONLY_WHEN_LOCKED]
		boolValue];
	[only_when_locked setState:when_locked];

	[super configureForActionDetails:inDetails listObject:inObject];
}

- (IBAction)awayClicked:(id)sender
{
	when_away = !when_away;
}

- (IBAction)lockedClicked:(id)sender
{
	when_locked = !when_locked;
}

- (NSDictionary *)actionDetails
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[pushover_key stringValue], KEY_PUSHOVER_KEY,
		[pushover_device_name stringValue], KEY_PUSHOVER_DEVICE_NAME,
		[[NSNumber alloc] initWithBool:when_away], KEY_ONLY_WHEN_AWAY,
		[[NSNumber alloc] initWithBool:when_locked], KEY_ONLY_WHEN_LOCKED,
		nil];
}

@end

