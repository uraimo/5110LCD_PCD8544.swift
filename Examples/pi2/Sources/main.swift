#if arch(arm) && os(Linux)
    //import 5110lcd_pcd8544 //Uncomment this when using the package manager
    //import SwiftyGPIO  //Uncomment this when using the package manager
    import Glibc
#endif
 

//Use the pins on the left side of the header:
// 3V3,GPIO2,GPIO3,GPIO4,GND,GPIO17,GPIO27
//
//Connect them with the display pins:
// VCC,SCLK,DN/MOSI,D/C,GND,SCE,RST (LED to VCC if you want)
//
let gpios = SwiftyGPIO.getGPIOsForBoard(.RaspberryPiPlus2Zero)
var dc = gpios[.P4]!
var sce = gpios[.P17]!
var rst = gpios[.P27]!

let spis = SwiftyGPIO.getHardwareSPIsForBoard(.RaspberryPiPlus2Zero)
var spi = spis?[0]

// Alternative: using a virtual spi
//var sclk = gpios[.P2]!
//var dnmosi = gpios[.P3]!
//var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk)

var lcd = PCD8544(spi:spi!,dc:dc,rst:rst,cs:sce)

lcd.setPixel(20,y:20,color:.BLACK)
lcd.setPixel(30,y:30,color:.BLACK)
lcd.setPixel(10,y:10,color:.WHITE)
lcd.display()
usleep(2000*1000)
lcd.clearDisplay()


lcd.drawImage(swift_logo,x:0,y:0,width:LCDWIDTH,height:LCDHEIGHT)
lcd.display()
usleep(2000*1000)
lcd.clearDisplay()

                
let alllines=[UInt8](count:LCDHEIGHT*LCDWIDTH/8, repeatedValue:0xAA)
lcd.drawImage(alllines,x:0,y:0,width:LCDWIDTH,height:LCDHEIGHT)
lcd.drawImage(swift_logo,x:0,y:0,width:LCDWIDTH,height:LCDHEIGHT,transparent:true)
lcd.display()
usleep(2000*1000)
lcd.clearDisplay()

lcd.loadFontAsDefault(SinclairS_Font,fontWidth:8,fontHeight:8) // Less fancy Tiny_Font also available

lcd.drawString("HelloWorld",x:0,y:0)
lcd.display()
usleep(2000*1000)
lcd.clearDisplay()


let ch1 = " !\"#$%&'()\n*+,-./0123\n456789:;<=\n>?@ABCDEFG\nHIJKLMNOPQ\nRSTUVWXYZ\n"
let ch2 = "[\\]^_`abcd\nefghijklmn\nopqrstuvwx\nyz{|}~"
lcd.drawString(ch1,x:0,y:0)
lcd.display()
usleep(2000*1000)
lcd.clearDisplay()
lcd.drawString(ch2,x:0,y:0)
lcd.display()



