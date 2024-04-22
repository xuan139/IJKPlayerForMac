// MyTableViewCell.m

#import "MyTableViewCell.h"

@implementation MyTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
              
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 8, 32, 32)];
        UIImage *iconImage = [UIImage imageNamed:@"icon.png"];
        self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconImageView.image = iconImage;
        [self.contentView addSubview:self.iconImageView];

        self.customImageView = [[UIImageView alloc] initWithFrame:CGRectMake(48, 96, 200, 160)];
        self.customImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.customImageView];

        
    }
    return self;
}

@end

