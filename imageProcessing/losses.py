import keras.backend as K

from keras_contrib.losses import dssim, DSSIMObjective
from keras.applications.vgg19 import VGG19
from keras.models import Model
from keras.backend import mean, square, log, constant
from keras.losses import mean_squared_error

number_of_channels = 3
shape = (256, 256, 3)


def l1_loss(y_true, y_pred):
    return K.mean(K.abs(y_pred - y_true))


def perceptual_loss_100(y_true, y_pred):
    return 100 * perceptual_loss(y_true, y_pred)


def log10(x):
  numerator = log(x)
  denominator = log(constant(10, dtype=numerator.dtype))
  return numerator / denominator

def perceptual_loss(y_true, y_pred):
    vgg19 = VGG19(include_top=False, weights='imagenet', input_shape=shape)
    model = Model(vgg19.input, vgg19.get_layer('block3_conv3').output)
    model.trainable = False

    return mean(square(model(y_true) - model(y_pred)))


def wasserstein_loss(y_true, y_pred):
    return mean(y_true * y_pred)


def PSNR(y_true, y_pred):
    r = 255
    mse = mean_squared_error(y_true, y_pred)

    return 10 * log10(r * r / mse)

def SSIM(y_true, y_pred):
    # DSSIM = (1 - SSIM) / 2 => SSIM = 1 - 2 * DSSIM
    dssim = DSSIMObjective()
    return 1 - 2 * dssim(y_true, y_pred)