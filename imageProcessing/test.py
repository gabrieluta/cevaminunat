import os
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

import numpy as np
import os
from PIL import Image
from numpy import *

image_shape = (256, 256, 3)

def l1_loss(y_true, y_pred):
    return K.mean(K.abs(y_pred - y_true))

def perceptual_loss_100(y_true, y_pred):
    return 100 * perceptual_loss(y_true, y_pred)

def perceptual_loss(y_true, y_pred):
    vgg = VGG16(include_top=False, weights='imagenet', input_shape=image_shape)
    loss_model = Model(inputs=vgg.input, outputs=vgg.get_layer('block3_conv3').output)
    loss_model.trainable = False
    return K.mean(K.square(loss_model(y_true) - loss_model(y_pred)))

def wasserstein_loss(y_true, y_pred):
    return K.mean(y_true * y_pred)


class InstanceNormalization(Layer):

    def __init__(self,
                 axis=None,
                 epsilon=1e-3,
                 center=True,
                 scale=True,
                 beta_initializer='zeros',
                 gamma_initializer='ones',
                 beta_regularizer=None,
                 gamma_regularizer=None,
                 beta_constraint=None,
                 gamma_constraint=None,
                 **kwargs):
        super(InstanceNormalization, self).__init__(**kwargs)
        self.supports_masking = True
        self.axis = axis
        self.epsilon = epsilon
        self.center = center
        self.scale = scale
        self.beta_initializer = initializers.get(beta_initializer)
        self.gamma_initializer = initializers.get(gamma_initializer)
        self.beta_regularizer = regularizers.get(beta_regularizer)
        self.gamma_regularizer = regularizers.get(gamma_regularizer)
        self.beta_constraint = constraints.get(beta_constraint)
        self.gamma_constraint = constraints.get(gamma_constraint)

    def build(self, input_shape):
        ndim = len(input_shape)
        if self.axis == 0:
            raise ValueError('Axis cannot be zero')

        if (self.axis is not None) and (ndim == 2):
            raise ValueError('Cannot specify axis for rank 1 tensor')

        self.input_spec = InputSpec(ndim=ndim)

        if self.axis is None:
            shape = (1,)
        else:
            shape = (input_shape[self.axis],)

        if self.scale:
            self.gamma = self.add_weight(shape=shape,
                                         name='gamma',
                                         initializer=self.gamma_initializer,
                                         regularizer=self.gamma_regularizer,
                                         constraint=self.gamma_constraint)
        else:
            self.gamma = None
        if self.center:
            self.beta = self.add_weight(shape=shape,
                                        name='beta',
                                        initializer=self.beta_initializer,
                                        regularizer=self.beta_regularizer,
                                        constraint=self.beta_constraint)
        else:
            self.beta = None
        self.built = True

    def call(self, inputs, training=None):
        input_shape = K.int_shape(inputs)
        reduction_axes = list(range(0, len(input_shape)))

        if (self.axis is not None):
            del reduction_axes[self.axis]

        del reduction_axes[0]

        mean = K.mean(inputs, reduction_axes, keepdims=True)
        stddev = K.std(inputs, reduction_axes, keepdims=True) + self.epsilon
        normed = (inputs - mean) / stddev

        broadcast_shape = [1] * len(input_shape)
        if self.axis is not None:
            broadcast_shape[self.axis] = input_shape[self.axis]

        if self.scale:
            broadcast_gamma = K.reshape(self.gamma, broadcast_shape)
            normed = normed * broadcast_gamma
        if self.center:
            broadcast_beta = K.reshape(self.beta, broadcast_shape)
            normed = normed + broadcast_beta
        return normed

    def get_config(self):
        config = {
            'axis': self.axis,
            'epsilon': self.epsilon,
            'center': self.center,
            'scale': self.scale,
            'beta_initializer': initializers.serialize(self.beta_initializer),
            'gamma_initializer': initializers.serialize(self.gamma_initializer),
            'beta_regularizer': regularizers.serialize(self.beta_regularizer),
            'gamma_regularizer': regularizers.serialize(self.gamma_regularizer),
            'beta_constraint': constraints.serialize(self.beta_constraint),
            'gamma_constraint': constraints.serialize(self.gamma_constraint)
        }
        base_config = super(InstanceNormalization, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))

get_custom_objects().update({'InstanceNormalization': InstanceNormalization})

