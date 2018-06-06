import keras
import coremltools

from keras.models import *
from keras.layers import *
from model import generator, lambda_function
from coremltools.proto import NeuralNetwork_pb2

def convert_lambda(layer):
    if layer.function == lambda_function:
        params = NeuralNetwork_pb2.CustomLayerParams()
        params.className = "Lambda"
        return params
    else:
        return None

def convert():
    generator_model = generator()
    coreml_model = coremltools.converters.keras.convert(generator_model,
                                                        input_names='blurred_img',
                                                        output_names='sharp_img',
                                                        add_custom_layers=True,
                                                        custom_conversion_functions={ "Lambda": convert_lambda})
    coreml_model.save('deblur.mlmodel')

if __name__ == '__main__':
    convert()