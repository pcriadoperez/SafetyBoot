class ArrowButton{
  int x,y;
  float rotation;
  int size=50;
  ArrowButton(int xTemp, int yTemp, float rotationTemp){
    x= xTemp;
    y = yTemp;
    rotation = rotationTemp;
  }
  void display(){
    pushMatrix();
    translate(x,y);
    fill(100);
    ellipse(0,0,size,size);
    rotate(rotation);
    stroke(20);
    triangle(-20,-5,20,-5,0,20);
    noStroke();
    popMatrix();
  }
}