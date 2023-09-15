import cv2
import numpy as np

################################################
####### Remove Barrel Distortion ###############
################################################

image_name = 'right.png'

src    = cv2.imread(image_name)
width  = src.shape[1]
height = src.shape[0]

cv2.imshow('frame', src)
cv2.waitKey(0)

distCoeff = np.zeros((4,1),np.float64)

k1 = -.7e-5; # negative to remove barrel distortion
k2 = 0.0;
p1 = 0.0;
p2 = 0.0;

distCoeff[0,0] = k1;
distCoeff[1,0] = k2;
distCoeff[2,0] = p1;
distCoeff[3,0] = p2;

cam = np.eye(3,dtype=np.float32)

cam[0,2] = width/2.0  #centerx
cam[1,2] = height/2.0 #centery
cam[0,0] = 10. #flength x
cam[1,1] = 10. #flength y

# here the undistortion will be computed
dst = cv2.undistort(src,cam,distCoeff)

cv2.imshow('dst',dst)
cv2.waitKey(0)
cv2.destroyAllWindows()
cv2.imwrite('./dst_'+ image_name, dst)


################################################
##########      BIRDS EYE VIEW      ############
################################################
