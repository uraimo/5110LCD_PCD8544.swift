#if arch(arm) && os(Linux)
    import SwiftyGPIO  //Comment this when not using the package manager
    import Glibc
#else
    import Darwin //Needed for TravisCI
#endif
 
public let LCDHEIGHT=48
public let LCDWIDTH=84

/// Class that represents the display being configured
public class PCD8544{
    var dc,rst,cs:GPIO
    var spi:SPIOutput
    var pcd8544_buffer=[UInt8](repeating:0x0,count:LCDHEIGHT*LCDWIDTH/8)
    var currentFont=[UInt8]()
    var currentFontWidth=0,currentFontHeight=0
 

    public init(spi:SPIOutput,dc:GPIO,rst:GPIO,cs:GPIO){
        self.spi=spi
        self.dc=dc
        self.rst=rst
        self.cs=cs    
        dc.direction = .OUT
        rst.direction = .OUT
        cs.direction = .OUT

        rst.value = 0
        usleep(UInt32(500*1000))
        rst.value = 1

        // get into the EXTENDED mode!
        command(PCD8544_FUNCTIONSET | PCD8544_EXTENDEDINSTRUCTION )

        // LCD bias select (4 is optimal?)
        command(PCD8544_SETBIAS | 0x4)

        // set VOP
        command( PCD8544_SETVOP | 0x32) // Experimentally determined, DONT'T change it

        // normal mode
        command(PCD8544_FUNCTIONSET)

        // Set display to Normal
        command(PCD8544_DISPLAYCONTROL | PCD8544_DISPLAYNORMAL)

        // set up a bounding box for screen updates
        updateBoundingBox(xmin:0, ymin:0, xmax:LCDWIDTH-1, ymax:LCDHEIGHT-1)
        display() //Cleanup
    }
    
    /// Set a single pixel to the internal graphic buffer, call `.display()` to update the screen
    public func setPixel(x:Int, y:Int, color:LCDColor) {
        guard ((x>0) && (x < LCDWIDTH) && (y>0) && (y < LCDHEIGHT)) else {
            return
        }

        // x is which column
 	    if (color == .BLACK){
		    pcd8544_buffer[x + (y/8)*LCDWIDTH] |= UInt8(truncatingBitPattern:0x1 << (y%8))
	    }else{                        
		    pcd8544_buffer[x + (y/8)*LCDWIDTH] &= UInt8(truncatingBitPattern:~(0x1 << (y%8)))
        }
        updateBoundingBox(xmin:x,ymin:y,xmax:x,ymax:y)
    }

    /// Get a single pixel from the internal graphic buffer
    public func getPixel(x:Int, y:Int)->UInt8 {
        guard ((x>0) && (x < LCDWIDTH) && (y>0) && (y < LCDHEIGHT)) else {
            return 0
        }

        return (pcd8544_buffer[x + (y/8)*LCDWIDTH] >> (UInt8(truncatingBitPattern:y)%8)) & 0x1
    } 

    /// Draw a monochrome bitmap image to the internal graphic buffer, call `.display()` to update the screen
    public func draw(image:[UInt8],x:Int,y:Int,width:Int,height:Int, transparent:Bool=false){

        for i in 0..<image.count {
            if transparent {
		        pcd8544_buffer[x + (y/8)*LCDWIDTH+i] |= image[i]
            }else{
		        pcd8544_buffer[x + (y/8)*LCDWIDTH+i] = image[i]
            }
 
        }
        updateBoundingBox(xmin:x, ymin:y, xmax:x+width, ymax:y+height)
    }          

    /// Load a bitmap font as default
    public func loadFontAsDefault(font:[UInt8], fontWidth:Int, fontHeight:Int){
        guard font.count == 95*fontWidth*fontHeight/8 else {
            return //TODO error
        }
        currentFontHeight = fontHeight
        currentFontWidth = fontWidth
        currentFont = font
    }

    /// Draw a string using the default font to the internal graphic buffer, call `.display()` to update the screen
    public func draw(text:String, x:Int, y:Int, transparent:Bool=false){
        var cursorX=x
        var cursorXMax=x
        var cursorY=y
        for scalar in text.unicodeScalars {
            cursorXMax = (cursorX>cursorXMax) ? cursorX : cursorXMax
            if scalar.value == 10 {
                cursorY += currentFontHeight // \n character
                cursorX = x 
                continue
            }
            drawChar(charCode:scalar.value, posX:cursorX, posY:cursorY, transparent:transparent)
            cursorX += currentFontWidth
        }        
        updateBoundingBox(xmin:x, ymin:y, xmax:cursorXMax, ymax:cursorY+currentFontHeight)
    }

    /// Get the next row position for a string using the default font and the given starting coordinates
    public func nextFontRow(x:Int, y:Int) ->(x:Int,y:Int){
        return (x,y+currentFontHeight)
    }

    /// Get the next column position for a string using the default font and the given starting coordinates
    public func nextFontColumn(x:Int, y:Int) ->(x:Int,y:Int){
        return (x+currentFontWidth,y)
    }

