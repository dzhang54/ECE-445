char buf[4];
int count;

void setup() {
  pinMode(9,OUTPUT);
  pinMode(11, OUTPUT);
  Serial.begin(115200);    //start serial communication @9600 bps
  digitalWrite(11, HIGH);
}

void loop(){
  if(Serial.available()){  //if data is available to read
    int val = Serial.readBytes(buf,4);
    if(val > 0){
      Serial.println(buf);
    }
    Serial.println(buf[0]);
    
    if(String(buf[0]).equals("r")){
      digitalWrite(11, HIGH);
      for(int j = 0; j < sizeof(buf)/sizeof(buf[0]); j++){
        buf[j] = 0;
      }
      return;
    }else if(String(buf[0]).equals("l")){
      digitalWrite(11, LOW);
      for(int j = 0; j < sizeof(buf)/sizeof(buf[0]); j++){
        buf[j] = 0;
      }
      return;
    }
    int rotation = (buf[0]-'0') * 1000 + (buf[1]-'0')* 100 + (buf[2]-'0')* 10 + (buf[3]-'0');
    if(val != 0){
    for(int i = 0; i < rotation; i++){/*
      if(i < 10){
        digitalWrite(9, HIGH);
        delay(10);
        digitalWrite(9, LOW);
        delay(10);
        
      }else{
      digitalWrite(9, HIGH);
      delay(3);
      digitalWrite(9, LOW);
      delay(3);
      }*/
      digitalWrite(9, HIGH);
      delay(3);
      digitalWrite(9, LOW);
      delay(3);
    }
    }
    
    
  }
  for(int j = 0; j < sizeof(buf)/sizeof(buf[0]); j++){
    buf[j] = 0;
  }
}
