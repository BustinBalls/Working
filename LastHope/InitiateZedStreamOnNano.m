function [ID]=InitiateZedStreamOnNano()

nano=jetson('192.168.1.7','law','P');
ID=runExecutable(nano,'/home/law/Desktop/sender/build/ZED_Streaming_Sender');
