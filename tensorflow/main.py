#Soli Project Tensorflow

import argparse
import tensorflow as tf
import numpy as np
import h5py

use_channel = 0
file_name = '../dsp/0_0_0.h5'

def main(file_dir):

    with h5py.File(file_name, 'r') as f:
        # Data and label are numpy arrays
        data = f['ch{}'.format(use_channel)][()]
        label = f['label'][()]


if __name__ == "__main__" :
    parser = argparse.ArgumentParser(description="Soli Tensorflow")
    parser.add_argument('--file', type=str)

    args = parser.parse_args()

    main(args.file)

