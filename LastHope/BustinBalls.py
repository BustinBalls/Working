'''
Runs live image update to zero in camera at the Peppers position
'''
import time
import matlab.engine
import pyzed.sl as sl
import scipy.io as sio

if __name__ == "__main__":
    #Starts matlab engine normally.        
    eng=matlab.engine.start_matlab()
    failSafe=5
    while True:#start the loop! 
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
        zed.set_camera_settings(sl.CAMERA_SETTINGS.CAMERA_SETTINGS_HUE, 0, False)
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
            eng.LiveUpdate(nargout=0)
            time.sleep(10)

        else:
            print(f'No Image Recieved, {failSafe}Remaining attempts to get IMG')
            failSafe=failSafe-1  
    zed.disable_streaming()
    zed.close()
           