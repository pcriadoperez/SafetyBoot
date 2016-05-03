// Script for boots
// 'l' for left boot
// 'r' for Right boot

#include "SimbleeCOM.h"

void setup() {
   SimbleeCOM.begin();
}

void loop() {
  // put your main code here, to run repeatedly:

}

void SimbleeCOM_onReceive(unsigned int esn, const char *payload, int len, int rssi)
{
  printf("%d ", rssi);
  printf("0x%08x ", esn);
  for (int i = 0; i < len; i++){
    if(boot == 'r') analogWrite(i+1, payload[i]);
  }
  printf("\n");
}
