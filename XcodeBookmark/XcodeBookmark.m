//
//  XcodeBookmark.h
//  XcodeBookmark
//
//  Created by Nick Xiao on 4.18.2015
//  Copyright (c) 2015 Nick Xiao. All rights reserved.
//

#import "XcodeBookmark.h"
#import "Xcode.h"

static id _sharedInstance = nil;
@implementation XcodeBookmark

+ (void)pluginDidLoad:(NSBundle *) plugin
{
	static dispatch_once_t onceToken;
	NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
	if ([currentApplicationName isEqual:@"Xcode"]) {
		dispatch_once(&onceToken, ^{
			_sharedInstance = [[self alloc] init];
		});
	}
}

+ (instancetype) sharedInstance
{
	return _sharedInstance;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
	}
	return self;
}

#pragma mark - dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notifications

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self createBookmarkMenuItems];
}

#pragma mark - menu

- (void) createBookmarkMenuItems
{
	NSMenuItem *navi = [[NSApp mainMenu] itemWithTitle:@"Navigate"];
	NSMenu *naviSubmenu = navi.submenu;
	NSUInteger location = 0;
	
	unichar c = NSF2FunctionKey;
	NSString *f2 = [NSString stringWithCharacters:&c length:1];
	[naviSubmenu insertItem:[NSMenuItem separatorItem] atIndex:location];
	
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Clear All Bookmarks"
													  action:@selector(clearAllBookmarks)
											   keyEquivalent: f2];
		[item setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
		item.target = self;
		[naviSubmenu insertItem:item atIndex:location];
	}
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Prev Bookmark"
													  action:@selector(goPrevBookmark)
											   keyEquivalent: f2];
		[item setKeyEquivalentModifierMask:NSShiftKeyMask];
		item.target = self;
		[naviSubmenu insertItem:item atIndex:location];
	}
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Next Bookmark"
													  action:@selector(goNextBookmark)
											   keyEquivalent: f2];
		[item setKeyEquivalentModifierMask:0];
		item.target = self;
		[naviSubmenu insertItem:item atIndex:location];
	}
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Toggle Bookmark"
													  action:@selector(toggleBookmark)
											   keyEquivalent: f2];
		[item setKeyEquivalentModifierMask:NSCommandKeyMask];
		item.target = self;
		[naviSubmenu insertItem:item atIndex:location];
	}
	
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	if ([menuItem action] == @selector(goNextBookmark) ||
		[menuItem action] == @selector(goPrevBookmark) ||
		[menuItem action] == @selector(clearAllBookmarks)){
		return [self hasBookmarks];
	}
	
	if ([menuItem action] == @selector(toggleBookmark)){
		return !![self currentSourceCodeEditor];
	}
	
	return YES;
}

#pragma mark - menu selector
#define BOOKMARK_TAG @"!\"Bookmark\""
- (void)toggleBookmark
{
	IDESourceCodeEditor *currentSourceCodeEditor = [self currentSourceCodeEditor];
	
	if (!currentSourceCodeEditor)
	{
		NSBeep();
		return;
	}
	
	long long lineNumber = [self currentLineNumberWithEditor:currentSourceCodeEditor];
	DVTTextDocumentLocation *documentLocation = [self documentLocationWithLineNumber:lineNumber];
	
	IDEWorkspace *workspace = [self currentWorkspace];
	IDEFileBreakpoint *breakpoint = [workspace.breakpointManager fileBreakpointAtDocumentLocation:documentLocation];
	if (breakpoint)
	{
		[workspace.breakpointManager removeBreakpoint: breakpoint];
	}
	else
	{
		breakpoint = [workspace.breakpointManager createFileBreakpointAtDocumentLocation:documentLocation];
		breakpoint.continueAfterRunningActions = YES;
		breakpoint.condition = BOOKMARK_TAG;
		breakpoint.ignoreCount = 30721;
		breakpoint.shouldBeEnabled = NO;
	}
}

- (BOOL) isCurrentDocumentBookmark: (IDEFileBreakpoint*) breakpoint
{
	IDEEditorContext *editorContext = [self currentEditorContext];
	IDEEditorHistoryStack *stack = [editorContext currentHistoryStack];
	NSString* currentDocument = stack.currentEditorHistoryItem.documentURL.path;
	
	return [breakpoint isKindOfClass:[IDEFileBreakpoint class]] &&
	[breakpoint.condition isEqualTo: BOOKMARK_TAG] &&
	[breakpoint.location.documentURL.path isEqualToString: currentDocument];
}

