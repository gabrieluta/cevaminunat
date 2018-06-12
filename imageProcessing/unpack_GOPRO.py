
import os
from shutil import copyfile

import click
import tqdm

def reorganize_gopro_files():

    dir_in, dir_out = "/data/image_deblurring/GOPRO_Large", "/data/image_deblurring/large_dataset"

    if not os.path.exists(dir_out):
        os.makedirs(dir_out)

    for folder_train_test in tqdm.tqdm(os.listdir(dir_in), desc='dir'):
        output_directory = os.path.join(dir_out, folder_train_test)
        output_directory_A = os.path.join(output_directory, 'blurred')
        output_directory_B = os.path.join(output_directory, 'sharp')
        if not os.path.exists(output_directory):
            os.makedirs(output_directory)
        if not os.path.exists(output_directory_A):
            os.makedirs(output_directory_A)
        if not os.path.exists(output_directory_B):
            os.makedirs(output_directory_B)

        current_folder_path = os.path.join(dir_in, folder_train_test)
        if "._" not in str(current_folder_path) and ".DS_Store" not in str(current_folder_path):

            for image_folder in tqdm.tqdm(os.listdir(current_folder_path), desc='image_folders'):

                current_sub_folder_path = os.path.join(current_folder_path, image_folder)

                if "._" not in str(current_sub_folder_path) and ".DS_Store" not in str(current_sub_folder_path):
                    for image_blurred in os.listdir(os.path.join(current_sub_folder_path, 'blur')):
                        if "._" not in str(image_blurred):
                            current_image_blurred_path = os.path.join(current_sub_folder_path, 'blur', image_blurred)
                            output_image_blurred_path = os.path.join(output_directory_A, image_folder + "_" + image_blurred)
                            copyfile(current_image_blurred_path, output_image_blurred_path)

                    for image_sharp in os.listdir(os.path.join(current_sub_folder_path, 'sharp')):
                        if "._" not in str(image_sharp):
                            current_image_sharp_path = os.path.join(current_sub_folder_path, 'sharp', image_sharp)
                            output_image_sharp_path = os.path.join(output_directory_B, image_folder + "_" + image_sharp)
                            copyfile(current_image_sharp_path, output_image_sharp_path)


if __name__ == "__main__":
    reorganize_gopro_files()