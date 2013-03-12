#import "PushoverPlugin.h"
#import "PushoverDetailPane.h"
#import "NSAttributedString+Hyperlink.h"

#import "JSONKit.h"

static NSMutableDictionary *cachedSoundList;

@implementation PushoverDetailPane

- (NSString *)nibName {
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

	[pushover_link_label setAllowsEditingTextAttributes: YES];
	[pushover_link_label setSelectable: YES];

	NSMutableAttributedString* string = [[NSMutableAttributedString alloc]
		initWithString:@"Find your user key or create an account at "];
	NSURL* url = [NSURL URLWithString:@"https://pushover.net/"];

	[string appendAttributedString:[NSAttributedString
		hyperlinkFromString:@"https://pushover.net/" withURL:url]];
	[pushover_link_label setAttributedStringValue: string];

	[sound removeAllItems];
	[sound addItemsWithTitles:[[[PushoverDetailPane soundList] allValues]
		sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
	[sound insertItemWithTitle:@"(Device default sound)" atIndex:0];

	NSString *sel_sound = [inDetails objectForKey:KEY_PUSHOVER_SOUND];
	if (sel_sound != nil) {
		/* map sound name to description */
		NSString *v = [[PushoverDetailPane soundList] valueForKey:sel_sound];
		if (v != nil)
			[sound selectItemWithTitle:v];
	}

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
	NSString *sel_sound = @"";

	/* find key in soundList for selected sound description */
	if ([sound selectedItem] != nil) {
		NSString *sound_t = [[sound selectedItem] title];
		NSArray *v = [[PushoverDetailPane soundList] allKeysForObject:sound_t];
		if (v != nil && [v count] > 0)
			sel_sound = [v objectAtIndex:0];
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:
		[pushover_key stringValue], KEY_PUSHOVER_KEY,
		[pushover_device_name stringValue], KEY_PUSHOVER_DEVICE_NAME,
		[[NSNumber alloc] initWithBool:when_away], KEY_ONLY_WHEN_AWAY,
		[[NSNumber alloc] initWithBool:when_locked], KEY_ONLY_WHEN_LOCKED,
		sel_sound, KEY_PUSHOVER_SOUND,
		nil];
}

+ (void)fetchSoundList
{
	NSURLResponse *response;
	NSError *error;

	cachedSoundList = [[NSMutableDictionary alloc] initWithCapacity:1];

	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL
		URLWithString:[NSString stringWithFormat:@"%s",
		PUSHOVER_API_SOUNDS_URL]]];
	NSData *d = [NSURLConnection sendSynchronousRequest:request
		returningResponse:&response error:&error];

	JSONDecoder *decoder = [[JSONDecoder alloc]
		initWithParseOptions:JKParseOptionNone];

	NSDictionary *json = [decoder parseJSONData:d];
	if (json != nil) {
		NSDictionary *s = [json objectForKey:@"sounds"];
		if (s != nil)
			[cachedSoundList setDictionary:[NSDictionary
				dictionaryWithObjects:[s allValues] forKeys:[s allKeys]]];
	}
}

+ (NSDictionary *)soundList
{
	if (cachedSoundList == nil || [cachedSoundList count] == 0)
		[PushoverDetailPane fetchSoundList];

	return cachedSoundList;
}

@end