- (void) clearAllBookmarks
{
	IDEWorkspace *workspace = [self currentWorkspace];
	NSMutableSet *bookmarks = [NSMutableSet set];

	for (IDEFileBreakpoint *breakpoint in workspace.breakpointManager.breakpoints) {
		if ([self isCurrentDocumentBookmark:breakpoint]) {
			[bookmarks addObject:breakpoint];
		}
	}
	
	for (id bookmark in bookmarks) {
		[workspace.breakpointManager removeBreakpoint: bookmark];
	}
}

- (BOOL) hasBookmarks
{
	for (IDEFileBreakpoint *breakpoint in [self currentWorkspace].breakpointManager.breakpoints)
	{
		if ([self isCurrentDocumentBookmark:breakpoint]) {
			return YES;
		}
	}
	return NO;
}

- (NSUInteger) nextLocation: (NSUInteger)currentLine direction: (BOOL) down
{
	if (down)
	{
		NSUInteger smallest = -1;
		NSUInteger distance = -1;
		
		for (IDEFileBreakpoint *breakpoint in [self currentWorkspace].breakpointManager.breakpoints)
		{
			if ([self isCurrentDocumentBookmark:breakpoint]) {
				NSUInteger loc = breakpoint.location.lineRange.location;
				if (loc < smallest) smallest = loc;
				if (loc > currentLine && loc - currentLine < distance)
				{
					distance = loc - currentLine;
				}
			}
		}
		
		if (distance != -1)
			return currentLine + distance;
		else if (smallest != -1)
			return smallest;
		else
			return 0;
	}
	else
	{
		NSUInteger largest = 0;
		NSUInteger distance = -1;
		
		for (IDEFileBreakpoint *breakpoint in [self currentWorkspace].breakpointManager.breakpoints)
		{
			if ([self isCurrentDocumentBookmark:breakpoint]) {
				NSUInteger loc = breakpoint.location.lineRange.location;
				if (loc > largest) largest = loc;
				if (loc < currentLine && currentLine - loc < distance)
				{
					distance = currentLine - loc;
				}
			}
		}
		
		if (distance != -1)
			return currentLine - distance;
		else if (largest != 0)
			return largest;
		else
			return 0;
	}
	return 0;
}

- (void) goNextBookmark
{
	[self goBookmark:YES];
}

- (void) goBookmark: (BOOL) down
{
	IDESourceCodeEditor *currentSourceCodeEditor = [self currentSourceCodeEditor];
	
	if (! currentSourceCodeEditor)
	{
		NSBeep();
		return;
	}
	
	long long currentLine = [self currentLineNumberWithEditor:currentSourceCodeEditor];
	
	NSUInteger nextBookmark = [self nextLocation:currentLine direction: down];
	if (! nextBookmark)
	{
		NSBeep();
		return;
	}
	
	NSTextView *textView = [self currentSourceCodeTextView];
	NSString* content = textView.textStorage.string;
	
	// get NSRange by line number
	__block NSUInteger lineNumber = 0;
	__block NSUInteger location = 0;
	__block NSRange range = NSMakeRange(0, 0);
	[content enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		lineNumber ++;
		if (lineNumber == nextBookmark)
		{
			range = NSMakeRange(location, [line length] ? [line length] : 1);
			*stop = YES;
			return;
		}
		
		location += [line length];
		
		NSString* lineEnding = [content substringWithRange: NSMakeRange(location, MIN(2, [content length] - location))];
		location += [lineEnding isEqualToString:@"\r\n"] ? 2 : 1;
	}];
	
	[textView setSelectedRange:NSMakeRange(range.location, 0)];
	[textView scrollRangeToVisible:range];
	[textView showFindIndicatorForRange:range];
}

- (void) goPrevBookmark
{
	[self goBookmark:NO];
}


//
//  Helper methods that come from Tuna
//
//  Created by Toshihiro Morimoto on 3/11/15.
//  Copyright (c) 2015 Toshihiro Morimoto. All rights reserved.
//
#pragma mark - private

