# AVPlayerOverlay

AVPlayer with custom controls, full screen mode, subtitles (.srt) and AirPlay features.

**HOW TO USE :**

* Put a Container View on your ViewController.

![image](https://github.com/priore/AVPlayerOverlay/blob/master/images/step1.jpg)

* Remove the ViewController that created automatically.

![image](https://github.com/priore/AVPlayerOverlay/blob/master/images/step2.jpg)

* Add a AVPlayerViewController.

* Connect the AVPlayerViewController to the Container View, embedded mode.

* Sets the AVPlayerViewController class to the AVPlayerVC custom class.

![image](https://github.com/priore/AVPlayerOverlay/blob/master/images/step3.jpg)

* Add a new ViewController.

* Set the ViewController class to the AVPlayerOverlayVC custom class.

* Set the storyboard identity to AVPlayerOverlayVC

![image](https://github.com/priore/AVPlayerOverlay/blob/master/images/step4.jpg)

* Put a View and Buttons and Slider inside this views for customize your controllers.

* Put a Slider for volume control outside this last view, near volume button control.

* Connect all controls interface of the viewcontroller.

![image](https://github.com/priore/AVPlayerOverlay/blob/master/images/step5.jpg)

* Set the constraints of the controls, and center the volume slider to the volume button.<br> 
_note: the volume slider is automatically rotated._

![image](https://github.com/priore/AVPlayerOverlay/blob/master/images/step6.jpg)

* In your ViewController where is the Container View, put the code below.

```objective-c

#import "AVPlayerVC.h"

@interface ViewController ()

@property (nonatomic, weak) AVPlayerVC *playerVC;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playerVC.videoURL = [NSURL URLWithString:@"http://your-video-url"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AVPlayerVC class]])
        self.playerVC = segue.destinationViewController;
}

@end

```


**that's all !!**
