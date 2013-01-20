#import "MICheckBox.h"

@implementation MICheckBox
@synthesize isChecked;

-(id)initWithCoder:(NSCoder *)aDecoder {
	
	if (self = [super initWithCoder:aDecoder]) {
        // Initialization code
		
		//self.frame =frame;
		self.contentHorizontalAlignment  = UIControlContentHorizontalAlignmentLeft;
		
		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
		[self addTarget:self action:@selector(checkBoxClicked) forControlEvents:UIControlEventTouchUpInside];
	}
    return self;
	
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		
		//self.frame =frame;
		self.contentHorizontalAlignment  = UIControlContentHorizontalAlignmentLeft;

		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
		[self addTarget:self action:@selector(checkBoxClicked) forControlEvents:UIControlEventTouchUpInside];
	}
    return self;
}

-(IBAction) checkBoxClicked {
	if(self.isChecked ==NO){
		self.isChecked =YES;
		[self setImage:[UIImage imageNamed:@"checkbox_ticked.png"] forState:UIControlStateNormal];
		
	}else{
		self.isChecked =NO;
		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];

	}

}


-(void) updateCheckBox:(BOOL)checked {
	
	
	self.isChecked = checked;
	
	if (checked)  
		[self setImage:[UIImage imageNamed:@"checkbox_ticked.png"] forState:UIControlStateNormal];
	else
		[self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];

		
	
	
	
}
 



 

@end
