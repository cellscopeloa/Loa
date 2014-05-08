//
//  BluetoothStage.h
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 5/8/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"


@interface BluetoothStage : UIViewController <BLEDelegate> {
}


@property (strong, nonatomic) BLE *ble;

-(void) connectBLE;
-(void) servoReturn;
-(void) servoAdvance;
-(void) servoConfigure:(int) fields;





@end
