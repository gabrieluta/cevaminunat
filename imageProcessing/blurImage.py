import cv2
import numpy as np
import os
from os import listdir
from os import walk
import matplotlib.pyplot as plt
import math

path = "/Users/gabrielad/cevaminunat/imageProcessing/images/"
dim_kernel = 9
orientations = [0, 30, 60, 90, 120, 150]
# 1 doesn't count because it will correspond to identity kernel
lengths = [3, 5, 7, 9]
           # 11, 13, 15, 17, 19, 21, 23, 25]

def generate_LO():
    LO = []
    # append the identity LO
    LO.append((1, 0))
    for o in orientations:
        for l in lengths:
            LO.append((l, o))

    return LO

def generate_kernel(dim, length, orientation):

    cos = math.cos(math.radians(orientation))
    sin = math.sin(math.radians(orientation))

    xP1 = 0
    yP1 = 0
    xP2 = int(math.ceil(xP1 + (length) * cos))
    yP2 = int(math.ceil(yP1 + (length) * sin))

    if orientation == 90:
        yP2 = yP2 - 1
    if orientation == 0:
        xP2 = xP2 - 1

    xTP1 = int(xP1 + (dim - length * cos)/2)
    yTP1 = int(yP1 + (dim - length * sin)/2)
    if (xTP1 > dim - 1):
        xTP1 = abs(dim - 1 - xTP1)
    if (yTP1 > dim - 1):
        yTP1 = abs(dim - 1 - yTP1)

    xTP2 = int(xP2 + (dim - length * cos)/2)
    yTP2 = int(yP2 + (dim - length * sin)/2)

    if (xTP2 > dim - 1):
        xTP2 = abs(dim - 1 - xTP2)
    if (yTP2 > dim - 1):
        yTP2 = abs(dim - 1 - yTP2)

    # Create a black image
    img = np.zeros((dim , dim), np.uint8)
    cv2.line(img, (xTP1, dim - 1 - yTP1), (xTP2, dim - 1 - yTP2), (1, 1, 1), 1)

    kernelimage = np.zeros((dim , dim, 3), np.uint8)
    cv2.line(kernelimage, (xTP1, dim - 1 - yTP1), (xTP2, dim - 1 - yTP2), (255, 255, 255), 1)

    plt.subplot(132), plt.imshow(kernelimage), plt.title('kernel image')
    plt.xticks([]), plt.yticks([])

    kernel = np.array(img)
    kernel = kernel/dim
    print(kernel)
    return kernel

def pretty_print(kernel, dim):

    final_string = "("
    for index, item in enumerate(kernel):
        if index == len(kernel) - 1:
            final_string += str(item) + ")"
        elif (index + 1) % dim == 0:
            final_string += str(item) + ";"
        else:
            final_string += str(item) + ","

    return final_string


def main():

    f = []
    for (dirpath, dirnames, filenames) in walk(path):
        f.extend(filenames)
        break

    for imagepath in f:

        image = cv2.imread(path + imagepath)
        dim = dim_kernel
        LO = generate_LO()

        for (l, o) in LO:
            plt.subplot(131), plt.imshow(image), plt.title('Original')
            plt.xticks([]), plt.yticks([])

            kernel = generate_kernel(dim, l, o)

            blurredimage = cv2.filter2D(image, -1, kernel)
            plt.subplot(133), plt.imshow(blurredimage), plt.title('Blurred')
            plt.xticks([]), plt.yticks([])
            plt.show()


if __name__ == "__main__":
    main()