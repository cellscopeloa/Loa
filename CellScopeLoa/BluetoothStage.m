//
//  BluetoothStage.m
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 5/8/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "BluetoothStage.h"

@interface BluetoothStage () {
    int connected;
    int currentPos;
    int totalFields;
}

@end

@implementation BluetoothStage
@synthesize ble;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)init {
    
    self = [super init];
    connected=0;
    currentPos=0;
    totalFields=0;
    ble = [[BLE alloc] init];
    [ble controlSetup];
    ble.delegate = self;
    
    return self;
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void) connectBLE {
    [NSTimer scheduledTimerWithTimeInterval:(float)3 target:self selector:@selector(connectBLETimer:) userInfo:nil repeats:YES];
}

-(void) connectBLETimer:(NSTimer *)timer {
    NSLog(@"connectBLETimer fired");
    if (connected==1) [timer invalidate];
    else [self scanForPeripherals];
}

-(void) servoReturn
{
    UInt8 buf[3] = {0x03, 0x00, 0x00};
    buf[1]= 190;
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
    currentPos=190;
}

-(void) servoConfigure:(int) fields {
    totalFields=fields;
}

-(void) servoAdvance
{
    UInt8 buf[3] = {0x03, 0x00, 0x00};
    currentPos=currentPos-90/totalFields;
    buf[1]= currentPos;
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];
}

- (void)scanForPeripherals
{
    if (ble.activePeripheral)
        if(ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
            return;
        }
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [ble findBLEPeripherals:2];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
}

-(void) connectionTimer:(NSTimer *)timer
{
    
    if (ble.peripherals.count > 0)
    {
        int i=0;
        while (i<ble.peripherals.count){
            NSLog(@"detected UUIDs: %@",[ble.peripherals objectAtIndex:i]);
            CBPeripheral *p = [ble.peripherals objectAtIndex:i];
            //for ipad mini not retina
            //NSString *corrUUID=@"8D9B9237-FA57-6052-C06E-F356562D8844";
            //for frankies ipad mini retina
            //NSString *corrUUID=@"94163A3B-8A39-BA5D-8F96-CC9588C86E12";
            
            //for Arunan's ipad
            //NSString *corrUUID=@"A4E91189-D450-312B-B0BB-0EC8726A4E34";
            
            //for mikes ipad mini retina
            NSString *corrUUID=@"D33AE2D6-EFEC-0D4C-245F-B2F884BD7E6C";
            
            NSLog(@"UUID is %@",p.identifier.UUIDString);
            NSLog(@"corrUUID is %@",corrUUID);
            if ([p.identifier.UUIDString isEqualToString: corrUUID]){
                
                [ble connectPeripheral:[ble.peripherals objectAtIndex:i]];
            }
            i=i+1;
        }
    }
    else
    {
    }
}
#pragma mark - BLE delegate

NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");
    [rssiTimer invalidate];
    connected=0;
    [NSTimer scheduledTimerWithTimeInterval:(float)5 target:self selector:@selector(connectBLETimer:) userInfo:nil repeats:YES];
}


// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    //lblRSSI.text = rssi.stringValue;
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [ble readRSSI];
}

// When disconnected, this will be called
-(void) bleDidConnect
{
    NSLog(@"->Connected");
    
    connected=1;
}




// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"Length: %d", length);
    
    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);
        
        if (data[i] == 0x0A)
        {
            //if (data[i+1] == 0x01)
            //swDigitalIn.on = true;
            //else
            //swDigitalIn.on = false;
        }
        else if (data[i] == 0x0B)
        {
            UInt16 Value;
            
            Value = data[i+2] | data[i+1] << 8;
            //lblAnalogIn.text = [NSString stringWithFormat:@"%d", Value];
        }
    }
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


@end