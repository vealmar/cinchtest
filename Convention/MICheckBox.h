#import <UIKit/UIKit.h>


@interface MICheckBox : UIButton {
	BOOL isChecked;
}
@property (nonatomic,assign) BOOL isChecked;

-(IBAction) checkBoxClicked;

-(void) updateCheckBox:(BOOL)checked;

@end
