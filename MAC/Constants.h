#define degreesToRadian(x) (3.14159265358979323846 * x / 180.0)

#define getDocumentPath() ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0])

#define kSelectedTabKey @"kSelectedTabKey"

#define kPointSizeKeyFormat @"kPointSizeKeyFormat%d"

#define kOpacityKeyFormat @"kOpacityKeyFormat%d"

#define kToolKeyFormat @"kToolKeyFormat%d"

#define kColorKeyFormat @"kColorKeyFormat%d"

#define kColorCoordinateKeyFormat @"kColorCoordinateKeyFormat%d"


#define kBrushTool 0
#define kSprayTool 1
#define kTextTool 2
