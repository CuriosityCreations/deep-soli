#Soli Project Tensorflow

import argparse, sys, os
import tensorflow as tf
import numpy as np
import h5py

import glob
import random
from random import randrange, shuffle
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

def batch_norm(x, n_out, phase_train):

    # Batch normalization on convolutional maps.
    # Ref.: http://stackoverflow.com/questions/33949786/how-could-i-use-batch-normalization-in-tensorflow

    # y = gamma * ( x-mean(x) )/ sigma + beta

    # Training: gamma and beta
    beta = tf.Variable(tf.constant(0.0, shape=[n_out]), 
                                  name='beta', trainable=True)
    gamma = tf.Variable(tf.constant(0.0, shape=[n_out]), 
                                  name='gamma', trainable=True)

    # nn.moments: get mean and var from batch data
    batch_mean, batch_var = tf.nn.moments(x, [0,1,2], name='moments')

    # ExponentialMovingAverage, decay is tunable: make training better
    ema = tf.train.ExponentialMovingAverage(decay=0.99)

    # Update exp moving avr mean and var
    def mean_var_with_update():
        ema_apply_op = ema.apply([batch_mean, batch_var])

        # Return should run after ema_apply_op (parallel processing)
        with tf.control_dependencies([ema_apply_op]):
            # Return tensor for the value 
            return tf.identity(batch_mean), tf.identity(batch_var)

    # Conditional function select by phase_train
    mean, var = tf.cond(phase_train,
                        mean_var_with_update,
                        lambda: (ema.average(batch_mean), ema.average(batch_var)))

    normed = tf.nn.batch_normalization(x, mean, var, beta, gamma, 1e-3)

    return normed

def deepnn(x, rnn):

    # Four channel range-dopler map
    x_rdmap = tf.reshape(x, [-1, 32, 32, 4])
    print(np.shape(x_rdmap))

    # Convolutional layer 1: map 4 channel to 32 feature maps
    W_conv1  = weight_variable([3, 3, 4, 32])
    b_conv1  = bias_variable([32])
    h_conv1 = conv2d(x_rdmap, W_conv1, 2) + b_conv1
    print(np.shape(h_conv1))

    h_bn1 = tf.contrib.layers.batch_norm(h_conv1, 
                                         center=True, scale=True, 
                                         is_training=True)
    print(np.shape(h_bn1))
    h_relu1 = tf.nn.relu(h_bn1)
    #h_drop1 = tf.nn.dropout(h_relu1, 0.6)

    # Convolutional layer 2: map 32 feature maps to 64 feature maps
    W_conv2  = weight_variable([3, 3, 32, 64])
    b_conv2  = bias_variable([64])
    h_conv2  = conv2d(h_relu1, W_conv2, 2) + b_conv2
    h_bn2 = tf.contrib.layers.batch_norm(h_conv2, 
                                         center=True, scale=True, 
                                         is_training=True)
    h_relu2 = tf.nn.relu(h_bn2)
    h_drop2 = tf.nn.dropout(h_relu2, 0.6)

    # Convolutional layer 3: map 64 feature maps to 128 feature maps
    W_conv3  = weight_variable([3, 3, 64, 128])
    b_conv3  = bias_variable([128])
    h_conv3  = conv2d(h_drop2, W_conv3, 2) + b_conv3
    h_bn3 = tf.contrib.layers.batch_norm(h_conv3, 
                                         center=True, scale=True, 
                                         is_training=True)
    h_relu3 = tf.nn.relu(h_bn3)
    h_drop3 = tf.nn.dropout(h_relu3, 0.6)
    print(np.shape(h_drop3))

    # Fully connected layer 1
    W_fc1 = weight_variable([4 * 4 * 128, 512])
    b_fc1 = bias_variable([512])

    h_fc1_flat = tf.reshape(h_drop3, [-1, 4 * 4 * 128])
    h_fc1_mul  = tf.matmul(h_fc1_flat, W_fc1) + b_fc1
    h_fc1_bn = tf.contrib.layers.batch_norm(h_fc1_mul, 
                                            center=True, scale=True, 
                                            is_training=True)

    h_fc1_relu = tf.nn.relu(h_fc1_bn)
    h_fc1_drop = tf.nn.dropout(h_fc1_relu, 0.5)

    # Fully connected layer 2 for LSTM
    W_fc2 = weight_variable([512, 512])
    b_fc2 = bias_variable([512])
    h_fc2_mul = tf.matmul(h_fc1_drop, W_fc2) + b_fc2

    # LSTM Layer
    n_steps = 512
    fc_size = rnn
    h_lstm_stack = tf.expand_dims(h_fc2_mul, 1)
    print(np.shape(h_lstm_stack))

    h_lstm_cell = tf.nn.rnn_cell.LSTMCell(n_steps)
    h_lstm_dropout = tf.nn.rnn_cell.DropoutWrapper(h_lstm_cell, input_keep_prob=0.5, output_keep_prob=0.5)
    #init_state = h_lstm_dropout.zero_state(fc_size, tf.float32)

    # Creates a recurrent neural network
    h_lstms, _ = tf.nn.dynamic_rnn(h_lstm_dropout, h_lstm_stack, dtype=tf.float32)

    print(np.shape(h_lstms))
    h_lstm = tf.reshape(h_lstms, [-1, 512])
    print(np.shape(h_lstm))

    # Fully connected layer for output softmax
    W_fc3 = weight_variable([512, 13])
    b_fc3 = bias_variable([13])
    y_fc3 = tf.matmul(h_lstm, W_fc3) + b_fc3
    print(np.shape(y_fc3))

    return y_fc3
    

