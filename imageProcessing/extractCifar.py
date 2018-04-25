import mxnet as mx
import numpy as np
import pickle
import cv2

def extractImagesAndLabels(path, file):
    f = open(path+file, 'rb')
    dict = pickle.load(f, encoding='bytes')
    images = dict[b'data']
    images = np.reshape(images, (10000, 3, 32, 32))
    labels = dict[b'labels']
    imagearray = mx.nd.array(images)
    labelarray = mx.nd.array(labels)
    return imagearray, labelarray

def extractCategories(path, file):
    f = open(path+file, 'rb')
    dict = pickle.load(f)
    return dict['label_names']

def saveCifarImage(array, path, file):
    # array is 3x32x32. cv2 needs 32x32x3
    array = array.asnumpy().transpose(1,2,0)
    # array is RGB. cv2 needs BGR
    array = cv2.cvtColor(array, cv2.COLOR_RGB2BGR)
    # save to PNG file
    return cv2.imwrite(path+file+".png", array)

imgarray, lblarray = extractImagesAndLabels("/Users/gabrielad/cevaminunat/imageProcessing/", "data_batch_1")
# print(imgarray.shape)
# print(lblarray.shape)

categories = extractCategories("/Users/gabrielad/cevaminunat/imageProcessing/", "batches.meta")

cats = []
for i in range(0,10000):
    saveCifarImage(imgarray[i], "/Users/gabrielad/cevaminunat/imageProcessing/images/", "image"+(str)(i))
    category = lblarray[i].asnumpy()
    category = (int)(category[0])
    cats.append(categories[category])
# print(cats)