def spatial_reflection_2d_padding(x, padding=((1, 1), (1, 1)), data_format=None):

    assert len(padding) == 2
    assert len(padding[0]) == 2
    assert len(padding[1]) == 2
    if data_format is None:
        data_format = image_data_format()
    if data_format not in {'channels_first', 'channels_last'}:
        raise ValueError('Unknown data_format ' + str(data_format))

    if data_format == 'channels_first':
        pattern = [[0, 0],
                   [0, 0],
                   list(padding[0]),
                   list(padding[1])]
    else:
        pattern = [[0, 0],
                   list(padding[0]), list(padding[1]),
                   [0, 0]]
    return tf.pad(x, pattern, "REFLECT")


class ReflectionPadding2D(Layer):

    def __init__(self,
                 padding=(1, 1),
                 data_format=None,
                 **kwargs):

        super(ReflectionPadding2D, self).__init__(**kwargs)
        self.data_format = conv_utils.normalize_data_format(data_format)
        if isinstance(padding, int):
            self.padding = ((padding, padding), (padding, padding))
        elif hasattr(padding, '__len__'):
            if len(padding) != 2:
                raise ValueError('`padding` should have two elements. '
                                 'Found: ' + str(padding))
            height_padding = conv_utils.normalize_tuple(padding[0], 2,
                                                        '1st entry of padding')
            width_padding = conv_utils.normalize_tuple(padding[1], 2,
                                                       '2nd entry of padding')
            self.padding = (height_padding, width_padding)
        else:
            raise ValueError('`padding` should be either an int, '
                             'a tuple of 2 ints '
                             '(symmetric_height_pad, symmetric_width_pad), '
                             'or a tuple of 2 tuples of 2 ints '
                             '((top_pad, bottom_pad), (left_pad, right_pad)). '
                             'Found: ' + str(padding))
        self.input_spec = InputSpec(ndim=4)

    def compute_output_shape(self, input_shape):
        if self.data_format == 'channels_first':
            if input_shape[2] is not None:
                rows = input_shape[2] + self.padding[0][0] + self.padding[0][1]
            else:
                rows = None
            if input_shape[3] is not None:
                cols = input_shape[3] + self.padding[1][0] + self.padding[1][1]
            else:
                cols = None
            return (input_shape[0],
                    input_shape[1],
                    rows,
                    cols)
        elif self.data_format == 'channels_last':
            if input_shape[1] is not None:
                rows = input_shape[1] + self.padding[0][0] + self.padding[0][1]
            else:
                rows = None
            if input_shape[2] is not None:
                cols = input_shape[2] + self.padding[1][0] + self.padding[1][1]
            else:
                cols = None
            return (input_shape[0],
                    rows,
                    cols,
                    input_shape[3])

    def call(self, inputs):
        return spatial_reflection_2d_padding(inputs,
                                             padding=self.padding,
                                             data_format=self.data_format)

    def get_config(self):
        config = {'padding': self.padding,
                  'data_format': self.data_format}
        base_config = super(ReflectionPadding2D, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))


