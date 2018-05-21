from keras.models import *
from keras.layers import Input, Concatenate, Conv2DTranspose, Conv2D, MaxPooling2D, UpSampling2D, Dropout, Cropping2D, Activation, Add
from keras.optimizers import *
from keras.callbacks import ModelCheckpoint, LearningRateScheduler
from keras import backend as keras
from keras.preprocessing.image import img_to_array, load_img
from keras.engine import Layer, InputSpec
from keras import regularizers, initializers, constraints
from keras.utils.generic_utils import get_custom_objects
from keras.layers.normalization import BatchNormalization
from keras.layers.core import Dense, Flatten, Lambda
from keras.utils import conv_utils
import keras.backend as K
from keras.applications.vgg16 import VGG16
from keras.models import Model
from keras.layers.advanced_activations import LeakyReLU
from utils import ReflectionPadding2D

import numpy as np
import os
from PIL import Image
from numpy import *


def generator_model():

    # inputs = Input((256, 256, 3))
    #
    # conv1 = ReflectionPadding2D((3, 3))(inputs)
    #
    # conv1 = Conv2D(64, 7, padding='valid', strides=(1, 1))(conv1)
    # # print("conv1 shape:", conv1.shape)
    # instanceN1 = BatchNormalization()(conv1)
    # # instanceN1 = InstanceNormalization(epsilon=0.1, gamma_regularizer=regularizers.l2(0.01), beta_regularizer=regularizers.l2(0.01))(conv1)
    # relu1 = Activation('relu')(instanceN1)
    #
    # conv2 = Conv2D(128, 3, padding='same', strides=(2, 2))(relu1)
    # # print("conv2 shape:", conv2.shape)
    # instanceN2 = BatchNormalization()(conv2)
    # # instanceN2 = InstanceNormalization(epsilon=0.1, gamma_regularizer=regularizers.l2(0.01), beta_regularizer=regularizers.l2(0.01))(conv2)
    # relu2 = Activation('relu')(instanceN2)
    #
    # conv3 = Conv2D(256, 3, padding='same', strides=(2, 2))(relu2)
    # # print("conv3 shape:", conv3.shape)
    # instanceN3 = BatchNormalization()(conv3)
    # # instanceN3 = InstanceNormalization(epsilon=0.1, gamma_regularizer=regularizers.l2(0.01), beta_regularizer=regularizers.l2(0.01))(conv3)
    # relu3 = Activation('relu')(instanceN3)
    #
    # x = relu3
    n_blocks_gen = 9
    # print("res: ", x)

    inputs = Input((256, 256, 3))

    x = ReflectionPadding2D((3, 3))(inputs)
    x = Conv2D(filters=64, kernel_size=(7, 7), padding='valid')(x)
    x = BatchNormalization()(x)
    x = Activation('relu')(x)

    n_downsampling = 2
    for i in range(n_downsampling):
        mult = 2 ** i
        x = Conv2D(filters=64 * mult * 2, kernel_size=(3, 3), strides=2, padding='same')(x)
        x = BatchNormalization()(x)
        x = Activation('relu')(x)

    mult = 2 ** n_downsampling
    for i in range(n_blocks_gen):
        input = x
        # res = self.res_block(res, 256, use_dropout=True)
        filters = 256
        kernel_size = (3, 3)
        strides = (1, 1)
        x = ReflectionPadding2D()(input)
        x = Conv2D(filters=filters,
                   kernel_size=kernel_size,
                   strides=strides, )(x)

        x = BatchNormalization()(x)
        x = Activation('relu')(x)

        # if use_dropout:
        x = Dropout(0.5)(x)

        x = ReflectionPadding2D()(x)
        x = Conv2D(filters=filters,
                   kernel_size=kernel_size,
                   strides=strides, )(x)

        x = BatchNormalization()(x)

        # Two convolution layers followed by a direct connection between input and output
        x = Add()([input, x])

    for i in range(2):
        mult = 2 ** (2 - i)
        x = Conv2DTranspose(filters=int(64 * mult / 2), kernel_size=(3, 3), strides=2, padding='same')(x)
        x = BatchNormalization()(x)
        x = Activation('relu')(x)

    x = ReflectionPadding2D((3, 3))(x)
    x = Conv2D(filters=3, kernel_size=(7, 7), padding='valid')(x)
    x = Activation('tanh')(x)

    outputs = Add()([x, inputs])
    # outputs = Lambda(lambda z: K.clip(z, -1, 1))(x)
    outputs = Lambda(lambda z: z / 2)(outputs)

    model = Model(inputs=inputs, outputs=outputs, name='Generator')
    return model
    # conv4 = Conv2DTranspose(filters=int(128), kernel_size=(3, 3), strides=(2, 2), padding='same')(x)
    # instanceN4 = BatchNormalization()(conv4)
    # relu4 = Activation('relu')(instanceN4)
    #
    # conv5 = Conv2DTranspose(filters=int(64), kernel_size=(3, 3), strides=(2, 2), padding='same')(relu4)
    # instanceN5 = BatchNormalization()(conv5)
    # relu5 = Activation('relu')(instanceN5)
    #
    # padd6 = ReflectionPadding2D((3, 3))(relu5)
    # conv6 = Conv2D(filters=3, kernel_size=(7, 7), padding='valid')(padd6)
    # tan6 = Activation('tanh')(conv6)
    #
    # outputs = Add()([tan6, inputs])
    # # outputs = Lambda(lambda z: K.clip(z, -1, 1))(x)
    # outputs = Lambda(lambda z: z / 2)(outputs)
    #
    # model = Model(inputs=inputs, outputs=outputs, name='Generator')
    # # model.compile(optimizer=Adam(lr=1e-4), loss=[perceptual_loss])
    #
    # return model


