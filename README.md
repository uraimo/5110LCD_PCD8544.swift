# 5110LCD_PCD8544.swift

**A Swift library for the Nokia3310/5110 PCD8544 Monochrome LCD display**

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat" alt="Swift 2 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/5110lcd_pcd8544.swift/master/LICENSE"><img src="http://img.shields.io/badge/license-BSD-blue.svg?style=flat" alt="License: BSD" /></a>
<!--<a href="https://travis-ci.org/uraimo/5110lcd_pcd8544.swift"><img src="https://api.travis-ci.org/uraimo/5110lcd_pcd8544.swift.svg" alt="Travis CI"></a>-->
</p>

![LCD with Swift logo](https://raw.githubusercontent.com/uraimo/5110lcd_pcd8544.swift/master/lcd.jpg)


## Summary

This library is an extended Swift port of the original PCD8544 C++ library from Limor Fried/Ladyada(Adafruit Industries).
With this library you will be able to draw single pixels, display text(multiple fonts), monochrome images and transparent sprites on the Nokia 3110/5110 84x48 Monochrome LCD display.  
The library need 5 GPIOs output to drive the display, two of those will act as software SPI(you don't need an hardware SPI to use this library).
Use it in your projects and let us know how it goes!

## Supported Boards

Every board supported by [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO): Raspberries, BeagleBones, C.H.I.P., etc...
The example below will use a CHIP board but you can easily modify the example to use one the the other supported boards.
                     
## Installation

To use this library, you'll need a Linux ARM board with Swift 2.2.

Please refer to the [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO) readme for Swift installation instructions.

Once your board runs Swift, considering that at the moment the package manager is not available on ARM, you'll need to manually download the library and its dependencies: 

    wget https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SwiftyGPIO.swift https://raw.githubusercontent.com/uraimo/5110lcd_pcd8544.swift/master/Sources/5110lcd_pcd8544.swift https://raw.githubusercontent.com/uraimo/font.swift/master/Sources/font.swift     

Once downloaded, in the same directory create an additional file that will contain the code of your application (e.g. main.swift). 

When your code is ready, compile it with:

    swiftc SwiftyGPIO.swift 5110lcd_pcd8544.swift font.swift main.swift

The compiler will create a **main** executable.
As everything interacting with GPIOs via sysfs, if you are not already root, you will need to run that binary with `sudo ./main`.

## Usage

This example uses a C.H.I.P. board and its first 5 GPIOs connected as shown below, but you can easily change the board selected with `getGPIOsForBoard` (e.g. `.RaspberryPiPlus2Zero`) and select a differen set of GPIOs. 

![LCD diagram](https://raw.githubusercontent.com/uraimo/5110lcd_pcd8544.swift/master/lcddiagram.png)

(It's highly likely that the pinout of your lcd module will be different from what is shown above, check your datasheet)

So, the first thing we need to do is configure the 5 GPIOs using SwiftyGPIO:

```swift
let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
var sclk = gpios[.P0]!
var dnmosi = gpios[.P1]!
var dc = gpios[.P2]!
var sce = gpios[.P3]!
var rst = gpios[.P4]!
```

Next, let's create a virtual SPI to send data to the display:

```swift
var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk)
```

And create the display object we'll use to interact with the LCD:

```swift
var lcd = PCD8544(spi:spi,dc:dc,rst:rst,cs:sce)
```

That's it, you are all set, let's see what we can do on the display: 

### Setting individual pixels

```swift
lcd.setPixel(20,y:20,color:.BLACK)
lcd.setPixel(30,y:30,color:.BLACK)
lcd.setPixel(10,y:10,color:.WHITE)
lcd.display()
```
The `setPixel` function draw a single pixel at the given coordinates. `.WHITE` represents the transparent background, `.BLACK` and opaque pixel.
To update the display, always call `.display()` once you are done. 


### Clearing the display

```swift
lcd.clearDisplay()
```
To clean the display just call `.clearDisplay()`.


### Drawing an image

To draw an image, using a bitmap buffer (create more monochrome bitmap images [here](http://www.rinkydinkelectronics.com/t_imageconverter_mono.php)):

```swift
lcd.drawImage(swift_logo,x:0,y:0,width:LCDWIDTH,height:LCDHEIGHT)
lcd.display()
```

The `x` and `y` parameters specify the position inside the 84x48 grid while the last two parameters are respectively the width and height og the image. The buffer is a buffer of `UInt8`, with size equals to `width*height`, buffer with an invalid size will be ignored.

If no additional parameters are specified images are opaque, i.e. white pixels will cover what's behind them, but if you need to draw a trasparent image (e.g. game sprites) add the `transparent:true` parameter.
Here we are displaying the Swift logo in front of a series of horizontal lines:
                
```swift
let alllines=[UInt8](count:LCDHEIGHT*LCDWIDTH/8, repeatedValue:0xAA)
lcd.drawImage(alllines,x:0,y:0,width:LCDWIDTH,height:LCDHEIGHT)
lcd.drawImage(swift_logo,x:0,y:0,width:LCDWIDTH,height:LCDHEIGHT,transparent:true)
lcd.display()
```

### Text and Fonts

This library allows to display strings using bitmap fonts. Two fonts are included: Tiny_Font and SinclairS (more font can be found or generated [here](http://www.rinkydinkelectronics.com/resources.php)).
To display some text, you need to load a font first and that font will be used for all the following strings: 

```swift
lcd.loadFontAsDefault(SinclairS_Font,fontWidth:8,fontHeight:8)
```

To draw a string simply call `drawString` with a position:

```swift
lcd.drawString("HelloWorld",x:0,y:0)
lcd.display()
```

That covers what the library can do.

## Examples

Examples are available in the *Examples* directory.

