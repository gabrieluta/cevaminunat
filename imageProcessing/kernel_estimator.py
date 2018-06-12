import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.optimizers import RMSprop
from keras.utils import np_utils
from keras.layers import Dense, Flatten
from keras.layers import Conv2D, MaxPooling2D
from keras.preprocessing.image import img_to_array, load_img
from keras.utils import multi_gpu_model
from keras.utils import np_utils
from sklearn.utils import shuffle
from sklearn.model_selection import train_test_split
from keras.callbacks import EarlyStopping
from keras import callbacks
from keras import backend as k

import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import os
from PIL import Image
from numpy import *

#
# def log10(x):
#     numerator = log(x)
#     denominator = log(constant(10, dtype=numerator.dtype))
#
#     return numerator / denominator
#
#
# def perceptual_loss(y_true, y_pred):
#     vgg19 = VGG19(include_top=False, weights='imagenet', input_shape=(256, 256, 3))
#     model = Model(vgg19.input, vgg19.get_layer('block3_conv3').output)
#     model.trainable = False
#
#     return mean(square(model(y_true) - model(y_pred)))
#
#
# def wasserstein_loss(y_true, y_pred):
#     return mean(y_true * y_pred)
#
#
# def PSNR(y_true, y_pred):
#     r = 255
#     mse = mean_squared_error(y_true, y_pred)
#
#     return 10 * log10(r * r / mse)
#
#
# def SSIM(y_true, y_pred):
#     # DSSIM = (1 - SSIM) / 2 => SSIM = 1 - 2 * DSSIM
#     dssim = DSSIMObjective()
#     return 1 - 2 * dssim(y_true, y_pred)


class AccuracyHistory(keras.callbacks.Callback):
    def on_train_begin(self, logs={}):
        self.acc = []

    def on_epoch_end(self, batch, logs={}):
        self.acc.append(logs.get('acc'))


# batch_size = 64
batch_size = 10
epochs = 10

# image info
img_rows, img_cols = 32, 32
channels = 3

data_path = "/data/image_deblurring/kernel_estimator/train_less/"

image_list = os.listdir(data_path)
image_data = [img_to_array(load_img(data_path + image)) for image in image_list]
data = np.asarray(image_data)
data = data.astype('float32')
data /= 255

labels_aux = [float((image.split(')', 1)[0].split('(', 1)[-1]).replace(',', '.')) for image in image_list]

labels_data = []
for label in labels_aux:
  if label == 1.0:
    labels_data.append(0)
  if label == 3.0:
    labels_data.append(1)
  if label == 3.45:
    labels_data.append(2)
  if label == 3.90:
    labels_data.append(3)
  if label == 3.135:
    labels_data.append(4)
  if label == 5.0:
    labels_data.append(5)
  if label == 5.30:
    labels_data.append(6)
  if label == 5.60:
    labels_data.append(7)
  if label == 5.90:
    labels_data.append(8)
  if label == 5.120:
    labels_data.append(9)
  if label == 5.150:
    labels_data.append(10)
  if label == 7.0:
    labels_data.append(11)
  if label == 7.30:
    labels_data.append(12)
  if label == 7.60:
    labels_data.append(13)
  if label == 7.90:
    labels_data.append(14)
  if label == 7.120:
    labels_data.append(15)
  if label == 7.150:
    labels_data.append(16)
  if label == 9.0:
    labels_data.append(17)
  if label == 9.30:
    labels_data.append(18)
  if label == 9.60:
    labels_data.append(19)
  if label == 9.90:
    labels_data.append(20)
  if label == 9.120:
    labels_data.append(21)
  if label == 9.150:
    labels_data.append(22)
  if label == 11.0:
    labels_data.append(23)
  if label == 11.30:
    labels_data.append(24)
  if label == 11.60:
    labels_data.append(25)
  if label == 11.90:
    labels_data.append(26)
  if label == 11.120:
    labels_data.append(27)
  if label == 11.150:
    labels_data.append(28)
  if label == 13.0:
    labels_data.append(29)
  if label == 13.30:
    labels_data.append(30)
  if label == 13.60:
    labels_data.append(31)
  if label == 13.90:
    labels_data.append(32)
  if label == 13.120:
    labels_data.append(33)
  if label == 13.150:
    labels_data.append(34)
  if label == 15.0:
    labels_data.append(35)
  if label == 15.30:
    labels_data.append(36)
  if label == 15.60:
    labels_data.append(37)
  if label == 15.90:
    labels_data.append(38)
  if label == 15.120:
    labels_data.append(39)
  if label == 15.150:
    labels_data.append(40)
  if label == 17.0:
    labels_data.append(41)
  if label == 17.30:
    labels_data.append(42)
  if label == 17.60:
    labels_data.append(43)
  if label == 17.90:
    labels_data.append(44)
  if label == 17.120:
    labels_data.append(45)
  if label == 17.150:
    labels_data.append(46)
  if label == 19.0:
    labels_data.append(47)
  if label == 19.30:
    labels_data.append(48)
  if label == 19.60:
    labels_data.append(49)
  if label == 19.90:
    labels_data.append(50)
  if label == 19.120:
    labels_data.append(51)
  if label == 19.150:
    labels_data.append(52)
  if label == 21.0:
    labels_data.append(53)
  if label == 21.30:
    labels_data.append(54)
  if label == 21.60:
    labels_data.append(55)
  if label == 21.90:
    labels_data.append(56)
  if label == 21.120:
    labels_data.append(57)
  if label == 21.150:
    labels_data.append(58)
  if label == 25.0:
    labels_data.append(59)
  if label == 25.30:
    labels_data.append(60)
  if label == 25.60:
    labels_data.append(61)
  if label == 25.90:
    labels_data.append(62)
  if label == 25.120:
    labels_data.append(63)
  if label == 25.150:
    labels_data.append(64)
  if label == 23.0:
    labels_data.append(65)
  if label == 23.30:
    labels_data.append(66)
  if label == 23.60:
    labels_data.append(67)
  if label == 23.90:
    labels_data.append(68)
  if label == 23.120:
    labels_data.append(69)
  if label == 23.150:
    labels_data.append(70)

