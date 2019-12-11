function [robotSend]=EndAllBeAll()
%%
clear all
close all
global Shots pocket color ballRad xCrop yCrop stereoParams zed bumper_w Ball Shot Balls 
%both measured with calliper
bumper_w=68;
ballRad=56.8/2;
%color matrix
color = {[0 0 0];[1 0 0];[0.4660 0.6740 0.1880];[0 0 1];[0.8500 0.3250 0.0980];[1 0 1]};
%%
%Get IMG and undistort and apply filters
load imgLeft leftImgArray
load imgRight rightImgArray
load ZedCallibrated stereoParams
zed.left.OG=leftImgArray;
zed.left.undistorted.BGR = undistortImage(zed.left.OG,stereoParams.CameraParameters1);
zed.left.undistorted.RGB=BGR2RGB(zed.left.undistorted.BGR);
zed.left.undistorted.GREY=rgb2gray(zed.left.undistorted.BGR);
zed.left.undistorted.Drawer=(zed.left.undistorted.RGB);

zed.right.OG=rightImgArray;
zed.right.undistorted.BGR = undistortImage(zed.right.OG,stereoParams.CameraParameters2);
zed.right.undistorted.RGB=BGR2RGB(zed.right.undistorted.BGR);
zed.right.undistorted.GREY=rgb2gray(zed.right.undistorted.BGR);
zed.right.undistorted.Drawer=(zed.right.undistorted.RGB);


%kern = [1 2 1; 0 0 0; -1 -2 -1];