    ///	Updates the display with the latest modification from the internal buffer
    public func display(){
        var col,maxcol:Int
  
        for p in 0...5 {            
           //To reduce how much is refreshed, do a partial udpate, algorithm derived from 
           //Steve Evans/JCW's mod but cleaned up and optimized

            // check if this page is part of update
            if ( yUpdateMin >= ((p+1)*8) ) {
                continue   // nope, skip it!
            }
            if (yUpdateMax < p*8) {
                break
            }

            command(PCD8544_SETYADDR | UInt8(truncatingBitPattern:p))

            col = xUpdateMin
            maxcol = xUpdateMax

            command(PCD8544_SETXADDR | UInt8(truncatingBitPattern:col))

            dataStream(Array(pcd8544_buffer[(LCDWIDTH*p)+col...(LCDWIDTH*p)+maxcol]))
        }                           
       
        command(PCD8544_SETYADDR )  // no idea why this is necessary but it is to finish the last byte?

        xUpdateMin = LCDWIDTH - 1
        xUpdateMax = 0
        yUpdateMin = LCDHEIGHT-1
        yUpdateMax = 0
    } 
 

    /// Clear the display
    public func clearDisplay() {
        for i in 0..<pcd8544_buffer.count {
            pcd8544_buffer[i] = 0
        }
        updateBoundingBox(xmin:0, ymin:0, xmax:LCDWIDTH-1, ymax:LCDHEIGHT-1)
        display()
    } 

// MARK: Private functions

    /// Execute a command (dc=0)
    private func command(_ commandcode:UInt8){
        dc.value = 0
        spi.sendData([commandcode])
    }

    /// Send some data (dc=1)
    private func data(_ data:UInt8){
        dc.value = 1
        spi.sendData([data])
    }

    /// Send some data stream(dc=1)
    private func dataStream(_ data:[UInt8]){
        dc.value = 1
        spi.sendData(data)
    }

    /// Add a char to the internal buffer
    private func drawChar(charCode:UInt32, posX:Int, posY:Int, transparent:Bool){
        guard (charCode>31)&&(charCode<127) else {
            return //Unprintable character
        }
        guard (posX+currentFontWidth<=LCDWIDTH)&&(posY+currentFontHeight<=LCDHEIGHT) else {
            return //Character outside of screen borders
        } 

        //Load char font row by row
        //transpose to save column by column
        let charRef = (Int(charCode)-32)*currentFontWidth
        let charSprite = currentFont[charRef..<charRef+currentFontWidth]
        let tCharSprite = transpose(matrix: charSprite,width:currentFontWidth,height:currentFontHeight)

        for col in 0..<currentFontWidth {
            if transparent {
		        pcd8544_buffer[posX + col + (posY/8)*LCDWIDTH] |= tCharSprite[col]
            }else{
		        pcd8544_buffer[posX + col + (posY/8)*LCDWIDTH] = tCharSprite[col]
            }
        }
    }
    
    /// Transpose an array containing a matrix of pixels
    private func transpose(matrix:ArraySlice<UInt8>,width:Int,height:Int)->[UInt8]{
        var res = [UInt8](repeating:0,count:matrix.count)
        var row = 0
        for el in matrix {
            for i in 0..<width {
                res[width-1-i] |= ((el & (0x1 << UInt8(i)) == 0) ? 0 : 1) << UInt8(row)
            }  
            row += 1  
        }
        return res
    }
         
    private var xUpdateMin:Int=0, xUpdateMax:Int=0, yUpdateMin:Int=0, yUpdateMax:Int=0  
    
    /// Update coordinates of the modified area
    private func updateBoundingBox(xmin:Int, ymin:Int, xmax:Int, ymax:Int) {
        xUpdateMin = (xmin>=0)&&(xmin<LCDWIDTH)&&(xmin < xUpdateMin) ? xmin : xUpdateMin
        xUpdateMax = (xmax>=0)&&(xmax<LCDWIDTH)&&(xmax > xUpdateMax) ? xmax : xUpdateMax
        xUpdateMax = (xmax>=LCDWIDTH) ? LCDWIDTH-1 : xUpdateMax
        yUpdateMin = (ymin>=0)&&(ymin<LCDHEIGHT)&&(ymin < yUpdateMin) ? ymin : yUpdateMin
        yUpdateMax = (ymax>=0)&&(ymax<LCDHEIGHT)&&(ymax > yUpdateMax) ? ymax : yUpdateMax
        yUpdateMax = (ymax>=LCDHEIGHT) ? LCDHEIGHT-1 : yUpdateMax
    }
  
}

/// Pixel color, .BLACK is opaque, .WHITE is transparent
public enum LCDColor:UInt8{
    case WHITE = 0
    case BLACK = 1
}
 
//Internal Constants

internal let PCD8544_POWERDOWN:UInt8=0x04
internal let PCD8544_ENTRYMODE:UInt8=0x02
internal let PCD8544_EXTENDEDINSTRUCTION:UInt8=0x01

internal let PCD8544_DISPLAYBLANK:UInt8=0x0
internal let PCD8544_DISPLAYNORMAL:UInt8=0x4
internal let PCD8544_DISPLAYALLON:UInt8=0x1
internal let PCD8544_DISPLAYINVERTED:UInt8=0x5

// H = 0
internal let PCD8544_FUNCTIONSET:UInt8=0x20
internal let PCD8544_DISPLAYCONTROL:UInt8=0x08
internal let PCD8544_SETYADDR:UInt8=0x40
internal let PCD8544_SETXADDR:UInt8=0x80
// H = 1
internal let PCD8544_SETTEMP:UInt8=0x04
internal let PCD8544_SETBIAS:UInt8=0x10
internal let PCD8544_SETVOP:UInt8=0x80


