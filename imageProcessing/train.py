import matplotlib.pyplot as plt
import matplotlib
matplotlib.use("TkAgg")
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

epochs = 5
batch_size = 4
test_blurred_path = "/data/blurred_sharp/blurred/"
test_sharp_path = "/data/blurred_sharp/sharp/"
process_parameter = 127.5


def load_data():
    blurred_images = []
    sharp_images = []

    if os.path.exists(train_blurred_path) and os.path.exists(train_sharp_path):

        image_list = sorted(os.listdir(train_blurred_path))
        blurred_images = np.asarray(
            [(img_to_array(load_img(train_blurred_path + image).resize((256, 256), Image.ANTIALIAS)) - 127.5) / 127.5
             for image in image_list])

        image_list = sorted(os.listdir(train_sharp_path))
        sharp_images = np.asarray(
            [(img_to_array(load_img(train_sharp_path + image).resize((256, 256), Image.ANTIALIAS)) - 127.5) / 127.5 for
             image in image_list])

    else:
        print("You gave a invalid train path!")

    return blurred_images, sharp_images


def save_weights(model):
    path = os.path.join("/data/weights")
    if not os.path.exists(path):
        os.makedirs(path)
    model.save_weights(os.path.join(path, 'generator_weights.h5'), overwrite=True)


def evaluate_gan():
    print("Starting training")
    os.system("nvidia-smi")
    print('Epochs: {}'.format(epochs))
    print('Batch size: {}'.format(batch_size))

    blurred, sharp = load_data()
    optimizer = Adam(lr=1E-4, beta_1=0.9, beta_2=0.999, epsilon=1e-08)
    true_batch = np.ones((batch_size, 1))
    false_batch = np.zeros((batch_size, 1))

    initial_generator_model, generator_model = generator()
    initial_generator_model.summary()
    generator_model.summary()

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
    mean_discriminator_losses = []
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

            for _ in range(5):
                generated_images = generator_model.predict(x=image_blur_batch, batch_size=batch_size)
                discriminator_loss_real = discriminator_model.train_on_batch(image_sharp_batch, true_batch)
                discriminator_loss_fake = discriminator_model.train_on_batch(generated_images, false_batch)

                mean_discriminator_loss = np.add(discriminator_loss_fake, discriminator_loss_real) / 2
                discriminator_losses.append(mean_discriminator_loss)

            mean_discriminator_loss = np.mean(discriminator_losses)
            print('Batch {} discriminator loss : {}'.format(batch + 1, mean_discriminator_loss))

            discriminator_model.trainable = False

            # GAN training:
            gan_out = gan.train_on_batch(image_blur_batch, [image_sharp_batch, true_batch])

            if batch == int(blurred.shape[0] / batch_size) - 1:
                gan_perceptual_losses.append(gan_out[1])
                gan_wasserstein_losses.append(gan_out[2])

                # Generator performance:
                scores = generator_model.evaluate(generated_images, image_sharp_batch, batch_size=batch_size)
                print("scores: {}".format(scores))
                generator_perceptual_losses.append(scores[0])
                generator_psnr_metrics.append(scores[1])

                print("gan_out[1]: {}".format(gan_out[1]))
                print("gan_out[2]: {}".format(gan_out[2]))
                print("scores[0]: {}".format(scores[0]))
                print("scores[1]: {}".format(scores[1]))

                mean_discriminator_losses.append(mean_discriminator_loss)

            discriminator_model.trainable = True

            # we suppose that wasserstein loss is also the best for this model
            if gan_out[0] < best_loss:
                print("Time to save weights")
                save_weights(initial_generator_model)
                best_loss = gan_out[0]

    print("generator_perceptual_losses: {}".format(generator_perceptual_losses))
    print("generator_psnr_metrics: {}".format(generator_psnr_metrics))

    print("gan_perceptual_losses: {}".format(gan_perceptual_losses))
    print("gan_wasserstein_losses: {}".format(gan_wasserstein_losses))

    print("mean_discriminator_losses: {}".format(mean_discriminator_losses))

    epoch_arr = [i for i in range(epochs)]
    batch_epoch_arr = [i for i in range(epochs * batch_size)]

    plt.plot(np.asarray(epoch_arr), np.asarray(generator_perceptual_losses))

    plt.title('Generator perceptual loss')
    plt.ylabel('perceptual')
    plt.xlabel('epoch')

    plt.savefig("generator_perceptual.png")
    plt.close()

    plt.plot(np.asarray(epoch_arr), np.asarray(generator_psnr_metrics))

    plt.title('Generator PSNR')
    plt.ylabel('PSNR')
    plt.xlabel('epoch')

    plt.savefig("generator_psnr.png")
    plt.close()

    plt.plot(np.asarray(epoch_arr), np.asarray(gan_perceptual_losses))

    plt.title('GAN perceptual loss')
    plt.ylabel('perceptual')
    plt.xlabel('epoch')

    plt.savefig("GAN_perceptual.png")
    plt.close()

    plt.plot(np.asarray(epoch_arr), np.asarray(gan_wasserstein_losses))

    plt.title('GAN wasserstein loss')
    plt.ylabel('wasserstein')
    plt.xlabel('epoch')

    plt.savefig("GAN_wasserstein.png")
    plt.close()

    plt.plot(np.asarray(epoch_arr), np.asarray(mean_discriminator_losses))

    plt.title('Discriminator wasserstein loss')
    plt.ylabel('wasserstein')
    plt.xlabel('epoch')

    plt.savefig("discriminator_wasserstein.png")
    plt.close()




if __name__ == '__main__':
    evaluate_gan()