% Capture the image from the webcam on hardware.
%{
img=zed.right.undistorted.RGB;

% Finding horizontal and vertical gradients.
h = conv2(img(:,:,2),kern,'same');
v = conv2(img(:,:,2),kern','same');

% Finding magnitude of the gradients.
e = sqrt(h.*h + v.*v);

% Threshold the edges
edgeImg = uint8((e > 100) * 240);
figure
% Display image.
imshow(edgeImg);
[cDot, r] = imfindcircles(BGR,[5 10],'Sensitivity', 0.9, 'EdgeThreshold', 0.4);
viscircles(cDot, r,'Color','r')

figure
[cDot, r] = imfindcircles(edgeImg,[5 10],'Sensitivity', 0.80, 'Method','twostage','EdgeThreshold', .65);
[cBall, r] = imfindcircles(BGR,[27 32],'Sensitivity', 0.9, 'EdgeThreshold', 0.4);
viscircles(cBall, r,'Color','r')
%}
%%
%trys to sum both left and right then just Left then just right
try
    %%
    
    for k=1:2
        if k==1
            RGB=zed.right.undistorted.RGB;
            BGR=zed.right.undistorted.BGR;
        else
            RGB=zed.left.undistorted.RGB;
            BGR=zed.left.undistorted.BGR;
        end
        %dot Diameter =16max
        Left=[];
        Right=[];
        Top=[];
        Bot=[];
        %figure; imshow(RGB);
        %axis on;
        %title('Undistorted');
        while ((isempty(Left) | isempty(Right) | isempty(Top) | isempty(Bot))==1)==1
            Left=[];
            Right=[];
            Top=[];
            Bot=[];
            [cDot, r] = imfindcircles(BGR,[5 10],'Sensitivity', 0.9, 'EdgeThreshold', 0.4);
            %viscircles(cDot, r,'Color','r');
            rNew=[];
            cDotNew=[];
            for i=1:length(cDot)
                if r(i)<8.5 && r(i)>6.3
                    rNew=[rNew;r(i)];
                    cDotNew=[cDotNew; cDot(i,:)];
                end
            end
            cDot=cDotNew;
            r=rNew;
            rNew=[];
            cDotNew=[];
            %viscircles(cDot, r,'Color','y');
            for i=1:length(cDot)
                if cDot(i,1) <= 300
                    Left=[Left;cDot(i,:)];
                    rNew=[rNew;r(i)];
                    cDotNew=[cDotNew; cDot(i,:)];
                elseif cDot(i,1) > 300 && cDot(i,1) <=1900
                    if cDot(i,2)<= 300
                        Top=[Top;cDot(i,:)];
                        rNew=[rNew;r(i)];
                        cDotNew=[cDotNew; cDot(i,:)];
                    elseif cDot(i,2)>= 1050
                        Bot=[Bot;cDot(i,:)];
                        rNew=[rNew;r(i)];
                        cDotNew=[cDotNew; cDot(i,:)];
                    end
                elseif cDot(i,1) >= 1900
                    Right=[Right;cDot(i,:)];
                    rNew=[rNew;r(i)];
                    cDotNew=[cDotNew; cDot(i,:)];
                else
                end
            end
        end
        cDot=cDotNew;
        r=rNew;
        %viscircles(cDot, r,'Color','g');
        Top=sum(Top(:,2))/length(Top(:,2));
        Bot=sum(Bot(:,2))/length(Bot(:,2));
        Right=sum(Right(:,1))/length(Right(:,1));
        Left=sum(Left(:,1))/length(Left(:,1));
        CroppedTable=[Left Top Right-Left Bot-Top];
        RGB=imcrop(RGB,CroppedTable);
        BGR=imcrop(BGR,CroppedTable);
        RGB=imresize(RGB, [980 1811]);
        BGR=imresize(BGR, [980 1811]);
        figure
        imshow(RGB);
        axis on;
        
        [yCrop,xCrop]=size(rgb2gray(BGR));
        pocket =    [ballRad+bumper_w ballRad+bumper_w;(xCrop)/2 bumper_w;xCrop-ballRad-bumper_w ballRad+bumper_w;xCrop-ballRad-bumper_w yCrop-ballRad-bumper_w;(xCrop)/2 yCrop-bumper_w;ballRad+bumper_w yCrop-ballRad-bumper_w];
        for i=1:6
            viscircles(pocket(i,:), ballRad/2, 'Color', color{i}, 'LineStyle', '-.');
        end
        %%
        [cBall,r] = imfindcircles(RGB,[25 35],'Sensitivity', .9, 'EdgeThreshold', .2);
        viscircles(cBall, r,'Color','b');
        [imgY,imgX]=size(rgb2gray(RGB));
        count=1;
        i=1;
        while isempty(cBall)==0
            if i==1
                Ball{i,13,k}=[];
                Ball{i,1,k}=i;
                [Ball{i,2,k},Ball{i,3,k}]=QueBallCenter(BGR,RGB);
                RGB=insertText(RGB,[Ball{i,2,k}-ballRad,Ball{i,3,k}-ballRad],'cue','FontSize',18,'TextColor','black','BoxOpacity',0);
                index_x= find(round(Ball{i,2,k})<(round(cBall(:,1))+30) & (round(Ball{i,2,k})>(round(cBall(:,1))-30)),1);
                index_y= find(round(Ball{i,3,k})<(round(cBall(:,2))+30) & (round(Ball{i,3,k})>(round(cBall(:,2))-30)),1);
                if index_y==index_x
                    cBall(index_x,:)=[];
                end
                Ball{i,4,k} = [0 0 0 0 0 0];
                Ball{i,5,k} = [0 0 0 0 0 0];
                Ball{i,6,k} = [0 0 0 0 0 0];
                Ball{i,7,k} = [0 0 0 0 0 0];
                Ball{i,8,k} = [0 0 0 0 0 0];
                Ball{i,9,k} = [0 0 0 0 0 0];
                Ball{i,10,k} = [0 0 0 0 0 0];
                Ball{i,11,k} = [0 0 0 0 0 0];
                Ball{i,12,k} = [0 0 0 0 0 0];
                Ball{i,13,k} = [0 0 0 0 0 0];
                if Ball{1,2,k} > imgX/2
                    if Ball{1,3,k} > imgY/2
                        if (pocket(4,1)-Ball{1,2,k}<75 || pocket(4,2)-Ball{1,3,k}<75)
                            A(k)=30;
                            rotWeight=5;
                        elseif (pocket(4,1)-Ball{1,2,k}<150 || pocket(4,2)-Ball{1,3,k}<150)
                            A(k)=20;
                            rotWeight=2;
                        else
                            A(k)=15;
                            rotWeight=1;
                        end
                    elseif Ball{1,3,k} <= imgY/2
                        if (pocket(3,1)-Ball{1,2,k}<75 || pocket(3,2)-Ball{1,3,k}>-75)
                            A(k)=30;
                            rotWeight=5;
                        elseif (pocket(3,1)-Ball{1,2,k}<150 || pocket(3,2)-Ball{1,3,k}>-150)
                            A(k)=20;
                            rotWeight=2;
                        else
                            A(k)=15;
                            rotWeight=1;
                        end
                    end
                elseif Ball{1,2,k} <= imgX/2
                    if Ball{1,3,k} > imgY/2
                        if (pocket(6,1)-Ball{1,2,k}>-75 || pocket(6,2)-Ball{1,3,k}<75)
                            A(k)=30;
                            rotWeight=5;
                        elseif (pocket(6,1)-Ball{1,2,k}>-150 || pocket(6,2)-Ball{1,3,k}<150)
                            A(k)=20;
                            rotWeight=2;
                        else
                            A(k)=15;
                            rotWeight=1;
                        end
                    elseif Ball{1,3,k} <= imgY/2
                        if (pocket(1,1)-Ball{1,2,k}>-75 || pocket(1,2)-Ball{1,3,k}>-75)
                            A(k)=30;
                            rotWeight=5;
                        elseif (pocket(1,1)-Ball{1,2,k}>-150 || pocket(1,2)-Ball{1,3,k}>-150)
                            A(k)=20;
                            rotWeight=2;
                        else
                            A(k)=15;
                            rotWeight=1;
                        end
                    end
                end
                Z(k)=648;%for now z is to remain constant647 last values from 0 0 -90 0 -90
                Ts(k)=90;
            else
                Ball{i,1,k}=i;
                Ball{i,2,k}=cBall(1,1);
                Ball{i,3,k}=cBall(1,2);
                RGB=insertText(RGB,[Ball{i,2,k}-ballRad,Ball{i,3,k}-ballRad],num2str(Ball{i,1,k}),'FontSize',18,'TextColor','black','BoxOpacity',0);
                cBall(1,:)=[];
                for j = 1:6
                    Ball{i,4,k} = [Ball{i,4,k} sqrt((Ball{i,2,k}-pocket(j,1))^2+(Ball{i,3,k}-pocket(j,2))^2)];
                    Ball{i,5,k} = [Ball{i,5,k}  (pocket(j,1)-Ball{i,2,k})/Ball{i,4,k}(j)];%vectx
                    Ball{i,6,k} = [Ball{i,6,k}  (pocket(j,2)-Ball{i,3,k})/Ball{i,4,k}(j)];%vecty
                    Ball{i,7,k} = [Ball{i,7,k}  Ball{i,2,k}-(ballRad*2)*Ball{i,5,k}(j)];
                    Ball{i,8,k} = [Ball{i,8,k}  Ball{i,3,k}-(ballRad*2)*Ball{i,6,k}(j)];
                    Ball{i,9,k} = [Ball{i,9,k}  sqrt((Ball{i,7,k}(j)-Ball{1,2,k})^2+(Ball{i,8,k}(j)-Ball{1,3,k})^2)]; %distance cue Ball travel
                    Ball{i,10,k} = [Ball{i,10,k}  (Ball{i,7,k}(j)-Ball{1,2,k})/(Ball{i,9,k}(j))]; %distance cue Ball travelx
                    Ball{i,11,k} = [Ball{i,11,k}  (Ball{i,8,k}(j)-Ball{1,3,k})/(Ball{i,9,k}(j))]; %distance cue Ball travely
                    Ball{i,12,k} = [Ball{i,12,k}  acosd(dot([Ball{i,10,k}(j) Ball{i,11,k}(j)],[Ball{i,5,k}(j) Ball{i,6,k}(j)]))];
                    targetBall2wallWeight=[];
                    if Ball{i,12,k}(j)<65
                        if Ball{i,7,k}(j) > imgX/2
                            if Ball{i,8,k}(j) > imgY/2 %
                                if pocket(4,1)-Ball{i,7,k}(j)<50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(4,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                if  pocket(4,2)-Ball{1,8,k}(j)<50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(4,2)-Ball{1,8,k}(j))/5;
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                targetBall2wallWeight=targetBall2wallWeight/2;
                                if (Ball{i,7,k}(j)>pocket(4,1)||Ball{i,8,k}(j)>pocket(4,2))
                                    Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                else
                                    Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                end
                            elseif Ball{i,8,k}(j) <= imgY/2
                                if pocket(3,1)-Ball{i,7,k}(j)<50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(3,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                if  pocket(3,2)-Ball{1,8,k}(j)>-50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(3,2)-Ball{1,8,k}(j))/5;
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                targetBall2wallWeight=targetBall2wallWeight/2;
                                if (Ball{i,7,k}(j)>pocket(3,1)||Ball{i,8,k}(j)<pocket(3,2))
                                    Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                else
                                    Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                end
                            end
                        elseif Ball{i,7,k}(j) <= imgX/2
                            if Ball{i,8,k}(j) > imgY/2
                                if pocket(6,1)-Ball{i,7,k}(j)>-50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(6,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                if  pocket(6,2)-Ball{1,8,k}(j)<50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(6,2)-Ball{1,8,k}(j))/5;
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                targetBall2wallWeight=targetBall2wallWeight/2;
                                if (Ball{i,7,k}(j)<pocket(6,1)||Ball{i,8,k}(j)>pocket(6,2))
                                    Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                else
                                    Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                end
                            elseif Ball{i,8,k}(j) <= imgY/2
                                if pocket(1,1)-Ball{i,7,k}(j)>-50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(1,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                if  pocket(1,2)-Ball{1,8,k}(j)>-50
                                    targetBall2wallWeight=targetBall2wallWeight+abs(pocket(1,2)-Ball{1,8,k}(j))/5;
                                else
                                    targetBall2wallWeight=targetBall2wallWeight+1;
                                end
                                targetBall2wallWeight=targetBall2wallWeight/2;
                                if (Ball{i,7,k}(j)<pocket(1,1)||Ball{i,8,k}(j)<pocket(1,2))
                                    Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                else
                                    Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                end
                            end
                        end
                    else
                        Ball{i,13,k}=[Ball{i,13,k} 0];%false by phi being greater than 85
                    end
                    if Ball{i,13,k}(j)==1
                        X(k)=(round((Ball{1,2,k})-903.678,2));%835.624 is offset to corner +6.3250 is cuestick radius if farthest edge detected-41.154+11
                        Y(k)=(round((Ball{1,3,k})-598.14,2));%+58.532 og offset from corner-64.501-46
                        GG=@(AA,BB) [dot(AA,BB) -norm(cross(AA,BB)) 0 ;norm(cross(AA,BB)) dot(AA,BB) 0 ; 0 0 1];
                        FFi = @(AA,BB) [ AA (BB-dot(AA,BB)*AA)/norm(BB-dot(AA,BB)*AA) cross(BB,AA) ];
                        UU = @(Fi,G) Fi*G*inv(Fi);
                        aa=[-1 0 0]';bb=[Ball{i,10,k}(j) Ball{i,11,k}(j) 0]';
                        U = UU(FFi(aa,bb), GG(aa,bb));
                        Oo=round(tr2eul(U)*(180/pi),2);
                        O(k)=Oo(3);
                        A(k)=abs(A(k));
                        Ts(k)=abs(Ts(k));
                        disp([num2str(X(k)) ' ' num2str(Y(k)) ' ' num2str(Z) ' ' num2str(O(k)) ' ' num2str(A(k)) ' ' num2str(Ts(k))])
                        Shot{count,1,k}=[(X(k)) (Y(k)) (Z(k)) (O(k)) (A(k)) (Ts(k))];
                        DistanceBeforeCollision=sqrt(abs(Ball{1,2,k}-Ball{i,7,k}(j))^2+abs(Ball{1,3,k}-Ball{i,8,k}(j))^2);
                        DistanceAfterCollision=sqrt(abs(pocket(j,1)-Ball{i,2,k})^2+abs(pocket(j,2)-Ball{i,3,k})^2);
                        deltaDistance(k)=(DistanceBeforeCollision+DistanceAfterCollision)*.1;
                        Shot{count,10,k}=(Ball{i,12,k}(j)*6)+(DistanceAfterCollision*.5)+(DistanceBeforeCollision*.1)*rotWeight;%rank
                        Shot{count,2,k}=[Ball{1,2,k},Ball{i,7,k}(j)];
                        Shot{count,3,k}=[Ball{1,3,k},Ball{i,8,k}(j)];
                        Shot{count,4,k}=[Ball{i,7,k}(j), Ball{i,8,k}(j)];
                        Shot{count,5,k}=[pocket(j,1),Ball{i,2,k}];
                        Shot{count,6,k}=[pocket(j,2),Ball{i,3,k}];
                        Shot{count,7,k}=[Ball{i,2,k},Ball{i,7,k}(j)];
                        Shot{count,8,k}=[Ball{i,3,k},Ball{i,8,k}(j)];
                        Shot{count,9,k}=color{j};
                        
                        if deltaDistance(k)<50
                            deltaDistance(k)=50;
                        elseif deltaDistance(k)>200
                            deltaDistance(k)=200;
                        end
                        Shot{count,11,k}=deltaDistance(k);
                        count=count+1;
                    end
                end
            end
            i=i+1;
        end
        Shots=cell2table(Shot(:,:,k));
        Shots.Properties.VariableNames={'XYZOATs','Draw1_1','Draw1_2','Draw2_1','Draw3_1','Draw3_2','Draw4_1','Draw4_2','Color','Rank','deltaDistance'};
        Balls=cell2table(Ball(:,:,k));
        Balls.Properties.VariableNames={'Num','X','Y','TargetBall2Pocket_mag','TargetBall2Pocket_UnitX','TargetBall2Pocket_UnitY','GhostBall_x','GhostBall_y','CueBall2TargetBall_mag','CueBall2TargetBall_UnitX','CueBall2TargetBall_UnitY','Phi','Possible'};
        rankedShots=sort(Shots.Rank(:));
        %imshow(RGB);
        axis on; hold on;
        %for 1 lense
        
        robotSend{k}=DrawShot(find(Shots.Rank(:)==rankedShots(1)));
        
        ballScrewBack{k}=75;
        %DrawShot(find(Shots.Rank(:)==rankedShots(1)));
    end

    %for both images summed together
    %results sent back
    rs=(robotSend{2}+robotSend{1})./2;
    robotSend=([num2str(rs(1)) ' ' num2str(rs(2)) ' ' num2str(rs(3)) ' ' num2str(rs(4)) ' ' num2str(rs(5)) ' ' num2str(rs(6))]);
    ballScrewBack=(ballScrewBack{2}+ballScrewBack{1})./2;
catch
    %try just left image
    try
        %%
        %clearvars -except zed color bumper_w ballRad
        %run with left
        for k=2:2
            if k==1
                RGB=zed.right.undistorted.RGB;
                BGR=zed.right.undistorted.BGR;
            else
                RGB=zed.left.undistorted.RGB;
                BGR=zed.left.undistorted.BGR;
            end
            %dot Diameter =16max
            Left=[];
            Right=[];
            Top=[];
            Bot=[];
            %figure; imshow(RGB);
            %axis on;
            %title('Undistorted');
            while ((isempty(Left) | isempty(Right) | isempty(Top) | isempty(Bot))==1)==1
                Left=[];
                Right=[];
                Top=[];
                Bot=[];
                [cDot, r] = imfindcircles(BGR,[5 10],'Sensitivity', 0.9, 'EdgeThreshold', 0.4);
                %viscircles(cDot, r,'Color','r');
                rNew=[];
                cDotNew=[];
                for i=1:length(cDot)
                    if r(i)<8.5 && r(i)>6.3
                        rNew=[rNew;r(i)];
                        cDotNew=[cDotNew; cDot(i,:)];
                    end
                end
                cDot=cDotNew;
                r=rNew;
                rNew=[];
                cDotNew=[];
                %viscircles(cDot, r,'Color','y');
                for i=1:length(cDot)
                    if cDot(i,1) <= 300
                        Left=[Left;cDot(i,:)];
                        rNew=[rNew;r(i)];
                        cDotNew=[cDotNew; cDot(i,:)];
                    elseif cDot(i,1) > 300 && cDot(i,1) <=1900
                        if cDot(i,2)<= 300
                            Top=[Top;cDot(i,:)];
                            rNew=[rNew;r(i)];
                            cDotNew=[cDotNew; cDot(i,:)];
                        elseif cDot(i,2)>= 1050
                            Bot=[Bot;cDot(i,:)];
                            rNew=[rNew;r(i)];
                            cDotNew=[cDotNew; cDot(i,:)];
                        end
                    elseif cDot(i,1) >= 1900
                        Right=[Right;cDot(i,:)];
                        rNew=[rNew;r(i)];
                        cDotNew=[cDotNew; cDot(i,:)];
                    else
                    end
                end
            end
            cDot=cDotNew;
            r=rNew;
            %viscircles(cDot, r,'Color','g');
            Top=sum(Top(:,2))/length(Top(:,2));
            Bot=sum(Bot(:,2))/length(Bot(:,2));
            Right=sum(Right(:,1))/length(Right(:,1));
            Left=sum(Left(:,1))/length(Left(:,1));
            CroppedTable=[Left Top Right-Left Bot-Top];
            RGB=imcrop(RGB,CroppedTable);
            BGR=imcrop(BGR,CroppedTable);
            RGB=imresize(RGB, [980 1811]);
            BGR=imresize(BGR, [980 1811]);
            figure
            imshow(RGB);
            axis on;
            
            [yCrop,xCrop]=size(rgb2gray(BGR));
            pocket =    [ballRad+bumper_w ballRad+bumper_w;(xCrop)/2 bumper_w;xCrop-ballRad-bumper_w ballRad+bumper_w;xCrop-ballRad-bumper_w yCrop-ballRad-bumper_w;(xCrop)/2 yCrop-bumper_w;ballRad+bumper_w yCrop-ballRad-bumper_w];
            for i=1:6
                viscircles(pocket(i,:), (ballRad/2), 'Color', color{i}, 'LineStyle', '-.');
            end
            %%
            [cBall,r] = imfindcircles(RGB,[25 35],'Sensitivity', .9, 'EdgeThreshold', .2);
            viscircles(cBall, r,'Color','b');
            [imgY,imgX]=size(rgb2gray(RGB));
            count=1;
            i=1;
            while isempty(cBall)==0
                if i==1
                    Ball{i,13,k}=[];
                    Ball{i,1,k}=i;
                    [Ball{i,2,k},Ball{i,3,k}]=QueBallCenter(BGR,RGB);
                    RGB=insertText(RGB,[Ball{i,2,k}-ballRad,Ball{i,3,k}-ballRad],'cue','FontSize',18,'TextColor','black','BoxOpacity',0);
                    index_x= find(round(Ball{i,2,k})<(round(cBall(:,1))+30) & (round(Ball{i,2,k})>(round(cBall(:,1))-30)),1);
                    index_y= find(round(Ball{i,3,k})<(round(cBall(:,2))+30) & (round(Ball{i,3,k})>(round(cBall(:,2))-30)),1);
                    if index_y==index_x
                        cBall(index_x,:)=[];
                    end
                    Ball{i,4,k} = [0 0 0 0 0 0];
                    Ball{i,5,k} = [0 0 0 0 0 0];
                    Ball{i,6,k} = [0 0 0 0 0 0];
                    Ball{i,7,k} = [0 0 0 0 0 0];
                    Ball{i,8,k} = [0 0 0 0 0 0];
                    Ball{i,9,k} = [0 0 0 0 0 0];
                    Ball{i,10,k} = [0 0 0 0 0 0];
                    Ball{i,11,k} = [0 0 0 0 0 0];
                    Ball{i,12,k} = [0 0 0 0 0 0];
                    Ball{i,13,k} = [0 0 0 0 0 0];
                    if Ball{1,2,k} > imgX/2
                        if Ball{1,3,k} > imgY/2
                            if (pocket(4,1)-Ball{1,2,k}<75 || pocket(4,2)-Ball{1,3,k}<75)
                                A(k)=30;
                                rotWeight=5;
                            elseif (pocket(4,1)-Ball{1,2,k}<150 || pocket(4,2)-Ball{1,3,k}<150)
                                A(k)=20;
                                rotWeight=2;
                            else
                                A(k)=15;
                                rotWeight=1;
                            end
                        elseif Ball{1,3,k} <= imgY/2
                            if (pocket(3,1)-Ball{1,2,k}<75 || pocket(3,2)-Ball{1,3,k}>-75)
                                A(k)=30;
                                rotWeight=5;
                            elseif (pocket(3,1)-Ball{1,2,k}<150 || pocket(3,2)-Ball{1,3,k}>-150)
                                A(k)=20;
                                rotWeight=2;
                            else
                                A(k)=15;
                                rotWeight=1;
                            end
                        end
                    elseif Ball{1,2,k} <= imgX/2
                        if Ball{1,3,k} > imgY/2
                            if (pocket(6,1)-Ball{1,2,k}>-75 || pocket(6,2)-Ball{1,3,k}<75)
                                A(k)=30;
                                rotWeight=5;
                            elseif (pocket(6,1)-Ball{1,2,k}>-150 || pocket(6,2)-Ball{1,3,k}<150)
                                A(k)=20;
                                rotWeight=2;
                            else
                                A(k)=15;
                                rotWeight=1;
                            end
                        elseif Ball{1,3,k} <= imgY/2
                            if (pocket(1,1)-Ball{1,2,k}>-75 || pocket(1,2)-Ball{1,3,k}>-75)
                                A(k)=30;
                                rotWeight=5;
                            elseif (pocket(1,1)-Ball{1,2,k}>-150 || pocket(1,2)-Ball{1,3,k}>-150)
                                A(k)=20;
                                rotWeight=2;
                            else
                                A(k)=15;
                                rotWeight=1;
                            end
                        end
                    end
                    Z(k)=648;%for now z is to remain constant647 last values from 0 0 -90 0 -90
                    Ts(k)=90;
                else
                    Ball{i,1,k}=i;
                    Ball{i,2,k}=cBall(1,1);
                    Ball{i,3,k}=cBall(1,2);
                    RGB=insertText(RGB,[Ball{i,2,k}-ballRad,Ball{i,3,k}-ballRad],num2str(Ball{i,1,k}),'FontSize',18,'TextColor','black','BoxOpacity',0);
                    cBall(1,:)=[];
                    for j = 1:6
                        Ball{i,4,k} = [Ball{i,4,k} sqrt((Ball{i,2,k}-pocket(j,1))^2+(Ball{i,3,k}-pocket(j,2))^2)];
                        Ball{i,5,k} = [Ball{i,5,k}  (pocket(j,1)-Ball{i,2,k})/Ball{i,4,k}(j)];%vectx
                        Ball{i,6,k} = [Ball{i,6,k}  (pocket(j,2)-Ball{i,3,k})/Ball{i,4,k}(j)];%vecty
                        Ball{i,7,k} = [Ball{i,7,k}  Ball{i,2,k}-(ballRad*2)*Ball{i,5,k}(j)];
                        Ball{i,8,k} = [Ball{i,8,k}  Ball{i,3,k}-(ballRad*2)*Ball{i,6,k}(j)];
                        Ball{i,9,k} = [Ball{i,9,k}  sqrt((Ball{i,7,k}(j)-Ball{1,2,k})^2+(Ball{i,8,k}(j)-Ball{1,3,k})^2)]; %distance cue Ball travel
                        Ball{i,10,k} = [Ball{i,10,k}  (Ball{i,7,k}(j)-Ball{1,2,k})/(Ball{i,9,k}(j))]; %distance cue Ball travelx
                        Ball{i,11,k} = [Ball{i,11,k}  (Ball{i,8,k}(j)-Ball{1,3,k})/(Ball{i,9,k}(j))]; %distance cue Ball travely
                        Ball{i,12,k} = [Ball{i,12,k}  acosd(dot([Ball{i,10,k}(j) Ball{i,11,k}(j)],[Ball{i,5,k}(j) Ball{i,6,k}(j)]))];
                        targetBall2wallWeight=[];
                        if Ball{i,12,k}(j)<65
                            if Ball{i,7,k}(j) > imgX/2
                                if Ball{i,8,k}(j) > imgY/2 %
                                    if pocket(4,1)-Ball{i,7,k}(j)<50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(4,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    if  pocket(4,2)-Ball{1,8,k}(j)<50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(4,2)-Ball{1,8,k}(j))/5;
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    targetBall2wallWeight=targetBall2wallWeight/2;
                                    if (Ball{i,7,k}(j)>pocket(4,1)||Ball{i,8,k}(j)>pocket(4,2))
                                        Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                    else
                                        Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                    end
                                elseif Ball{i,8,k}(j) <= imgY/2
                                    if pocket(3,1)-Ball{i,7,k}(j)<50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(3,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    if  pocket(3,2)-Ball{1,8,k}(j)>-50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(3,2)-Ball{1,8,k}(j))/5;
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    targetBall2wallWeight=targetBall2wallWeight/2;
                                    if (Ball{i,7,k}(j)>pocket(3,1)||Ball{i,8,k}(j)<pocket(3,2))
                                        Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                    else
                                        Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                    end
                                end
                            elseif Ball{i,7,k}(j) <= imgX/2
                                if Ball{i,8,k}(j) > imgY/2
                                    if pocket(6,1)-Ball{i,7,k}(j)>-50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(6,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    if  pocket(6,2)-Ball{1,8,k}(j)<50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(6,2)-Ball{1,8,k}(j))/5;
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    targetBall2wallWeight=targetBall2wallWeight/2;
                                    if (Ball{i,7,k}(j)<pocket(6,1)||Ball{i,8,k}(j)>pocket(6,2))
                                        Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                    else
                                        Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                    end
                                elseif Ball{i,8,k}(j) <= imgY/2
                                    if pocket(1,1)-Ball{i,7,k}(j)>-50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(1,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    if  pocket(1,2)-Ball{1,8,k}(j)>-50
                                        targetBall2wallWeight=targetBall2wallWeight+abs(pocket(1,2)-Ball{1,8,k}(j))/5;
                                    else
                                        targetBall2wallWeight=targetBall2wallWeight+1;
                                    end
                                    targetBall2wallWeight=targetBall2wallWeight/2;
                                    if (Ball{i,7,k}(j)<pocket(1,1)||Ball{i,8,k}(j)<pocket(1,2))
                                        Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                    else
                                        Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                    end
                                end
                            end
                        else
                            Ball{i,13,k}=[Ball{i,13,k} 0];%false by phi being greater than 85
                        end
                        if Ball{i,13,k}(j)==1
                            X(k)=(round((Ball{1,2,k})-903.678,2));%835.624 is offset to corner +6.3250 is cuestick radius if farthest edge detected-41.154+11
                            Y(k)=(round((Ball{1,3,k})-598.14,2));%+58.532 og offset from corner-64.501-46
                            GG=@(AA,BB) [dot(AA,BB) -norm(cross(AA,BB)) 0 ;norm(cross(AA,BB)) dot(AA,BB) 0 ; 0 0 1];
                            FFi = @(AA,BB) [ AA (BB-dot(AA,BB)*AA)/norm(BB-dot(AA,BB)*AA) cross(BB,AA) ];
                            UU = @(Fi,G) Fi*G*inv(Fi);
                            aa=[-1 0 0]';bb=[Ball{i,10,k}(j) Ball{i,11,k}(j) 0]';
                            U = UU(FFi(aa,bb), GG(aa,bb));
                            Oo=round(tr2eul(U)*(180/pi),2);
                            O(k)=Oo(3);
                            A(k)=abs(A(k));
                            Ts(k)=abs(Ts(k));
                            disp([num2str(X(k)) ' ' num2str(Y(k)) ' ' num2str(Z) ' ' num2str(O(k)) ' ' num2str(A(k)) ' ' num2str(Ts(k))])
                            Shot{count,1,k}=[(X(k)) (Y(k)) (Z(k)) (O(k)) (A(k)) (Ts(k))];
                            DistanceBeforeCollision=sqrt(abs(Ball{1,2,k}-Ball{i,7,k}(j))^2+abs(Ball{1,3,k}-Ball{i,8,k}(j))^2);
                            DistanceAfterCollision=sqrt(abs(pocket(j,1)-Ball{i,2,k})^2+abs(pocket(j,2)-Ball{i,3,k})^2);
                            deltaDistance(k)=(DistanceBeforeCollision+DistanceAfterCollision)*.1;
                            Shot{count,10,k}=(Ball{i,12,k}(j)*6)+(DistanceAfterCollision*.5)+(DistanceBeforeCollision*.1)*rotWeight;%rank
                            Shot{count,2,k}=[Ball{1,2,k},Ball{i,7,k}(j)];
                            Shot{count,3,k}=[Ball{1,3,k},Ball{i,8,k}(j)];
                            Shot{count,4,k}=[Ball{i,7,k}(j), Ball{i,8,k}(j)];
                            Shot{count,5,k}=[pocket(j,1),Ball{i,2,k}];
                            Shot{count,6,k}=[pocket(j,2),Ball{i,3,k}];
                            Shot{count,7,k}=[Ball{i,2,k},Ball{i,7,k}(j)];
                            Shot{count,8,k}=[Ball{i,3,k},Ball{i,8,k}(j)];
                            Shot{count,9,k}=color{j};
                            
                            if deltaDistance(k)<50
                                deltaDistance(k)=50;
                            elseif deltaDistance(k)>150
                                deltaDistance(k)=150;
                            end
                            Shot{count,11,k}=deltaDistance(k);
                            count=count+1;
                        end
                    end
                end
                i=i+1;
            end
            Shots=cell2table(Shot(:,:,k));
            Shots.Properties.VariableNames={'XYZOATs','Draw1_1','Draw1_2','Draw2_1','Draw3_1','Draw3_2','Draw4_1','Draw4_2','Color','Rank','deltaDistance'};
            Balls=cell2table(Ball(:,:,k));
            Balls.Properties.VariableNames={'Num','X','Y','TargetBall2Pocket_mag','TargetBall2Pocket_UnitX','TargetBall2Pocket_UnitY','GhostBall_x','GhostBall_y','CueBall2TargetBall_mag','CueBall2TargetBall_UnitX','CueBall2TargetBall_UnitY','Phi','Possible'};
            rankedShots=sort(Shots.Rank(:));
            %imshow(RGB);
            axis on; hold on;
            %for 1 lense
            
            robotSend{k}=DrawShot(find(Shots.Rank(:)==rankedShots(1)));
            
            %ballScrewBack=75;
            %DrawShot(find(Shots.Rank(:)==rankedShots(1)));
        end
        
        %for Left image by its self
        rs=(robotSend{2}+robotSend{1})./2;
        robotSend=([num2str(rs(1)) ' ' num2str(rs(2)) ' ' num2str(rs(3)) ' ' num2str(rs(4)) ' ' num2str(rs(5)) ' ' num2str(rs(6))]);
        ballScrewBack=(ballScrewBack{2}+ballScrewBack{1})./2;
        
    catch
        %try just right
        try
            %clearvars -except zed color bumper_w ballRad
            %run twice 1 for each img
            for k=1:1
                if k==1
                    RGB=zed.right.undistorted.RGB;
                    BGR=zed.right.undistorted.BGR;
                else
                    RGB=zed.left.undistorted.RGB;
                    BGR=zed.left.undistorted.BGR;
                end
                %dot Diameter =16max
                Left=[];
                Right=[];
                Top=[];
                Bot=[];
                %figure; imshow(RGB);
                %axis on;
                %title('Undistorted');
                while ((isempty(Left) | isempty(Right) | isempty(Top) | isempty(Bot))==1)==1
                    Left=[];
                    Right=[];
                    Top=[];
                    Bot=[];
                    [cDot, r] = imfindcircles(BGR,[5 10],'Sensitivity', 0.9, 'EdgeThreshold', 0.4);
                    %viscircles(cDot, r,'Color','r');
                    rNew=[];
                    cDotNew=[];
                    for i=1:length(cDot)
                        if r(i)<8.5 && r(i)>6.3
                            rNew=[rNew;r(i)];
                            cDotNew=[cDotNew; cDot(i,:)];
                        end
                    end
                    cDot=cDotNew;
                    r=rNew;
                    rNew=[];
                    cDotNew=[];
                    %viscircles(cDot, r,'Color','y');
                    for i=1:length(cDot)
                        if cDot(i,1) <= 300
                            Left=[Left;cDot(i,:)];
                            rNew=[rNew;r(i)];
                            cDotNew=[cDotNew; cDot(i,:)];
                        elseif cDot(i,1) > 300 && cDot(i,1) <=1900
                            if cDot(i,2)<= 300
                                Top=[Top;cDot(i,:)];
                                rNew=[rNew;r(i)];
                                cDotNew=[cDotNew; cDot(i,:)];
                            elseif cDot(i,2)>= 1050
                                Bot=[Bot;cDot(i,:)];
                                rNew=[rNew;r(i)];
                                cDotNew=[cDotNew; cDot(i,:)];
                            end
                        elseif cDot(i,1) >= 1900
                            Right=[Right;cDot(i,:)];
                            rNew=[rNew;r(i)];
                            cDotNew=[cDotNew; cDot(i,:)];
                        else
                        end
                    end
                end
                cDot=cDotNew;
                r=rNew;
                %viscircles(cDot, r,'Color','g');
                Top=sum(Top(:,2))/length(Top(:,2));
                Bot=sum(Bot(:,2))/length(Bot(:,2));
                Right=sum(Right(:,1))/length(Right(:,1));
                Left=sum(Left(:,1))/length(Left(:,1));
                CroppedTable=[Left Top Right-Left Bot-Top];
                RGB=imcrop(RGB,CroppedTable);
                BGR=imcrop(BGR,CroppedTable);
                RGB=imresize(RGB, [980 1811]);
                BGR=imresize(BGR, [980 1811]);
                figure
                imshow(RGB);
                axis on;
                
                [yCrop,xCrop]=size(rgb2gray(BGR));
                pocket =    [ballRad+bumper_w ballRad+bumper_w;(xCrop)/2 bumper_w;xCrop-ballRad-bumper_w ballRad+bumper_w;xCrop-ballRad-bumper_w yCrop-ballRad-bumper_w;(xCrop)/2 yCrop-bumper_w;ballRad+bumper_w yCrop-ballRad-bumper_w];
                for i=1:6
                    viscircles(pocket(i,:), (ballRad*2), 'Color', color{i}, 'LineStyle', '-.');
                end
                %%
                [cBall,r] = imfindcircles(RGB,[25 35],'Sensitivity', .9, 'EdgeThreshold', .2);
                viscircles(cBall, r,'Color','b');
                [imgY,imgX]=size(rgb2gray(RGB));
                count=1;
                i=1;
                while isempty(cBall)==0
                    if i==1
                        Ball{i,13,k}=[];
                        Ball{i,1,k}=i;
                        [Ball{i,2,k},Ball{i,3,k}]=QueBallCenter(BGR,RGB);
                        RGB=insertText(RGB,[Ball{i,2,k}-ballRad,Ball{i,3,k}-ballRad],'cue','FontSize',18,'TextColor','black','BoxOpacity',0);
                        index_x= find(round(Ball{i,2,k})<(round(cBall(:,1))+30) & (round(Ball{i,2,k})>(round(cBall(:,1))-30)),1);
                        index_y= find(round(Ball{i,3,k})<(round(cBall(:,2))+30) & (round(Ball{i,3,k})>(round(cBall(:,2))-30)),1);
                        if index_y==index_x
                            cBall(index_x,:)=[];
                        end
                        Ball{i,4,k} = [0 0 0 0 0 0];
                        Ball{i,5,k} = [0 0 0 0 0 0];
                        Ball{i,6,k} = [0 0 0 0 0 0];
                        Ball{i,7,k} = [0 0 0 0 0 0];
                        Ball{i,8,k} = [0 0 0 0 0 0];
                        Ball{i,9,k} = [0 0 0 0 0 0];
                        Ball{i,10,k} = [0 0 0 0 0 0];
                        Ball{i,11,k} = [0 0 0 0 0 0];
                        Ball{i,12,k} = [0 0 0 0 0 0];
                        Ball{i,13,k} = [0 0 0 0 0 0];
                        if Ball{1,2,k} > imgX/2
                            if Ball{1,3,k} > imgY/2
                                if (pocket(4,1)-Ball{1,2,k}<75 || pocket(4,2)-Ball{1,3,k}<75)
                                    A(k)=30;
                                    rotWeight=5;
                                elseif (pocket(4,1)-Ball{1,2,k}<150 || pocket(4,2)-Ball{1,3,k}<150)
                                    A(k)=20;
                                    rotWeight=2;
                                else
                                    A(k)=15;
                                    rotWeight=1;
                                end
                            elseif Ball{1,3,k} <= imgY/2
                                if (pocket(3,1)-Ball{1,2,k}<75 || pocket(3,2)-Ball{1,3,k}>-75)
                                    A(k)=30;
                                    rotWeight=5;
                                elseif (pocket(3,1)-Ball{1,2,k}<150 || pocket(3,2)-Ball{1,3,k}>-150)
                                    A(k)=20;
                                    rotWeight=2;
                                else
                                    A(k)=15;
                                    rotWeight=1;
                                end
                            end
                        elseif Ball{1,2,k} <= imgX/2
                            if Ball{1,3,k} > imgY/2
                                if (pocket(6,1)-Ball{1,2,k}>-75 || pocket(6,2)-Ball{1,3,k}<75)
                                    A(k)=30;
                                    rotWeight=5;
                                elseif (pocket(6,1)-Ball{1,2,k}>-150 || pocket(6,2)-Ball{1,3,k}<150)
                                    A(k)=20;
                                    rotWeight=2;
                                else
                                    A(k)=15;
                                    rotWeight=1;
                                end
                            elseif Ball{1,3,k} <= imgY/2
                                if (pocket(1,1)-Ball{1,2,k}>-75 || pocket(1,2)-Ball{1,3,k}>-75)
                                    A(k)=30;
                                    rotWeight=5;
                                elseif (pocket(1,1)-Ball{1,2,k}>-150 || pocket(1,2)-Ball{1,3,k}>-150)
                                    A(k)=20;
                                    rotWeight=2;
                                else
                                    A(k)=15;
                                    rotWeight=1;
                                end
                            end
                        end
                        Z(k)=648;%for now z is to remain constant647 last values from 0 0 -90 0 -90
                        Ts(k)=90;
                    else
                        Ball{i,1,k}=i;
                        Ball{i,2,k}=cBall(1,1);
                        Ball{i,3,k}=cBall(1,2);
                        RGB=insertText(RGB,[Ball{i,2,k}-ballRad,Ball{i,3,k}-ballRad],num2str(Ball{i,1,k}),'FontSize',18,'TextColor','black','BoxOpacity',0);
                        cBall(1,:)=[];
                        for j = 1:6
                            Ball{i,4,k} = [Ball{i,4,k} sqrt((Ball{i,2,k}-pocket(j,1))^2+(Ball{i,3,k}-pocket(j,2))^2)];
                            Ball{i,5,k} = [Ball{i,5,k}  (pocket(j,1)-Ball{i,2,k})/Ball{i,4,k}(j)];%vectx
                            Ball{i,6,k} = [Ball{i,6,k}  (pocket(j,2)-Ball{i,3,k})/Ball{i,4,k}(j)];%vecty
                            Ball{i,7,k} = [Ball{i,7,k}  Ball{i,2,k}-(ballRad*2)*Ball{i,5,k}(j)];
                            Ball{i,8,k} = [Ball{i,8,k}  Ball{i,3,k}-(ballRad*2)*Ball{i,6,k}(j)];
                            Ball{i,9,k} = [Ball{i,9,k}  sqrt((Ball{i,7,k}(j)-Ball{1,2,k})^2+(Ball{i,8,k}(j)-Ball{1,3,k})^2)]; %distance cue Ball travel
                            Ball{i,10,k} = [Ball{i,10,k}  (Ball{i,7,k}(j)-Ball{1,2,k})/(Ball{i,9,k}(j))]; %distance cue Ball travelx
                            Ball{i,11,k} = [Ball{i,11,k}  (Ball{i,8,k}(j)-Ball{1,3,k})/(Ball{i,9,k}(j))]; %distance cue Ball travely
                            Ball{i,12,k} = [Ball{i,12,k}  acosd(dot([Ball{i,10,k}(j) Ball{i,11,k}(j)],[Ball{i,5,k}(j) Ball{i,6,k}(j)]))];
                            targetBall2wallWeight=[];
                            if Ball{i,12,k}(j)<65
                                if Ball{i,7,k}(j) > imgX/2
                                    if Ball{i,8,k}(j) > imgY/2 %
                                        if pocket(4,1)-Ball{i,7,k}(j)<50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(4,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        if  pocket(4,2)-Ball{1,8,k}(j)<50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(4,2)-Ball{1,8,k}(j))/5;
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        targetBall2wallWeight=targetBall2wallWeight/2;
                                        if (Ball{i,7,k}(j)>pocket(4,1)||Ball{i,8,k}(j)>pocket(4,2))
                                            Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                        else
                                            Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                        end
                                    elseif Ball{i,8,k}(j) <= imgY/2
                                        if pocket(3,1)-Ball{i,7,k}(j)<50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(3,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        if  pocket(3,2)-Ball{1,8,k}(j)>-50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(3,2)-Ball{1,8,k}(j))/5;
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        targetBall2wallWeight=targetBall2wallWeight/2;
                                        if (Ball{i,7,k}(j)>pocket(3,1)||Ball{i,8,k}(j)<pocket(3,2))
                                            Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                        else
                                            Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                        end
                                    end
                                elseif Ball{i,7,k}(j) <= imgX/2
                                    if Ball{i,8,k}(j) > imgY/2
                                        if pocket(6,1)-Ball{i,7,k}(j)>-50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(6,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        if  pocket(6,2)-Ball{1,8,k}(j)<50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(6,2)-Ball{1,8,k}(j))/5;
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        targetBall2wallWeight=targetBall2wallWeight/2;
                                        if (Ball{i,7,k}(j)<pocket(6,1)||Ball{i,8,k}(j)>pocket(6,2))
                                            Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                        else
                                            Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                        end
                                    elseif Ball{i,8,k}(j) <= imgY/2
                                        if pocket(1,1)-Ball{i,7,k}(j)>-50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(1,1)-Ball{i,7,k}(j))/5;%sum of x and y distance from wall added max==100 then /10 so max multi ==10
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        if  pocket(1,2)-Ball{1,8,k}(j)>-50
                                            targetBall2wallWeight=targetBall2wallWeight+abs(pocket(1,2)-Ball{1,8,k}(j))/5;
                                        else
                                            targetBall2wallWeight=targetBall2wallWeight+1;
                                        end
                                        targetBall2wallWeight=targetBall2wallWeight/2;
                                        if (Ball{i,7,k}(j)<pocket(1,1)||Ball{i,8,k}(j)<pocket(1,2))
                                            Ball{i,13,k}=[Ball{i,13,k} 0];%shotpossible==FALSE
                                        else
                                            Ball{i,13,k}=[Ball{i,13,k} 1];%not eliminated yet
                                        end
                                    end
                                end
                            else
                                Ball{i,13,k}=[Ball{i,13,k} 0];%false by phi being greater than 85
                            end
                            if Ball{i,13,k}(j)==1
                                X(k)=(round((Ball{1,2,k})-903.678,2));%835.624 is offset to corner +6.3250 is cuestick radius if farthest edge detected-41.154+11
                                Y(k)=(round((Ball{1,3,k})-598.14,2));%+58.532 og offset from corner-64.501-46
                                GG=@(AA,BB) [dot(AA,BB) -norm(cross(AA,BB)) 0 ;norm(cross(AA,BB)) dot(AA,BB) 0 ; 0 0 1];
                                FFi = @(AA,BB) [ AA (BB-dot(AA,BB)*AA)/norm(BB-dot(AA,BB)*AA) cross(BB,AA) ];
                                UU = @(Fi,G) Fi*G*inv(Fi);
                                aa=[-1 0 0]';bb=[Ball{i,10,k}(j) Ball{i,11,k}(j) 0]';
                                U = UU(FFi(aa,bb), GG(aa,bb));
                                Oo=round(tr2eul(U)*(180/pi),2);
                                O(k)=Oo(3);
                                A(k)=abs(A(k));
                                Ts(k)=abs(Ts(k));
                                disp([num2str(X(k)) ' ' num2str(Y(k)) ' ' num2str(Z) ' ' num2str(O(k)) ' ' num2str(A(k)) ' ' num2str(Ts(k))])
                                Shot{count,1,k}=[(X(k)) (Y(k)) (Z(k)) (O(k)) (A(k)) (Ts(k))];
                                DistanceBeforeCollision=sqrt(abs(Ball{1,2,k}-Ball{i,7,k}(j))^2+abs(Ball{1,3,k}-Ball{i,8,k}(j))^2);
                                DistanceAfterCollision=sqrt(abs(pocket(j,1)-Ball{i,2,k})^2+abs(pocket(j,2)-Ball{i,3,k})^2);
                                deltaDistance(k)=(DistanceBeforeCollision+DistanceAfterCollision)*.1;
                                Shot{count,10,k}=(Ball{i,12,k}(j)*6)+(DistanceAfterCollision*.5)+(DistanceBeforeCollision*.1)*rotWeight;%rank
                                Shot{count,2,k}=[Ball{1,2,k},Ball{i,7,k}(j)];
                                Shot{count,3,k}=[Ball{1,3,k},Ball{i,8,k}(j)];
                                Shot{count,4,k}=[Ball{i,7,k}(j), Ball{i,8,k}(j)];
                                Shot{count,5,k}=[pocket(j,1),Ball{i,2,k}];
                                Shot{count,6,k}=[pocket(j,2),Ball{i,3,k}];
                                Shot{count,7,k}=[Ball{i,2,k},Ball{i,7,k}(j)];
                                Shot{count,8,k}=[Ball{i,3,k},Ball{i,8,k}(j)];
                                Shot{count,9,k}=color{j};
                                
                                if deltaDistance(k)<50
                                    deltaDistance(k)=50;
                                elseif deltaDistance(k)>150
                                    deltaDistance(k)=150;
                                end
                                Shot{count,11,k}=deltaDistance(k);
                                count=count+1;
                            end
                        end
                    end
                    i=i+1;
                end
                Shots=cell2table(Shot(:,:,k));
                Shots.Properties.VariableNames={'XYZOATs','Draw1_1','Draw1_2','Draw2_1','Draw3_1','Draw3_2','Draw4_1','Draw4_2','Color','Rank','deltaDistance'};
                Balls=cell2table(Ball(:,:,k));
                Balls.Properties.VariableNames={'Num','X','Y','TargetBall2Pocket_mag','TargetBall2Pocket_UnitX','TargetBall2Pocket_UnitY','GhostBall_x','GhostBall_y','CueBall2TargetBall_mag','CueBall2TargetBall_UnitX','CueBall2TargetBall_UnitY','Phi','Possible'};
                rankedShots=sort(Shots.Rank(:));
                %imshow(RGB);
                axis on; hold on;
                %for 1 lense
                
                [robotSend{k},ballScrewBack{k}]=DrawShot(find(Shots.Rank(:)==rankedShots(1)));
                
                %ballScrewBack=75;
                %DrawShot(find(Shots.Rank(:)==rankedShots(1)));
            end
            
            %for Right Image only
            rs=(robotSend{2}+robotSend{1})./2;
            robotSend=([num2str(rs(1)) ' ' num2str(rs(2)) ' ' num2str(rs(3)) ' ' num2str(rs(4)) ' ' num2str(rs(5)) ' ' num2str(rs(6))]);
            ballScrewBack=(ballScrewBack{2}+ballScrewBack{1})./2;
        catch
            %for now send back(0 0 100 0 0 0)
            %this will be sent to peppers to get a higher image to
            %hopefully catch pool entire table
            %photo
            robotSend=('0 0 0 0 0 0');
            ballScrewBack=0;
        end
    end
end
%%

%for ballscrewback uncomment when connected

clear arduinoUno
arduinoUno = arduino('COM8','uno');
for i=1:ballScrewBack
    % Move Reverse
    writeDigitalPin(arduinoUno,'D4',0);
    writePWMDutyCycle(arduinoUno,'D3',0.7);
end
writeDigitalPin(arduinoUno,'D3',0);
clear arduinoUno

end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ENDS MAIN FUNCTION

%%

function [fixedImage]=BGR2RGB(imageArray)
placeholder(:,:,1)=imageArray(:,:,3);
imageArray(:,:,3)=imageArray(:,:,1);
imageArray(:,:,1)=placeholder(:,:,1);
fixedImage=imageArray;
end
function[CueBallx,CueBally]=QueBallCenter(BGR,RGB)
try
    
    I = rgb2lab(RGB);
    
    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 41.395;
    channel1Max = 89.381;
    
    % Define thresholds for channel 2 based on histogram settings
    channel2Min = -27.287;
    channel2Max = 31.519;
    
    % Define thresholds for channel 3 based on histogram settings
    channel3Min = -54.676;
    channel3Max = 45.984;
    
    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;
    
    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;
    
    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;
    [cBall, r] = imfindcircles(maskedRGBImage,[25 35],'Sensitivity', 0.9, 'EdgeThreshold', .2);
    cSelect = cBall(1,:);
    
catch
    try
        I = rgb2lab(RGB);
        
        % Define thresholds for channel 1 based on histogram settings
        channel1Min = 58.905;
        channel1Max = 100.000;
        
        % Define thresholds for channel 2 based on histogram settings
        channel2Min = -42.087;
        channel2Max = 68.580;
        
        % Define thresholds for channel 3 based on histogram settings
        channel3Min = -40.437;
        channel3Max = 91.184;
        
        % Create mask based on chosen histogram thresholds
        sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
            (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
            (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
        BW = sliderBW;
        
        % Initialize output masked image based on input image.
        maskedRGBImage = RGB;
        
        % Set background pixels where BW is false to zero.
        maskedRGBImage(repmat(~BW,[1 1 3])) = 0;
        
        [cBall, r] = imfindcircles(maskedRGBImage,[25 35],'Sensitivity', 0.9, 'EdgeThreshold', .2);
        cSelect = cBall(1,:);
        
        
    catch
        try
            
            I = rgb2lab(BGR);
            
            % Define thresholds for channel 1 based on histogram settings
            channel1Min = 37.256;
            channel1Max = 85.237;
            
            % Define thresholds for channel 2 based on histogram settings
            channel2Min = -16.852;
            channel2Max = 18.809;
            
            % Define thresholds for channel 3 based on histogram settings
            channel3Min = -77.905;
            channel3Max = 40.179;
            
            % Create mask based on chosen histogram thresholds
            sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
                (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
                (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
            BW = sliderBW;
            
            % Initialize output masked image based on input image.
            maskedRGBImage = BGR;
            
            % Set background pixels where BW is false to zero.
            maskedRGBImage(repmat(~BW,[1 1 3])) = 0;
            
            [cBall, r] = imfindcircles(maskedRGBImage,[25 35],'Sensitivity', 0.9, 'EdgeThreshold', .2);
            cSelect = cBall(1,:);
            
        catch
            disp('8================================D')
            [cSelect, r] = imfindcircles(BW,[25 35],'Sensitivity', 0.9, 'EdgeThreshold', 0.2);
        end
    end
end
viscircles(cBall(1,:), r(1),'Color',[0.8500 0.3250 0.0980],'LineWidth',3,'LineStyle',':');

CueBallx=cSelect(1);
CueBally=cSelect(2);
end
function [robotNextShot]=DrawShot(shotNum)
global Shots pocket color ballRad xCrop yCrop bumper_w
title([num2str(Shots.XYZOATs(1,1)) ' ' num2str(Shots.XYZOATs(1,2)) ' ' num2str(Shots.XYZOATs(1,3)) ' ' num2str(Shots.XYZOATs(1,4)) ' ' num2str(Shots.XYZOATs(1,5)) ' ' num2str(Shots.XYZOATs(1,6))]);
line([ballRad+bumper_w,ballRad+bumper_w],[ballRad+bumper_w ,yCrop-ballRad-bumper_w],'Color', 'w','LineWidth', 1);
line([xCrop-ballRad-bumper_w,xCrop-ballRad-bumper_w],[ballRad+bumper_w ,yCrop-ballRad-bumper_w],'Color', 'w','LineWidth', 1);
line([ballRad+bumper_w,xCrop-ballRad-bumper_w],[ballRad+bumper_w ,ballRad+bumper_w],'Color', 'w','LineWidth', 1);
line([ballRad+bumper_w,xCrop-ballRad-bumper_w],[yCrop-ballRad-bumper_w ,yCrop-ballRad-bumper_w],'Color', 'w','LineWidth', 1);
for i=1:6
    viscircles(pocket(i,:), ballRad*2, 'Color', color{i}, 'LineStyle', '-.');
end
line(Shots.Draw1_1(shotNum,:),Shots.Draw1_2(shotNum,:),'Color',Shots.Color(shotNum,:),'LineWidth',2);
viscircles(Shots.Draw2_1(shotNum,:) , ballRad, 'Color', Shots.Color(shotNum,:), 'LineStyle', '-.');
line(Shots.Draw3_1(shotNum,:), Shots.Draw3_2(shotNum,:),'Color', Shots.Color(shotNum,:),'LineWidth',2);
line(Shots.Draw4_1(shotNum,:),Shots.Draw4_2(shotNum,:),'Color',Shots.Color(shotNum,:),'LineWidth',2);
hold off;

robotNextShot=Shots.XYZOATs(shotNum,:);
end
