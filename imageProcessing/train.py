import matplotlib.pyplot as plt
import numpy as np
import os
import tensorflow as tf

from losses import wasserstein_loss, perceptual_loss, SSIM, PSNR
from model import generator, discriminator, generator_and_discriminator
from keras.optimizers import Adam
from keras.preprocessing.image import img_to_array, load_img
from PIL import Image
from numpy import *

train_blurred_path = "/data/blurred_sharp/blurred/"
train_sharp_path = "/data/blurred_sharp/sharp/"

epochs = 10
batch_size = 4

batch_size = 4
test_blurred_path = "/data/blurred_sharp/blurred/"
test_sharp_path = "/data/blurred_sharp/sharp/"
process_parameter = 127.5


def load_data():
    blurred_images = []
    sharp_images = []

    if os.path.exists(train_blurred_path) and os.path.exists(train_sharp_path):

        image_list = sorted(os.listdir(train_blurred_path))[:10]
        blurred_images = np.asarray(
            [(img_to_array(load_img(train_blurred_path + image).resize((256, 256), Image.ANTIALIAS)) - 127.5) / 127.5
             for image in image_list])

        image_list = sorted(os.listdir(train_sharp_path))[:10]
        sharp_images = np.asarray(
            [(img_to_array(load_img(train_sharp_path + image).resize((256, 256), Image.ANTIALIAS)) - 127.5) / 127.5 for
             image in image_list])

    else:
        print("You gave a invalid train path!")

    return blurred_images, sharp_images


def save_weights(generator):
    path = os.path.join("/data/weights")
    if not os.path.exists(path):
        os.makedirs(path)
    generator.save_weights(os.path.join(path, 'weights.h5'), overwrite=True)


def evaluate_gan():
    print("Starting training")
    os.system("nvidia-smi")
    print('Epochs: {}'.format(epochs))
    print('Batch size: {}'.format(batch_size))

    blurred, sharp = load_data()
    optimizer = Adam(lr=1E-4, beta_1=0.9, beta_2=0.999, epsilon=1e-08)
    true_batch = np.ones((batch_size, 1))
    false_batch = np.zeros((batch_size, 1))

    generator_model = generator()
    discriminator_model = discriminator()
    gan = generator_and_discriminator(generator_model, discriminator_model)

    discriminator_model.trainable = True
    discriminator_model.compile(optimizer=optimizer, loss=wasserstein_loss)
    discriminator_model.trainable = False

    gan.compile(optimizer=optimizer, loss=[perceptual_loss, wasserstein_loss], loss_weights=[100, 1])

    generator_model.compile(loss=[perceptual_loss], optimizer=optimizer, metrics=[PSNR])
    discriminator_model.trainable = True

    # print("Generator summary:")
    # discriminator_model.summary()
    # print("Discriminator summary:")
    # discriminator_model.summary()
    # print("GAN summary:")
    # gan.summary()
    best_loss = 100000
    discriminator_losses = []
    gan_perceptual_losses = []
    gan_wasserstein_losses = []
    generator_perceptual_losses = []
    generator_psnr_metrics = []

    for epoch in range(epochs):
        print('Epoch: {}/{}'.format(epoch, epochs))
        print('Batches: {}'.format(blurred.shape[0] / batch_size))

        permutated_indexes = np.random.permutation(blurred.shape[0])

        for batch in range(int(blurred.shape[0] / batch_size)):
            batch_indexes = permutated_indexes[batch * batch_size:(batch + 1) * batch_size]
            image_blur_batch = blurred[batch_indexes]
            image_sharp_batch = sharp[batch_indexes]

            # print(image_blur_batch.shape())
            # print(image_full_batch.shape())

            for _ in range(5):
                generated_images = generator_model.predict(x=image_blur_batch, batch_size=batch_size)
                discriminator_loss_real = discriminator_model.train_on_batch(image_sharp_batch, true_batch)
                discriminator_loss_fake = discriminator_model.train_on_batch(generated_images, false_batch)

                mean_discriminator_loss = np.add(discriminator_loss_fake, discriminator_loss_real) / 2
                discriminator_losses.append(mean_discriminator_loss)

            print('Batch {} discriminator loss : {}'.format(batch + 1, np.mean(discriminator_losses)))

            discriminator_model.trainable = False

            # GAN training:
            gan_out = gan.train_on_batch(image_blur_batch, [image_sharp_batch, true_batch])

            if batch == int(blurred.shape[0] / batch_size) - 1:
                print("gan_out[0]: {}".format(gan_out[0]))
                print("gan_out[2]: {}".format(gan_out[2]))
                print("scores[0]: {}".format(scores[0]))
                print("scores[1]: {}".format(scores[1]))

                gan_perceptual_losses.append(gan_out[0])
                # gan_out[1]
                gan_wasserstein_losses.append(gan_out[2])

                # Generator test performance:
                scores = generator_model.evaluate(generated_images, image_sharp_batch, batch_size=batch_size)
                generator_perceptual_losses.append(scores[0])
                generator_psnr_metrics.append(scores[1])

            discriminator_model.trainable = True

            # we suppose that wasserstein loss is also the best for this model
            if gan_out[0] < best_loss:
                save_weights(generator_model)
                best_loss = gan_out[0]

    print("len gan_perceptual_losses: {}".format(len(gan_perceptual_losses)))
    print("len generator_perceptual_losses".format(len(generator_perceptual_losses)))
    print("len generator_psnr_metrics".format(len(generator_psnr_metrics)))


    epoch_arr = [i for i in range(epochs)]
    plt.plot(epoch_arr, gan_perceptual_losses, 'r')
    plt.plot(epoch_arr, generator_perceptual_losses, 'b')

    plt.title('Perceptual loss')
    plt.ylabel('loss')
    plt.xlabel('epoch')

    plt.savefig("/data/image_processing/perc.png")
    plt.close()

    plt.plot(epoch_arr, generator_psnr_metrics)

    plt.title('generator_psnr_metrics')
    plt.ylabel('psnr')
    plt.xlabel('epoch')

    plt.savefig("/data/image_processing/psnr.png")
    plt.close()


if __name__ == '__main__':
    evaluate_gan()
