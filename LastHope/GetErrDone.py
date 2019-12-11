'''
Runs the entire Program
'''

from telnetlib import IAC, DO, WILL, SB, SE, TTYPE, ECHO, DONT, WONT, NAOFFD
import telnetlib
import socket
import time
import threading
import os
import matlab.engine
import pyzed.sl as sl
import scipy.io as sio
   
    
class Kawasaki:
    """
	Python interface to  connect, initite, and control progrmas for Kawasaki
    Robotics. File X6 was originally recieved form James Hudak, Mechatronics 
    Lab assitant for Kennesaw State University, if number folling the 'x' 
    changes it simply reflects modified version.
    
    *TCP port 23 uses the Transmission Control Protocol. TCP is one of the main
    protocols in TCP/IP networks. Whereas the IP protocol deals only with 
    packets, TCP enables two hosts to establish a connection and exchange 
    streams of data. TCP guarantees delivery of data and also guarantees that 
    packets will be delivered on port 23 in the same order in which they were 
    sent. Guaranteed communication over port 23 is the key difference between 
    TCP and UDP. UDP port 23 would not have guaranteed communication in the 
    same way as TCP.  
	"""
    def __init__(self, hostIp='192.168.1.30', port=23):                         # Defines a local IP address connecting to Robot, Port is set to 23 as it is the TCP/IP communications on PC, was recommended to use 10300?
        self.BUFFER_SIZE = 512                                                 # bytes                                                     # seconds # No robot movement should take more than 60 seconds
        self.sock = None
        self.sockjnts = None
        self.hostIp = hostIp                                                   #
        self.port = port
        self.env_term = 'VT100'
        self.user = "as" 
        self.telnet = telnetlib.Telnet()
        #calls function Connect
        self.Connect()
        
    def TelnetProcessOptions(self, socket, cmd, opt):				
        IS = b'\00'
        if cmd == WILL and opt == ECHO:                                        # hex:ff fb 01 name:IAC WILL ECHO description:(I will echo)
            socket.sendall(IAC + DO + opt)                                     # hex(ff fd 01), name(IAC DO ECHO), descr(please use echo)
        elif cmd == DO and opt == TTYPE:                                       # hex(ff fd 18), name(IAC DO TTYPE), descr(please send environment type)		
            socket.sendall(IAC + WILL + TTYPE)                                 # hex(ff fb 18), name(IAC WILL TTYPE), descr(Dont worry, i'll send environment type)
        elif cmd == SB:
            socket.sendall(IAC + SB + TTYPE + IS + self.env_term.encode() + IS + IAC + SE)
            # hex(ff fa 18 00 b"VT100" 00 ff f0) name(IAC SB TTYPE iS VT100 IS IAC SE) descr(Start subnegotiation, environment type is VT100, end negotation)
        elif cmd == SE:                                                        # server letting us know sub negotiation has ended
            pass                                                               # do nothing
        else: print('Unexpected telnet negotiation')
    
    def Connect(self):
        print(f'>Connecting to robot, IPv4:{self.hostIp}, port:{self.port}')
        self.telnet.set_option_negotiation_callback(self.TelnetProcessOptions)
        self.telnet.open(self.hostIp, self.port)
        time.sleep(0.5) #Allow TELNET negotaion to finish
        self.telnet.read_until(b"n: ") 
        self.telnet.write(self.user.encode() + b"\r\n")
        self.telnet.read_until(b">")
        print('>Connected succesfully\n')
        
    def Disconnect(self):
        self.telnet.close()      
    
    #Stopped working around time of install of Sensor on robot by James, He was
    #not a fan of how this called into robot 
    def LoadAsFile(self, file_location='master.as'):
        max_chars = 492                                                        # Max amount of characters that can be accepted per write to kawa.
        if file_location != None:
            print('>Transfering {} to kawasaki'.format(file_location))
            inputfile = open(file_location, 'r')
            file_text = inputfile.read()                                       # Store Kawasaki-as code from file in local varianle
            text_split = [file_text[i:i+max_chars] for i in range(0, len(file_text), max_chars)] # Split AS code in sendable blocks
            print(f'>File consists of {len(file_text)} characters')
            self.telnet.write(b"load master.as\r\n")##########################
            self.telnet.read_until(b".as").decode("ascii")
            self.telnet.write(b"\x02A    0\x17")
            self.telnet.read_until(b"\x17")
            print('>Sending file.... maybe....')
            for i in range(0, len(text_split), 1):
                self.telnet.write(b"\x02C    0" + text_split[i].encode() + b"\x17")
                self.telnet.read_until(b"\x17")
                print('>Loaded {} of {}'.format(i+1,len(text_split)))
            self.telnet.write(b"\x02" + b"C    0" + b"\x1a\x17")
            self.telnet.write(b"\r\n")
            self.telnet.read_until(b"E\x17")
            self.telnet.write(b"\x02" + b"E    0" + b"\x17")
            #Read until command prompt and continue
            self.telnet.read_until(b">")
            print(".... Done, great success!\n        -Borat\n")
        else: print('No file specified\n')                                     #Lastknown check, was built and sent to robot#still True [yes] [no]

    def AbortKillAll(self):
        #I call at every run to make sure there arent lingering programs running
        for command in ["pcabort "]:
            for i in range(1, 6):
                prog_number = str(i) + ":"     
                self.telnet.write(command.encode() + prog_number.encode() + b"\r\n")
                self.telnet.read_until(b">")
        for command in ["abort ", "pckill\r\n1", "kill\r\n1"]:
            self.telnet.write(command.encode() + b"\r\n")
            self.telnet.read_until(b">")
    
    def InitiateProgram(self,progName='master',promptAs=None,strCmd=None):
        #IF program is on robot will execute and pass a str of vars if specified
        #if there is a prompt in .as file, name is as a string here
        #will throw error if motor power is not on
        self.MotorOn()
        #initiates .as program on robot, if no extension Kawasaki assumes .as  need to spesify if .pg
        command=b'exe ' + progName.encode() + b'\r\n'
        print(command)
        #chose to do if before telnet write incase prompt was initiated quick
        if promptAs==None:
            self.telnet.write(command)
        else:
            self.telnet.write(command)
            #Reads until Prompt comes in program
            #self.telnet.read_until(promptAs.encode()).decode('ascii'))
            #for autononomous use str, else can use user input for prompt
            command=strCmd.encode() + b'\r\n'
            self.telnet.write(command)
            
        self.telnet.read_until(b'>Program completed.No = 1').decode('ascii')
        self.AsCmd('esc')

    def MotorOn(self):  
        command = b"zpow on\r\n"
        self.telnet.write(command)
        self.telnet.read_until(b">")
        
    def MotorOff(self):
        command = b"zpow off\r\n"
        self.telnet.write(command)
        self.telnet.read_until(b">")
    
    def ResetError(self):                  
        command = b'ereset\r\n'
        self.telnet.write(command)
        self.telnet.read_until(b">").decode("ascii")#####WHY?

    def AsCmd(self,command=None):
        command=command.encode() + b'\r\n'
        self.telnet.write(command)
        self.telnet.read_until(b'>')    
                
    def ClampExtend(self):
        self.MotorOn()
        command=b'exe Klampe\r\n' #Runs pg goat
        self.telnet.write(command)
        self.telnet.read_until(b'>Program completed.No = 1',timeout=10).decode('ascii')
        self.AsCmd('esc')
        
    def ClampRetract(self):
        self.MotorOn()
        command=b'exe Klampr\r\n' #Runs pg goat
        self.telnet.write(command)
        self.telnet.read_until(b'>Program completed.No = 1',timeout=10).decode('ascii')
        self.AsCmd('esc')
        
    def Robot2Shot(self,strCmd='0 0 0 0 0 0'):
        self.MotorOn()
        command=b'exe redhot\r\n' #Runs pg goat
        self.telnet.write(command)
        self.telnet.read_until(b'xyzoats').decode('ascii')
        command=strCmd.encode() + b"\r\n"
        self.telnet.write(command)
        self.telnet.read_until(b'>Program completed.No = 1',timeout=10).decode('ascii')
        #self.telnet.read_until(b'(E1128) Uncoincidence error betw destination and current jt 6 pos.',timeout=10).decode('ascii')
        time.sleep(3)
        self.ResetError()
        self.AsCmd('esc')

    def Shot2Home(self,imgcorrect='0 0 0 0 0 0 0'):
        self.MotorOn()
        self.ResetError()
        command=b'exe peppers\r\n' #Runs pg goat
        self.telnet.write(command)
        self.telnet.read_until(b'xyzoats').decode('ascii')
        command=imgcorrect.encode() + b"\r\n"
        self.telnet.write(command)
        self.telnet.read_until(b'>Program completed.No = 1',timeout=10).decode('ascii')
        #self.telnet.read_until(b'(E1128) Uncoincidence error betw destination and current jt 6 pos.',timeout=10).decode('ascii')
        time.sleep(3)
        self.ResetError()
        self.AsCmd('esc')

        

