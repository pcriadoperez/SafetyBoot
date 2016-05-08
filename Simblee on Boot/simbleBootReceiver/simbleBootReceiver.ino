/*
 * Copyright (c) 2015 RF Digital Corp. All Rights Reserved.
 *
 * The source code contained in this file and all intellectual property embodied in
 * or covering the source code is the property of RF Digital Corp. or its licensors.
 * Your right to use this source code and intellectual property is non-transferable,
 * non-sub licensable, revocable, and subject to terms and conditions of the
 * SIMBLEE SOFTWARE LICENSE AGREEMENT.
 * http://www.simblee.com/licenses/SimbleeSoftwareLicenseAgreement.txt
 *
 * THE SOURCE CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
 *
 * This heading must NOT be removed from this file.
 */

#include "SimbleeCOM.h"

void setup() {
  Serial.begin(9600);
  
  SimbleeCOM.begin();
}

void loop() {
  
}

void SimbleeCOM_onReceive(unsigned int esn, const char *payload, int len, int rssi)
{
  for (int i = 1; i < len; i++){
    Serial.println(int(payload[i]));
    if(int(payload[0])==0 && i>0){ // payload[0]==0 for left and payload[0]==1 for Right
      analogWrite(i+1, int(payload[i]));
    }
  }
  Serial.println("end message");
}
