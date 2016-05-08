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
boolean update = false;
char payload[] = {0,250,250,250,128,0,0};
void setup() {
  Serial.begin(9600);
  SimbleeCOM.begin();
}

void loop() {
 if(Serial.available()){
  //Serial.readBytes(payload, sizeof(payload));
  //for(int i =0; i<sizeof(payload); i++) payload[i] = Serial.read();
  Serial.readBytesUntil(-128,payload, 10);
  update = true;
 }
 if(update){
 SimbleeCOM.send(payload, sizeof(payload));
 Serial.write(payload);
 update = false;
 }
}