class myUnet(object):

    def __init__(self, img_rows=256, img_cols=256):
        self.img_rows = img_rows
        self.img_cols = img_cols



    def load_data(self):

        train_path = "/usr/local/blurred_sharp/blurred/"
        image_list = sorted(os.listdir(train_path))[:100]
        imgs_train = [img_to_array(load_img(train_path + image).resize((256, 256), Image.ANTIALIAS)) for image in image_list]
        imgs_train = np.asarray(imgs_train)

        mask_path = "/usr/local/blurred_sharp/sharp/"
        image_list = sorted(os.listdir(mask_path))[:100]
        imgs_mask_train = [img_to_array(load_img(mask_path + image).resize((256, 256), Image.ANTIALIAS)) for image in image_list]
        imgs_mask_train = np.asarray(imgs_mask_train)

        # test_path = "/usr/local/blurred_sharp/blurred/"
        # image_list = sorted(os.listdir(test_path))
        # imgs_test = [img_to_array(load_img(test_path + image)) for image in image_list]
        # imgs_test = np.asarray(imgs_test)
        imgs_test = imgs_train

        return imgs_train, imgs_mask_train, imgs_test

    def res_block(input, filters, kernel_size=(3, 3), strides=(1, 1), use_dropout=False):

        print("input: ", input)
        x = ReflectionPadding2D()(input)
        print("x1", x)
        x = Conv2D(filters=filters,
                   kernel_size=kernel_size,
                   strides=strides, )(x)

        print("x2", x)
        x = BatchNormalization()(x)
        print("x3", x)
        x = Activation('relu')(x)
        print("x4", x)

        if use_dropout:
            x = Dropout(0.5)(x)

        print("x5", x)
        x = ReflectionPadding2D()(x)
        print("x6", x)
        x = Conv2D(filters=filters,
                   kernel_size=kernel_size,
                   strides=strides, )(x)

        print("x7", x)
        x = BatchNormalization()(x)
        print("x8", x)

        # Two convolution layers followed by a direct connection between input and output
        merged = Add()([input, x])
        return merged

    def get_unet(self):
        inputs = Input((256, 256, 3))

        conv1 = ReflectionPadding2D((3, 3))(inputs)

        conv1 = Conv2D(64, 7, padding='valid', strides=(1, 1))(conv1)
        # print("conv1 shape:", conv1.shape)
        instanceN1 = BatchNormalization()(conv1)
        # instanceN1 = InstanceNormalization(epsilon=0.1, gamma_regularizer=regularizers.l2(0.01), beta_regularizer=regularizers.l2(0.01))(conv1)
        relu1 = Activation('relu')(instanceN1)

        conv2 = Conv2D(128, 3, padding='same', strides=(2, 2))(relu1)
        # print("conv2 shape:", conv2.shape)
        instanceN2 = BatchNormalization()(conv2)
        # instanceN2 = InstanceNormalization(epsilon=0.1, gamma_regularizer=regularizers.l2(0.01), beta_regularizer=regularizers.l2(0.01))(conv2)
        relu2 = Activation('relu')(instanceN2)

        conv3 = Conv2D(256, 3, padding='same', strides=(2, 2))(relu2)
        # print("conv3 shape:", conv3.shape)
        instanceN3 = BatchNormalization()(conv3)
        # instanceN3 = InstanceNormalization(epsilon=0.1, gamma_regularizer=regularizers.l2(0.01), beta_regularizer=regularizers.l2(0.01))(conv3)
        relu3 = Activation('relu')(instanceN3)

        x = relu3
        n_blocks_gen = 9
        print("res: ", x)
        for i in range(n_blocks_gen):
            input = x
            # res = self.res_block(res, 256, use_dropout=True)
            filters = 256
            kernel_size = (3, 3)
            strides = (1, 1)
            x = ReflectionPadding2D()(input)
            print("x1", x)
            x = Conv2D(filters=filters,
                       kernel_size=kernel_size,
                       strides=strides, )(x)

            print("x2", x)
            x = BatchNormalization()(x)
            print("x3", x)
            x = Activation('relu')(x)
            print("x4", x)

            # if use_dropout:
            x = Dropout(0.5)(x)

            print("x5", x)
            x = ReflectionPadding2D()(x)
            print("x6", x)
            x = Conv2D(filters=filters,
                       kernel_size=kernel_size,
                       strides=strides, )(x)

            print("x7", x)
            x = BatchNormalization()(x)
            print("x8", x)

            # Two convolution layers followed by a direct connection between input and output
            x = Add()([input, x])

        conv4 = Conv2DTranspose(filters=int(128), kernel_size=(3, 3), strides=(2, 2), padding='same')(x)
        instanceN4 = BatchNormalization()(conv4)
        relu4 = Activation('relu')(instanceN4)

        conv5 = Conv2DTranspose(filters=int(64), kernel_size=(3, 3), strides=(2, 2), padding='same')(relu4)
        instanceN5 = BatchNormalization()(conv5)
        relu5 = Activation('relu')(instanceN5)

        padd6 = ReflectionPadding2D((3, 3))(relu5)
        conv6 = Conv2D(filters=3, kernel_size=(7, 7), padding='valid')(padd6)
        tan6 = Activation('tanh')(conv6)

        outputs = Add()([tan6, inputs])
        # outputs = Lambda(lambda z: K.clip(z, -1, 1))(x)
        outputs = Lambda(lambda z: z / 2)(outputs)

        model = Model(inputs=inputs, outputs=outputs, name='Generator')
        model.compile(optimizer=Adam(lr=1e-4), loss=[perceptual_loss])

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
