function LiveUpdate()
%%
clear all
close all

%Get IMG and undistort
load imgLeft leftImgArray
load imgRight rightImgArray
load ZedCallibrated stereoParams
zed.left.OG=leftImgArray;
zed.left.undistorted.BGR = undistortImage(zed.left.OG,stereoParams.CameraParameters1);
zed.left.undistorted.RGB=BGR2RGB(zed.left.undistorted.BGR);
zed.left.undistorted.GREY=rgb2gray(zed.left.undistorted.BGR);


zed.right.OG=rightImgArray;
zed.right.undistorted.BGR = undistortImage(zed.right.OG,stereoParams.CameraParameters2);
zed.right.undistorted.RGB=BGR2RGB(zed.right.undistorted.BGR);
zed.right.undistorted.GREY=rgb2gray(zed.right.undistorted.BGR);
figure
subplot(2,1,1)
imshow(zed.left.OG)
subplot(2,1,2)
imshow(zed.right.OG)
end

%%
%%
function [fixedImage]=BGR2RGB(imageArray)
placeholder(:,:,1)=imageArray(:,:,3);
imageArray(:,:,3)=imageArray(:,:,1);
imageArray(:,:,1)=placeholder(:,:,1);
fixedImage=imageArray;
end
