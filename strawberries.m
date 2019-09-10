 clc
 clear all
 close all
 im1=imread('C:\Users\Finn\Dropbox\THIRD YEAR\METR4202\Sandbox\images\Simple19.png');
 figure(1);
 imshow(im1)
 im2 = rgb2gray(im1);
 [counts, locations] = imhist(im2)
 threshold = thresh(counts);
 %threshold = (t/256);
 %im2 = histeq(im2);
 figure(2);
 imshow(im2);
 im = edge(im2, 'canny', threshold);
 figure(3);
 imshow(im);
 
 se = strel('disk', 5,0);
 im = imdilate(im,se);
 figure; imshow(im)
 im = imerode(im,se);
 figure; imshow(im)
 im = imfill(im,'holes');
 figure; imshow(im)

 
 
%  [im, radii] = imfindcircles(im, [1,100]);
%  figure; imshow(im);
%  viscircles(im, radii,'Color','b');
%  
%  [H,T,R] = hough(im,'RhoResolution',0.5,'Theta',-90:0.5:89.5);
%  figure; imshow(imadjust(rescale(H)),'XData',T,'YData',R,'InitialMagnification','fit');
%  
 %im = imerode(im,se)
 %figure; imshow(im)
%  im2 = imfill(im);
%  figure; imshow(im2)