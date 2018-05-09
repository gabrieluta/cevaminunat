import os
from keras.models import *
from keras.layers import Input, Concatenate, Conv2D, MaxPooling2D, UpSampling2D, Dropout, Cropping2D
from keras.optimizers import *
from keras.callbacks import ModelCheckpoint, LearningRateScheduler
from keras import backend as keras
from keras.preprocessing.image import img_to_array, load_img

import numpy as np
import os
from PIL import Image
from numpy import *


class myUnet(object):

    def __init__(self, img_rows=512, img_cols=512):
        self.img_rows = img_rows
        self.img_cols = img_cols



    def load_data(self):

        train_path = "/usr/local/blurred_sharp/blurred/"
        image_list = sorted(os.listdir(train_path))[:100]
        imgs_train = [img_to_array(load_img(train_path + image).resize((512, 512), Image.ANTIALIAS)) for image in image_list]
        imgs_train = np.asarray(imgs_train)

        mask_path = "/usr/local/blurred_sharp/sharp/"
        image_list = sorted(os.listdir(mask_path))[:100]
        imgs_mask_train = [img_to_array(load_img(mask_path + image).resize((512, 512), Image.ANTIALIAS)) for image in image_list]
        imgs_mask_train = np.asarray(imgs_mask_train)

        # test_path = "/usr/local/blurred_sharp/blurred/"
        # image_list = sorted(os.listdir(test_path))
        # imgs_test = [img_to_array(load_img(test_path + image)) for image in image_list]
        # imgs_test = np.asarray(imgs_test)
        imgs_test = imgs_train

        return imgs_train, imgs_mask_train, imgs_test

    def get_unet(self):
        inputs = Input((self.img_rows, self.img_cols, 3))

        conv1 = Conv2D(64, 3, activation='relu', padding='same', kernel_initializer='he_normal')(inputs)
        print("conv1 shape:",conv1.shape)
        conv1 = Conv2D(64, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv1)
        print("conv1 shape:",conv1.shape)
        pool1 = MaxPooling2D(pool_size=(2, 2))(conv1)
        print("pool1 shape:",pool1.shape)

        conv2 = Conv2D(128, 3, activation='relu', padding='same', kernel_initializer='he_normal')(pool1)
        print("conv2 shape:",conv2.shape)
        conv2 = Conv2D(128, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv2)
        print("conv2 shape:",conv2.shape)
        pool2 = MaxPooling2D(pool_size=(2, 2))(conv2)
        print("pool2 shape:",pool2.shape)

        conv3 = Conv2D(256, 3, activation='relu', padding='same', kernel_initializer='he_normal')(pool2)
        print("conv3 shape:",conv3.shape)
        conv3 = Conv2D(256, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv3)
        print("conv3 shape:",conv3.shape)
        pool3 = MaxPooling2D(pool_size=(2, 2))(conv3)
        print("pool3 shape:",pool3.shape)

        conv4 = Conv2D(512, 3, activation='relu', padding='same', kernel_initializer='he_normal')(pool3)
        print ("conv4 shape:", conv4.shape)
        conv4 = Conv2D(512, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv4)
        print ("conv4 shape:",conv4.shape)

        drop4 = Dropout(0.5)(conv4)
        print ("drop4 shape:", drop4.shape)
        pool4 = MaxPooling2D(pool_size=(2, 2))(drop4)
        print ("pool4 shape:", pool4.shape)

        conv5 = Conv2D(1024, 3, activation='relu', padding='same', kernel_initializer='he_normal')(pool4)
        print ("conv5 shape:", conv5.shape)
        conv5 = Conv2D(1024, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv5)
        print ("conv5 shape:", conv5.shape)

        drop5 = Dropout(0.5)(conv5)
        print ("drop5 shape:", drop5.shape)

        # concat = Concatenate(axis=3)
        up6 = Conv2D(512, 2, activation='relu', padding='same', kernel_initializer='he_normal')(
            UpSampling2D(size=(2, 2))(drop5))
        print ("up6 shape:", up6.shape)
        merge6 = Concatenate(axis=3)([drop4, up6])
        print ("merge6 shape:", merge6.shape)
        conv6 = Conv2D(512, 3, activation='relu', padding='same', kernel_initializer='he_normal')(merge6)
        print ("conv6 shape:", conv6.shape)
        conv6 = Conv2D(512, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv6)
        print ("conv6 shape:", conv6.shape)

        up7 = Conv2D(256, 2, activation='relu', padding='same', kernel_initializer='he_normal')(
            UpSampling2D(size=(2, 2))(conv6))
        print ("up7 shape:", up7.shape)
        merge7 = Concatenate(axis=3)([conv3, up7])
        print ("merge7 shape:", merge7.shape)
        conv7 = Conv2D(256, 3, activation='relu', padding='same', kernel_initializer='he_normal')(merge7)
        print ("conv7 shape:", conv7.shape)
        conv7 = Conv2D(256, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv7)
        print ("conv7 shape:", conv7.shape)

        up8 = Conv2D(128, 2, activation='relu', padding='same', kernel_initializer='he_normal')(
            UpSampling2D(size=(2, 2))(conv7))
        print ("up8 shape:", up8.shape)
        merge8 = Concatenate(axis=3)([conv2, up8])
        print ("merge8 shape:", merge8.shape)
        conv8 = Conv2D(128, 3, activation='relu', padding='same', kernel_initializer='he_normal')(merge8)
        print ("conv8 shape:", conv8.shape)
        conv8 = Conv2D(128, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv8)
        print ("conv8 shape:", conv8.shape)

        up9 = Conv2D(64, 2, activation='relu', padding='same', kernel_initializer='he_normal')(
            UpSampling2D(size=(2, 2))(conv8))
        print ("up9 shape:", up9.shape)
        merge9 = Concatenate(axis=3)([conv1, up9])
        print ("merge9 shape:", merge9.shape)
        conv9 = Conv2D(64, 3, activation='relu', padding='same', kernel_initializer='he_normal')(merge9)
        print ("conv9 shape:", conv9.shape)
        conv9 = Conv2D(64, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv9)
        print ("conv9 shape:", conv9.shape)
        # conv9 = Conv2D(2, 3, activation='relu', padding='same', kernel_initializer='he_normal')(conv9)
        # print ("conv9 shape:", conv9.shape)
        conv10 = Conv2D(3, 1, activation='sigmoid')(conv9)
        print ("conv10 shape:", conv10.shape)

        model = Model(inputs=inputs, outputs=conv10)

        model.compile(optimizer=Adam(lr=1e-4), loss='binary_crossentropy', metrics=['mse'])

        return model

    def train(self):
        print("loading data")
        imgs_train, imgs_mask_train, imgs_test = self.load_data()
        print("loading data done")
        model = self.get_unet()
        print("got unet")

        model_checkpoint = ModelCheckpoint('unet.hdf5', monitor='loss', verbose=1, save_best_only=True)
        print('Fitting model...')
        model.fit(imgs_train, imgs_mask_train, batch_size=4, epochs=10, verbose=1, validation_split=0.2, shuffle=True,
                  callbacks=[model_checkpoint])

        print('predict test data')
        imgs_mask_test = model.predict(imgs_test, batch_size=1, verbose=1)
        np.save('/usr/local/results/imgs_mask_test.npy', imgs_mask_test)

    def save_img(self):
        print("array to image")
        imgs = np.load('/usr/local/results/imgs_mask_test.npy')

        for i in range(imgs.shape[0]):
            img = imgs[i]
            img = array_to_img(img)
            img.save("/usr/local/results/%d.jpg" % (i))


if __name__ == '__main__':
    myunet = myUnet()
    myunet.train()
    myunet.save_img()