def weight_variable(shape):

    # Generates a weight variable of a given shape.
    initial = tf.truncated_normal(shape, stddev=0.1)
    return tf.Variable(initial)

def bias_variable(shape):

    # Generates a weight variable of a given shape.
    initial = tf.constant(0.1, shape=shape)
    return tf.Variable(initial)

def conv2d(x, W, stride):
    
    # Generates convolution net with stride=stride
    return tf.nn.conv2d(x, W, strides=[1, stride, stride, 1], padding='SAME')

def data_batch(data, label, rnnsteps):

    SequenceSize = np.shape(data)[0]
    random_index = randrange(0, SequenceSize - rnnsteps)

    data_batchseq = data[random_index : random_index + rnnsteps]
    label_batchseq = label[random_index : random_index + rnnsteps]

    return data_batchseq, label_batchseq

def data_epoch(file_dir, batchsize):

    file_name = glob.glob(file_dir)
    datasize = np.shape(file_name)[0]
    
    random.shuffle(file_name, random.random)

    progress = 0;
    for filename in file_name:

        progress = progress + 1
        sys.stdout.write('\r')

        i = np.int((progress / batchsize) * 100)
        sys.stdout.write("Epoch Loading Progress: [%-20s] %d%%  " % ('='*np.int(i/5), 1*i))
        

        # Import data
        with h5py.File(filename, 'r') as f:
            #Data and label are numpy arrays
            data_ch0 = f['ch{}'.format(0)][()]
            data_ch1 = f['ch{}'.format(1)][()]
            data_ch2 = f['ch{}'.format(2)][()]
            data_ch3 = f['ch{}'.format(3)][()]

            label_t  = f['label'][()]

        data = np.zeros((np.shape(data_ch0)[0], 1024, 4), dtype=np.float32)
    
        data[..., 0] = data_ch0
        data[..., 1] = data_ch1
        data[..., 2] = data_ch2
        data[..., 3] = data_ch3

        label = np.zeros((np.shape(data_ch0)[0], 13), dtype=np.float32)
        for i in label_t:
            label[..., i] = 1.0;

        if (progress == 1):
            data_total = data
            label_total = label
        else:
            data_total  = np.concatenate((data_total,  data ), axis=0)
            label_total = np.concatenate((label_total, label), axis=0)

        sys.stdout.write(str(np.shape(data_total)))
        sys.stdout.write(str(np.shape(label_total)))
        sys.stdout.flush()

        if (progress == batchsize):
            break
    return data_total, label_total
    

def main(file_dir):

    #use_channel = 0  #(0,1,2,3)
    
    #"../../dsp/*.h5"
    # Filename shuffle for training
    
    
    batchsize = 200
    rnnsteps = 40
    epoch = 50
    batch_iter = 10000
    file_dir = "../../dsp/*.h5"

    # Create the model
    x = tf.placeholder(tf.float32, [None, 1024, 4])

    # Define loss and optimizer
    y_ = tf.placeholder(tf.float32, [None, 13])

    # Build the graph for the deep net
    y_fc3 = deepnn(x, rnnsteps)

    # Logsoftmax for the output of net
    #y_fc3_softmax  = tf.nn.log_softmax(y_fc3)
    cost = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=y_fc3, labels=y_))

    # Train steps
    train_step = tf.train.AdamOptimizer(1e-3).minimize(cost)
    
    # Accuracy
    correct_prediction = tf.equal(tf.argmax(y_fc3, 1), tf.argmax(y_, 1))
    correct_prediction = tf.cast(correct_prediction, tf.float32)
    accuracy = tf.reduce_mean(correct_prediction)

    
    #tf training session
    with tf.Session() as sess:
        sess.run(tf.global_variables_initializer())

        for e in range(epoch + 1):

            # Random loading epoch data
            sys.stdout.write('_____________  <<< Epoch %d started >>>  _____________\n\n' % e)
            data_total, label_total = data_epoch(file_dir, batchsize)
            sys.stdout.write("\n")
            accum = 0;

            for b in range(batch_iter + 1):
            
                # Random select batch data 
                data_batchseq, label_batchseq = data_batch(data_total, label_total, rnnsteps)
    
                if b % 100 == 0:
                    
                    sys.stdout.write('\n')
                    j = np.float(((b) / (batch_iter)) * 100)
                    sys.stdout.write("Training Progress: [%-20s] %.3f%%  " % ('='*np.int(j/5), 1*j))

                    if b == 0:
                        sys.stdout.write("Avr Accuracy: %.3f%%  " % (0))
                    else:
                        train_accuracy = accuracy.eval(feed_dict={x: data_batchseq, y_: label_batchseq})
                        accum = accum + train_accuracy
                        sys.stdout.write("Avr Accuracy: %.3f%%  " % (accum*100*100/b))

                    sys.stdout.write("Epoch: %d" % (e))
                    sys.stdout.flush()
                train_step.run(feed_dict={x: data_batchseq, y_: label_batchseq})
            # Epoth finish
            sys.stdout.write('\n\n')

if __name__ == "__main__" :
    parser = argparse.ArgumentParser(description="Soli Tensorflow")
    parser.add_argument('--file', type=str)

    FLAGS, unparsed = parser.parse_known_args()

    tf.app.run(main=main, argv=[sys.argv[0]] + unparsed)