- (DVTTextDocumentLocation *)documentLocationWithLineNumber:(long long)lineNumber
{
	IDEEditorContext *editorContext = [self currentEditorContext];
	IDEEditorHistoryStack *stack = [editorContext currentHistoryStack];
	NSNumber *timestamp = @([[NSDate date] timeIntervalSince1970]);
	return [[DVTTextDocumentLocation alloc] initWithDocumentURL:stack.currentEditorHistoryItem.documentURL
													  timestamp:timestamp
													  lineRange:NSMakeRange(MAX(lineNumber, 0), lineNumber)];
}

#pragma mark - IDE helper

- (IDEWorkspace *)currentWorkspace
{
	NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
	if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
		return [currentWindowController valueForKey:@"_workspace"];
	}
	else {
		return nil;
	}
}

- (IDEEditorContext *)currentEditorContext
{
	NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
	if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
		IDEEditorArea *editorArea = [(IDEWorkspaceWindowController *)currentWindowController editorArea];
		return [editorArea lastActiveEditorContext];
	}
	else {
		return nil;
	}
}

- (IDEEditor *)currentEditor
{
	IDEEditorContext *editorContext = [self currentEditorContext];
	if (editorContext) {
		return [editorContext editor];
	}
	else {
		return nil;
	}
}

/// SourceCodeEditor Type.
typedef NS_ENUM(NSInteger, EditorType)
{
	EditorTypeOther,
	EditorTypeSourceCodeEditor,
	EditorTypeSourceCodeComparisonEditor
};

- (EditorType)editorTypeOf:(IDEEditor *)editor
{
	NSDictionary* editors = @{
							  @"IDESourceCodeEditor" : @(EditorTypeSourceCodeEditor),
							  @"IDESourceCodeComparisonEditor" : @(EditorTypeSourceCodeComparisonEditor)
							  };
	
	for (NSString* className in editors.allKeys)
	{
		if ([editor isKindOfClass:NSClassFromString(className)])
		{
			return (EditorType)[editors[className] integerValue];
		}
	}
	
	return EditorTypeOther;
}

- (IDESourceCodeEditor *)currentSourceCodeEditor
{
	IDEEditor *editor = [self currentEditor];
	
	switch ([self editorTypeOf:editor])
	{
		case EditorTypeSourceCodeEditor:
			return (IDESourceCodeEditor *)editor;
			
		case EditorTypeSourceCodeComparisonEditor:
			return [self getKeySourceCodeEditorOnlyIfKeyEditorIsEqualToPrimaryEditor:(IDESourceCodeComparisonEditor*)editor];
			
		case EditorTypeOther:
			return nil;
	}
}

- (BOOL)isKeyEditorEqualToPrimaryEditor:(IDESourceCodeComparisonEditor*)sourceCodeComparisonEditor
{
	return sourceCodeComparisonEditor.keyEditor == sourceCodeComparisonEditor.primaryEditorInstance;
}

- (IDESourceCodeEditor *)getKeySourceCodeEditorOnlyIfKeyEditorIsEqualToPrimaryEditor:(IDESourceCodeComparisonEditor*)sourceCodeComparisonEditor
{
	if ([self isKeyEditorEqualToPrimaryEditor:sourceCodeComparisonEditor])
	{
		return [self getKeySourceCodeEditor:sourceCodeComparisonEditor];
	}
	else
	{
		return nil;
	}
}

- (IDESourceCodeEditor *)getKeySourceCodeEditor:(IDESourceCodeComparisonEditor*)sourceCodeComparisonEditor
{
	IDEEditor *editor = sourceCodeComparisonEditor.keyEditor;
	
	switch ([self editorTypeOf:editor])
	{
		case EditorTypeSourceCodeEditor:
			return (IDESourceCodeEditor*)editor;
			
		case EditorTypeSourceCodeComparisonEditor:
		case EditorTypeOther:
			return nil;
	}
}


- (NSTextView *)currentSourceCodeTextView
{
	IDEEditor *editor = [self currentEditor];
	
	switch ([self editorTypeOf:editor])
	{
		case EditorTypeSourceCodeEditor:
			return (NSTextView *)editor.textView;
			
		case EditorTypeSourceCodeComparisonEditor:
			return (NSTextView *)((IDESourceCodeComparisonEditor *)editor).keyTextView;
			
		case EditorTypeOther:
			return nil;
	}
}

- (long long)currentLineNumberWithEditor:(IDESourceCodeEditor *)editor
{
	return [editor respondsToSelector:@selector(_currentOneBasedLineNumber)] ? editor._currentOneBasedLineNumber : editor._currentOneBasedLineNubmer;
}

@end
