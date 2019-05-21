/*
 * MacVim.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class MacVimItem, MacVimApplication, MacVimColor, MacVimDocument, MacVimWindow, MacVimAttributeRun, MacVimCharacter, MacVimParagraph, MacVimText, MacVimAttachment, MacVimWord, MacVimPrintSettings;

enum MacVimSavo {
	MacVimSavoAsk = 'ask ' /* Ask the user whether or not to save the file. */,
	MacVimSavoNo = 'no  ' /* Do not save the file. */,
	MacVimSavoYes = 'yes ' /* Save the file. */
};
typedef enum MacVimSavo MacVimSavo;

enum MacVimEnum {
	MacVimEnumStandard = 'lwst' /* Standard PostScript error handling */,
	MacVimEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum MacVimEnum MacVimEnum;

@protocol MacVimGenericMethods

- (void) closeSaving:(MacVimSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.

@end



/*
 * Standard Suite
 */

// A scriptable object.
@interface MacVimItem : SBObject <MacVimGenericMethods>

@property (copy) NSDictionary *properties;  // All of the object's properties.


@end

// An application's top level scripting object.
@interface MacVimApplication : SBApplication

- (SBElementArray<MacVimDocument *> *) documents;
- (SBElementArray<MacVimWindow *> *) windows;

@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *name;  // The name of the application.
@property (copy, readonly) NSString *version;  // The version of the application.

- (MacVimDocument *) open:(NSURL *)x;  // Open an object.
- (void) print:(NSURL *)x printDialog:(BOOL)printDialog withProperties:(MacVimPrintSettings *)withProperties;  // Print an object.
- (void) quitSaving:(MacVimSavo)saving;  // Quit an application.

@end

// A color.
@interface MacVimColor : MacVimItem


@end

// A document.
@interface MacVimDocument : MacVimItem

@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy) NSString *name;  // The document's name.
@property (copy) NSString *path;  // The document's path.


@end

// A window.
@interface MacVimWindow : MacVimItem

@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (copy, readonly) MacVimDocument *document;  // The document whose contents are being displayed in the window.
@property (readonly) BOOL floating;  // Whether the window floats.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property (readonly) BOOL miniaturizable;  // Whether the window can be miniaturized.
@property BOOL miniaturized;  // Whether the window is currently miniaturized.
@property (readonly) BOOL modal;  // Whether the window is the application's current modal window.
@property (copy) NSString *name;  // The full title of the window.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property (readonly) BOOL titled;  // Whether the window has a title bar.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.


@end



/*
 * Text Suite
 */

// This subdivides the text into chunks that all have the same attributes.
@interface MacVimAttributeRun : MacVimItem

- (SBElementArray<MacVimAttachment *> *) attachments;
- (SBElementArray<MacVimAttributeRun *> *) attributeRuns;
- (SBElementArray<MacVimCharacter *> *) characters;
- (SBElementArray<MacVimParagraph *> *) paragraphs;
- (SBElementArray<MacVimWord *> *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into characters.
@interface MacVimCharacter : MacVimItem

- (SBElementArray<MacVimAttachment *> *) attachments;
- (SBElementArray<MacVimAttributeRun *> *) attributeRuns;
- (SBElementArray<MacVimCharacter *> *) characters;
- (SBElementArray<MacVimParagraph *> *) paragraphs;
- (SBElementArray<MacVimWord *> *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into paragraphs.
@interface MacVimParagraph : MacVimItem

- (SBElementArray<MacVimAttachment *> *) attachments;
- (SBElementArray<MacVimAttributeRun *> *) attributeRuns;
- (SBElementArray<MacVimCharacter *> *) characters;
- (SBElementArray<MacVimParagraph *> *) paragraphs;
- (SBElementArray<MacVimWord *> *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Rich (styled) text
@interface MacVimText : MacVimItem

- (SBElementArray<MacVimAttachment *> *) attachments;
- (SBElementArray<MacVimAttributeRun *> *) attributeRuns;
- (SBElementArray<MacVimCharacter *> *) characters;
- (SBElementArray<MacVimParagraph *> *) paragraphs;
- (SBElementArray<MacVimWord *> *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Represents an inline text attachment.  This class is used mainly for make commands.
@interface MacVimAttachment : MacVimText

@property (copy) NSString *fileName;  // The path to the file for the attachment


@end

// This subdivides the text into words.
@interface MacVimWord : MacVimItem

- (SBElementArray<MacVimAttachment *> *) attachments;
- (SBElementArray<MacVimAttributeRun *> *) attributeRuns;
- (SBElementArray<MacVimCharacter *> *) characters;
- (SBElementArray<MacVimParagraph *> *) paragraphs;
- (SBElementArray<MacVimWord *> *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end



/*
 * Type Definitions
 */

@interface MacVimPrintSettings : SBObject <MacVimGenericMethods>

@property NSInteger copies;  // the number of copies of a document to be printed
@property BOOL collating;  // Should printed copies be collated?
@property NSInteger startingPage;  // the first page of the document to be printed
@property NSInteger endingPage;  // the last page of the document to be printed
@property NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (copy) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property MacVimEnum errorHandling;  // how errors are handled
@property (copy) NSString *faxNumber;  // for fax number
@property (copy) NSString *targetPrinter;  // for target printer


@end