# labels[:] = 0

labels = np.asarray(labels_data, dtype='int64')
labels = np_utils.to_categorical(labels, 71)

data, labels = shuffle(data, labels, random_state=2)

# Split the dataset
train_data, test_data, train_labels, test_labels = train_test_split(data, labels, test_size=0.2, random_state=2)

# model construction
model = Sequential()
model.add(Conv2D(96, kernel_size=(7, 7), activation='relu', input_shape=(img_rows, img_cols, channels)))
model.add(MaxPooling2D(pool_size=(2, 2), strides=(2, 2)))
model.add(Conv2D(256, kernel_size=(5, 5), activation='relu', input_shape=(img_rows, img_cols, channels)))
model.add(MaxPooling2D(pool_size=(2, 2), strides=(2, 2)))
model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(1024, activation='relu'))
model.add(Dropout(0.2))
model.add(Dense(71, activation='softmax'))

model = multi_gpu_model(model, gpus=4)

# model compilation
model.compile(loss='categorical_crossentropy',
              optimizer=keras.optimizers.Adam(),
              metrics=['accuracy'])

# model fit train data
history = AccuracyHistory()

score1 = model.fit(train_data,
                   train_labels,
                   batch_size=batch_size,
                   epochs=epochs,
                   verbose=1,
                   validation_data= (test_data, test_labels),
                   callbacks=[history])

filename='model_train_new.csv'
csv_log=callbacks.CSVLogger(filename, separator=',', append=False)

early_stopping=callbacks.EarlyStopping(monitor='val_loss', min_delta=0, patience=0, verbose=0, mode='min')

filepath = "/data/image_deblurring/kernel_estimator/"

checkpoint = callbacks.ModelCheckpoint(filepath, monitor='val_loss', verbose=1, save_best_only=True, mode='min')

# tensorboard callback
tensorboard_callback = k.callbacks.TensorBoard(log_dir='./logs', histogram_freq=0, batch_size=32, write_graph=True, write_grads=False, write_images=False, embeddings_freq=0, embeddings_layer_names=None, embeddings_metadata=None)

callbacks_list = [csv_log,early_stopping,checkpoint, tensorboard_callback]


score = model.evaluate(test_data, test_labels, show_accuracy=True, verbose=0)
print('Test Loss:', score[0])
print('Test accuracy:', score[1])

test_image = test_data[0:1]
print(test_image.shape)

print(model.predict(test_image))
print(model.predict_classes(test_image))
print(test_labels[0:1])

# Save our model here
file = open(filepath+"motionblur.h5", 'a')
model.save(filepath+"motionblur.h5")
file.close()