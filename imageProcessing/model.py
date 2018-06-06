from keras.layers import Input, Conv2DTranspose, Conv2D, Dropout, Activation, Add
from keras.layers.core import Dense, Flatten, Lambda
from keras.models import Model
from keras.layers.advanced_activations import LeakyReLU
from utils import ReflectionPadding2D
from keras_contrib.layers.normalization import InstanceNormalization
from keras.utils import multi_gpu_model

import numpy as np
import os
from PIL import Image
from numpy import *

inputs = Input((256, 256, 3))
res_blocks = 9


def lambda_function(x):
    return x / 2

def generator():
    x = ReflectionPadding2D((3, 3))(inputs)
    x = Conv2D(filters=64, kernel_size=(7, 7), padding='valid')(x)
    x = InstanceNormalization()(x)
    x = Activation('relu')(x)

    n_downsampling = 2
    for i in range(n_downsampling):
        mult = 2 ** i
        x = Conv2D(filters=64 * mult * 2, kernel_size=(3, 3), strides=2, padding='same')(x)
        x = InstanceNormalization()(x)
        x = Activation('relu')(x)

    mult = 2 ** n_downsampling
    for i in range(res_blocks):

        input = x
        #filters = 256
        filters = mult*64
        kernel_size = (3, 3)
        strides = (1, 1)

        x = ReflectionPadding2D()(input)
        x = Conv2D(filters=filters,
                   kernel_size=kernel_size,
                   strides=strides, )(x)

        x = InstanceNormalization()(x)
        x = Activation('relu')(x)

        x = Dropout(0.5)(x)

        x = ReflectionPadding2D()(x)
        x = Conv2D(filters=filters,
                   kernel_size=kernel_size,
                   strides=strides, )(x)

        x = InstanceNormalization()(x)

        x = Add()([input, x])

    for i in range(2):
        mult = 2 ** (2 - i)
        x = Conv2DTranspose(filters=int(64 * mult / 2), kernel_size=(3, 3), strides=2, padding='same')(x)
        x = InstanceNormalization()(x)
        x = Activation('relu')(x)

    x = ReflectionPadding2D((3, 3))(x)
    x = Conv2D(filters=3, kernel_size=(7, 7), padding='valid')(x)
    x = Activation('tanh')(x)

    outputs = Add()([x, inputs])
    outputs = Lambda(lambda_function)(outputs)
    # outputs = Lambda(lambda z: z / 2)(outputs)

    model = Model(inputs=inputs, outputs=outputs, name='Generator')
    model_multiple_gpu = multi_gpu_model(model, gpus=4)

    return [model, model_multiple_gpu]


def discriminator():
    n_layers, use_sigmoid = 3, False

    x = Conv2D(filters=64, kernel_size=(4, 4), strides=2, padding='same')(inputs)
    x = LeakyReLU(0.2)(x)

    nf_mult, nf_mult_prev = 1, 1
    for n in range(n_layers):
        nf_mult_prev, nf_mult = nf_mult, min(2 ** n, 8)
        x = Conv2D(filters=64 * nf_mult, kernel_size=(4, 4), strides=2, padding='same')(x)
        x = InstanceNormalization()(x)
        x = LeakyReLU(0.2)(x)

    nf_mult_prev, nf_mult = nf_mult, min(2 ** n_layers, 8)
    x = Conv2D(filters=64 * nf_mult, kernel_size=(4, 4), strides=1, padding='same')(x)
    x = InstanceNormalization()(x)
    x = LeakyReLU(0.2)(x)

    x = Conv2D(filters=1, kernel_size=(4, 4), strides=1, padding='same')(x)
    if use_sigmoid:
        x = Activation('sigmoid')(x)

    x = Flatten()(x)
    x = Dense(1024, activation='tanh')(x)
    x = Dense(1, activation='sigmoid')(x)

    model = Model(inputs=inputs, outputs=x, name='Discriminator')
    model = multi_gpu_model(model, gpus=4)

    return model


def generator_and_discriminator(generator, discriminator):
    generated_image = generator(inputs)
    outputs = discriminator(generated_image)
    model = Model(inputs=inputs, outputs=[generated_image, outputs])

    return model
