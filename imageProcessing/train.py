from losses import wasserstein_loss, perceptual_loss
from model import generator_model, discriminator_model, generator_containing_discriminator, generator_containing_discriminator_multiple_outputs
from keras.optimizers import Adam
from keras.preprocessing.image import img_to_array, load_img

import numpy as np
import os
from PIL import Image
from numpy import *

epoch_num = 10
batch_size = 4
critic_updates = 5

def load_data():
    train_path = "/data/blurred_sharp/blurred/"
    image_list = sorted(os.listdir(train_path))[:100]
    imgs_train = [(img_to_array(load_img(train_path + image).resize((256, 256), Image.ANTIALIAS)) - 127.5)/127.5 for image in image_list]

    imgs_train = np.asarray(imgs_train)

    mask_path = "/data/blurred_sharp/sharp/"
    image_list = sorted(os.listdir(mask_path))[:100]
    imgs_mask_train = [(img_to_array(load_img(mask_path + image).resize((256, 256), Image.ANTIALIAS)) - 127.5)/127.5 for image in image_list]
    imgs_mask_train = np.asarray(imgs_mask_train)

    return imgs_train, imgs_mask_train

def train():

    x_train, y_train = load_data()

    g = generator_model()
    d = discriminator_model()
    d_on_g = generator_containing_discriminator_multiple_outputs(g, d)

    opt = Adam(lr=1E-4, beta_1=0.9, beta_2=0.999, epsilon=1e-08)

    d.trainable = True
    d.compile(optimizer=opt, loss=wasserstein_loss)
    d.trainable = False
    loss = [perceptual_loss, wasserstein_loss]
    loss_weights = [100, 1]
    d_on_g.compile(optimizer=opt, loss=loss, loss_weights=loss_weights)
    d.trainable = True

    output_true_batch, output_false_batch = np.ones((batch_size, 1)), np.zeros((batch_size, 1))

    d_on_g.summary()

    # os.system("nvidia-smi")


    for epoch in range(epoch_num):
        print('epoch: {}/{}'.format(epoch, epoch_num))
        print('batches: {}'.format(x_train.shape[0] / batch_size))

        permutated_indexes = np.random.permutation(x_train.shape[0])

        d_losses = []
        d_on_g_losses = []
        for index in range(int(x_train.shape[0] / batch_size)):
            batch_indexes = permutated_indexes[index * batch_size:(index + 1) * batch_size]
            image_blur_batch = x_train[batch_indexes]
            image_full_batch = y_train[batch_indexes]

            generated_images = g.predict(x=image_blur_batch, batch_size=batch_size)

            for _ in range(critic_updates):
                d_loss_real = d.train_on_batch(image_full_batch, output_true_batch)
                d_loss_fake = d.train_on_batch(generated_images, output_false_batch)
                d_loss = 0.5 * np.add(d_loss_fake, d_loss_real)
                d_losses.append(d_loss)

            print('batch {} d_loss : {}'.format(index + 1, np.mean(d_losses)))

            d.trainable = False

            # os.system("nvidia-smi")

            print(image_blur_batch.shape())
            print(image_full_batch.shape())
            d_on_g_loss = d_on_g.train_on_batch(image_blur_batch, [image_full_batch, output_true_batch])
            d_on_g_losses.append(d_on_g_loss)
            print('batch {} d_on_g_loss : {}'.format(index + 1, d_on_g_loss))

            d.trainable = True

        with open('log.txt', 'a') as f:
            f.write('{} - {} - {}\n'.format(epoch, np.mean(d_losses), np.mean(d_on_g_losses)))


if __name__ == '__main__':
    train()