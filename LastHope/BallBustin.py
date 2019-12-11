'''
Will be used if photo is already got and to show communication to matlab and python

'''



import time
import os
import matlab.engine
import scipy.io as sio



if __name__ == "__main__":
    #Starts matlab engine normally.        
    eng=matlab.engine.start_matlab()
    eng.OpenMatLabProject(nargout=0)
    while True:#start the loop! 
        eng.Stepper2Front(nargout=0)  

        XYZOATstring=eng.EndAllBeAll(nargout=1)

    eng.CloseMatLabProject()
           
       
     