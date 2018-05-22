import os
import matplotlib.pyplot as plt

from PIL import Image
from numpy import *
from keras.preprocessing.image import img_to_array, load_img
from model import generator

batch_size = 4
test_blurred_path = "/data/blurred_sharp/blurred/"
test_sharp_path = "/data/blurred_sharp/sharp/"
process_parameter = 128


def test():

    image_list = sorted(os.listdir(test_blurred_path))[:100]
    images_test_blurred = np.asarray([(img_to_array(load_img(test_blurred_path + image).resize((256, 256), Image.ANTIALIAS)) - process_parameter) / process_parameter for image in image_list])

    n_images = len(images_test_blurred)
    print("Testing on {} images".format(n_images))

    image_list = sorted(os.listdir(test_sharp_path))[:100]
    images_test_sharp = np.asarray([(img_to_array(load_img(test_sharp_path + image).resize((256, 256), Image.ANTIALIAS)) - process_parameter) / process_parameter for image in image_list])

    generator_model = generator()
    print("Loading weights")
    generator_model.load_weights('weights.h5')

    print("Generator is making predictions")
    generated_images = generator_model.predict(x=images_test_blurred, batch_size=batch_size)
    generated = np.array([img * process_parameter + process_parameter for img in generated_images])
    images_test_blurred = np.asarray([image * process_parameter + process_parameter for image in images_test_blurred])
    images_test_sharp = np.asarray([image * process_parameter + process_parameter for image in images_test_sharp])

    print("Saving images")
    for i in range(generated_images.shape[0]):

        y = images_test_sharp[i, :, :, :]
        x = images_test_blurred[i, :, :, :]
        img = generated[i, :, :, :]
        output = np.concatenate((y, x, img), axis=1)
        im = Image.fromarray(output.astype(np.uint8))
        im.save('sharp{}.png'.format(i))
