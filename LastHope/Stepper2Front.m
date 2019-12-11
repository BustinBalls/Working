function Stepper2Front()
clear arduinoUno
%ESTOP WILL BE ADDED to cut all motor power set to pin 2 as NO set LOW
%{
try
    readDigitalPin(arduinoUno,'D2');
catch
    arduinoUno = arduino('COM8','uno');
end
%}
arduinoUno = arduino('COM8','uno');
atHome=readDigitalPin(arduinoUno,'D2');
while atHome==1
    %reads until limit switch is Low, used on a normally open switch with a internal Pullup Resistor
    writeDigitalPin(arduinoUno,'D4',1);
    writePWMDutyCycle(arduinoUno,'D3',0.7);
    atHome=readDigitalPin(arduinoUno,'D2');
end
writeDigitalPin(arduinoUno,'D3',0);
clear arduinoUno
end
