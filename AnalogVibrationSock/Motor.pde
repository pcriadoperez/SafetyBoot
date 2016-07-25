class Motor{
  float x,y;
  int fill=200;
  float size;
  int power=0;
  double squareTimeChange=0;
  
  Motor(int xTemp, int yTemp, int tempSize){
    x=xTemp;
    y=yTemp;
    size=tempSize;
  }
  
  void display(){
    int vibration;
    if(power>0){
      vibration = (int)random(size*0.10);
      fill(0, power, 0);
    }
    else{
      vibration = 0;
      fill(100,100,100);
    }
    ellipse(x + vibration,y +vibration,size,size);
  }

}