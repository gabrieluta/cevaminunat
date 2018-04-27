from __future__ import print_function

import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.optimizers import RMSprop
from keras.utils import np_utils
from keras.layers import Dense, Flatten
from keras.layers import Conv2D, MaxPooling2D

import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import os
import theano
from PIL import Image
from numpy import *



class AccuracyHistory(keras.callbacks.Callback):
    def on_train_begin(self, logs={}):
        self.acc = []

    def on_epoch_end(self, batch, logs={}):
        self.acc.append(logs.get('acc'))

#model statics
batch_size = 64
epochs = 10

#image info
img_rows, img_cols = 32, 32
channels = 3

#train data
train_path = "/Users/gabrielad/Desktop/train/"

image_list = os.listdir(train_path)
image_data = [(Image.open(train_path + image)).getdata() for image in image_list if image != '.DS_Store']
labels_data = [image.replace('.png', '') for image in image_list]

train_data = np.asarray(image_data)
train_labels = np.asarray(labels_data)

#validation data
validation_path = "/Users/gabrielad/Desktop/validation/"

image_list = os.listdir(validation_path)
image_data = [(Image.open(validation_path + image)).getdata() for image in image_list if image != '.DS_Store']
labels_data = [image.replace('.png', '') for image in image_list]

validation_data = np.asarray(image_data)
validation_labels = np.asarray(labels_data)

#model construction
model = Sequential()
model.add(Conv2D(96, kernel_size=(7, 7), strides=(1, 1), activation='relu', input_shape=(img_rows, img_cols, channels)))
model.add(MaxPooling2D(pool_size=(2, 2), strides=(2, 2)))
model.add(Conv2D(256, kernel_size=(5, 5), strides=(1, 1), activation='relu', input_shape=(img_rows, img_cols, channels)))
model.add(MaxPooling2D(pool_size=(2, 2), strides=(2, 2)))
model.add(Flatten())
model.add(Dense(1024, activation='relu'))
model.add(Dense(71, activation='softmax'))

#model compilation
model.compile(loss=keras.losses.categorical_crossentropy,
              optimizer=keras.optimizers.Adam(),
              metrics=['accuracy'])

#model fit train data
history = AccuracyHistory()

model.fit(train_data, train_labels,
          batch_size=batch_size,
          epochs=epochs,
          verbose=1,
          validation_data=(validation_data, validation_labels),
          callbacks=[history])

#seed
score = model.evaluate(validation_data, validation_labels, verbose=0)
print('Test loss:', score[0])
print('Test accuracy:', score[1])
plt.plot(range(1, 11), history.acc)
plt.xlabel('Epochs')
plt.ylabel('Accuracy')
plt.show()