def discriminator_model():
    n_layers, use_sigmoid = 3, False
    inputs = Input((256, 256, 3))

    x = Conv2D(filters=64, kernel_size=(4, 4), strides=2, padding='same')(inputs)
    x = LeakyReLU(0.2)(x)

    nf_mult, nf_mult_prev = 1, 1
    for n in range(n_layers):
        nf_mult_prev, nf_mult = nf_mult, min(2 ** n, 8)
        x = Conv2D(filters=64 * nf_mult, kernel_size=(4, 4), strides=2, padding='same')(x)
        x = BatchNormalization()(x)
        x = LeakyReLU(0.2)(x)

    nf_mult_prev, nf_mult = nf_mult, min(2 ** n_layers, 8)
    x = Conv2D(filters=64 * nf_mult, kernel_size=(4, 4), strides=1, padding='same')(x)
    x = BatchNormalization()(x)
    x = LeakyReLU(0.2)(x)

    x = Conv2D(filters=1, kernel_size=(4, 4), strides=1, padding='same')(x)
    if use_sigmoid:
        x = Activation('sigmoid')(x)

    x = Flatten()(x)
    x = Dense(1024, activation='tanh')(x)
    x = Dense(1, activation='sigmoid')(x)

    model = Model(inputs=inputs, outputs=x, name='Discriminator')
    return model


def generator_containing_discriminator(generator, discriminator):
    inputs = Input((256, 256, 3))
    generated_image = generator(inputs)
    outputs = discriminator(generated_image)
    model = Model(inputs=inputs, outputs=outputs)
    return model


def generator_containing_discriminator_multiple_outputs(generator, discriminator):
    inputs = Input((256, 256, 3))
    generated_image = generator(inputs)
    outputs = discriminator(generated_image)
    model = Model(inputs=inputs, outputs=[generated_image, outputs])
    return model


if __name__ == '__main__':
    g = generator_model()
    g.summary()
    d = discriminator_model()
    d.summary()
    m = generator_containing_discriminator(generator_model(), discriminator_model())
    m.summary()