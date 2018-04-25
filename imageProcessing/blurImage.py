import cv2
import numpy as np
import os
from os import listdir
from os import walk
import matplotlib.pyplot as plt
import math
from PIL import Image
import scipy.misc

# import LinearMotionBlur
from scipy.signal import convolve2d

path = "/Users/gabrielad/cevaminunat/imageProcessing/images/"
blurredpath = "/Users/gabrielad/cevaminunat/imageProcessing/blurred_images/"
orientations3 = [0, 45, 90, 135]
orientations = [0, 30, 60, 90, 120, 150]
# 1 doesn't count because it will correspond to identity kernel
lengths = [5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25]


def generate_LO():
    LO = []
    # append the identity LO
    LO.append((1, 0))
    for o in orientations3:
        LO.append((3, o))
    for o in orientations:
        for l in lengths:
            LO.append((l, o))

    return LO

def generate_kernel(dim, length, orientation):

    dim = length
    cos = math.cos(math.radians(orientation))
    sin = math.sin(math.radians(orientation))
    xP1 = 0
    yP1 = 0
    xP2 = xP1 + length * cos
    yP2 = yP1 + length * sin


    xTP1 = int(xP1 + (dim - length * cos)/2)
    yTP1 = int(yP1 + (dim - length * sin)/2)

    xTP2 = int(xP2 + (dim - length * cos)/2)
    yTP2 = int(yP2 + (dim - length * sin)/2)

    # Create a black image
    img = np.zeros((dim , dim), np.uint8)
    cv2.line(img, (xTP1, dim - 1 - yTP1), (xTP2, dim - 1 - yTP2), (1, 1, 1), 1)

    kernelimage = np.zeros((dim , dim, 3), np.uint8)
    cv2.line(kernelimage, (xTP1, dim - 1 - yTP1), (xTP2, dim - 1 - yTP2), (255, 255, 255), 1)
    #
    # plt.subplot(132), plt.imshow(kernelimage), plt.title('kernel image')
    # plt.xticks([]), plt.yticks([])

    kernel = np.array(img)
    kernel = kernel/dim
    return kernel


def crop_image(im, width, height, l, o, k):
    imgwidth, imgheight = im.size
    for i in range(0, imgheight, height):
        for j in range(0, imgwidth, width):
            box = (j, i, j + width, i + height)
            a = im.crop(box)
            save_image(a, l, o, k)
            k += 1

def save_image(image, l, o, k):
    image_name = '({0},{1}){2}.jpg'.format(str(l), str(o), k)
    scipy.misc.imsave(blurredpath + image_name, image)


def main():
    k=1
    f = []
    for (dirpath, dirnames, filenames) in walk(path):
        f.extend(filenames)
        break
    f.remove('.DS_Store')
    for imagepath in f:

        image = cv2.imread(path + imagepath)
        LO = generate_LO()

        for (l, o) in LO:
            # plt.subplot(131), plt.imshow(image), plt.title('Original')
            # plt.xticks([]), plt.yticks([])

            dim = 0
            kernel = generate_kernel(dim, l, o)
            blurredimage = cv2.filter2D(image, -1, kernel)

            img = Image.fromarray(blurredimage, 'RGB')
            save_image(img, l, o, k)
            k+=1
            # crop_image(img, 30, 30, l , o, k)
            # plt.subplot(133), plt.imshow(blurredimage), plt.title('Blurred')
            # plt.xticks([]), plt.yticks([])
            # plt.show()




if __name__ == "__main__":
    main()