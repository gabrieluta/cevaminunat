import keras.backend as K
from keras.applications.vgg16 import VGG16
from keras.models import Model
from keras.backend import mean, square, abs

def l1_loss(y_true, y_pred):
    return mean(abs(y_pred - y_true))

def perceptual_loss_100(y_true, y_pred):
    return 100 * perceptual_loss(y_true, y_pred)

def perceptual_loss(y_true, y_pred):
    vgg = VGG16(include_top=False, weights='imagenet', input_shape=(256, 256, 3))
    loss_model = Model(inputs=vgg.input, outputs=vgg.get_layer('block3_conv3').output)
    loss_model.trainable = False
    return mean(square(loss_model(y_true) - loss_model(y_pred)))

def wasserstein_loss(y_true, y_pred):
    return mean(y_true * y_pred)