if __name__ == "__main__":
    #Starts matlab engine normally.        
    eng=matlab.engine.start_matlab()
    eng.OpenMatLabProject(nargout=0)
    FS30L = Kawasaki() 
    time.sleep(5)
    FS30L.ResetError()
    FS30L.AbortKillAll()
    FS30L.MotorOff()

    FS30L.ClampRetract()
    #Executes program Peppers, the 3rd robot move
    FS30L.Shot2Home('0')
    failSafe=5
    while failSafe!=0:#start the loop! 
        #calls Klampr to retract clamp so ball screw can return home
        FS30L.ClampRetract()
        #stepper home Can run this on pi while PC finds img
        #'send 2 X Y Z O A Ts for per 
        eng.Stepper2Front(nargout=0)  
        #calls clamp after stpper gets home to enable cocking
        FS30L.ClampExtend()
        #############START GET IMG######################
        # Set the input from stream
        init = sl.InitParameters()
        # Specify the IP and port of the sender 
        init.set_from_stream("192.168.1.7", 30000) 
        #cameras resolution 1242x2208x4 RGBalpha
        init.camera_resolution = sl.RESOLUTION.RESOLUTION_HD2K
        #depthmode for 3D space calcs
        init.depth_mode = sl.DEPTH_MODE.DEPTH_MODE_PERFORMANCE
        #sets zeds units to mm
        init.coordinate_units=sl.UNIT.UNIT_MILLIMETER
        #cause our camera is mounted upside down
        init.camera_image_flip=True
        zed = sl.Camera()
        #cam.find_floor_plane(sl.Plane)
        zed.open(init)
        #Set variables for clearer image, if false it takes user input if true uses ZEDSDK default
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_HUE,0 , False)
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_BRIGHTNESS, 4, False)
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_GAIN, -1, True)
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_WHITEBALANCE, 3000, False)
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_EXPOSURE, -1, True)
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_CONTRAST, 3, False)
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_SATURATION, 4, False)  
        runtime = sl.RuntimeParameters()
        mat = sl.Mat()
        err = zed.grab(runtime)
        if (err == sl.ERROR_CODE.SUCCESS) :
            failSafe=5
            print('connected')
            #Gets image from left camera
            zed.retrieve_image(mat, sl.VIEW.VIEW_LEFT)
            #resizes to get rid of BS alpha parameter
            leftImgArray=mat.get_data()[:,:,0:3]
            #saves as matlab variable
            sio.savemat('imgLeft.mat', dict(leftImgArray=leftImgArray))
            #Same Shit but now for right camera
            zed.retrieve_image(mat, sl.VIEW.VIEW_RIGHT)
            rightImgArray=mat.get_data()[:,:,0:3]
            sio.savemat('imgRight.mat', dict(rightImgArray=rightImgArray))                        
            #calcs shot returns XYZOATs
            strXYZOATs=eng.EndAllBeAll(nargout=1)
            print(strXYZOATs)
                                
            ##Calls redhot.as with prompt of xyzoats 
            FS30L.Robot2Shot(strXYZOATs)                      
            time.sleep(2)
            FS30L.ClampRetract()#shoots
            FS30L.Shot2Home('0') #Home move to take photo
        else:
            print(f'No Image Recieved, {failSafe}Remaining attempts to get IMG')
            failSafe=failSafe-1        
        #closes stream and camera and ends loop if 5 consecutive attempts to get img fails    
    zed.disable_streaming()
    zed.close()
    #eng.CloseMatLabProject()
           