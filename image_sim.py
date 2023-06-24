import os,sys
from subprocess import Popen

import torch
import cv2
import time
import numpy as np
import argparse
import logging
logger=logging.getLogger()
file_handler = logging.FileHandler('/home/ro/Documents/elad_designweek/coffee_reader/logs_sim.log')
formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

t=time.time()
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
imgs_path = '/home/ro/Documents/elad_designweek/compare_imgs'
compare_fns = os.listdir(imgs_path)
imgs = [cv2.imread(os.path.join(imgs_path, fn), cv2.IMREAD_UNCHANGED) for fn in compare_fns]
edge=int((720-640)/2)
imgs = [im[edge : 720-edge,edge : 720-edge] for im in imgs]

imgs = [(torch.tensor(img.transpose(2, 0, 1)).to(device) / 255.).unsqueeze(0) for img in imgs]

def find_similar_image(img_path):

    img1 = cv2.imread(img_path, cv2.IMREAD_UNCHANGED)
    img1 = (torch.tensor(img1.transpose(2, 0, 1)).to(device) / 255.).unsqueeze(0)
    simis=[torch.abs(img0-img1).mean().cpu().detach().numpy() for img0 in imgs]
    simis=np.array(simis).flatten()
    # simis=[e.detach().numpy() for e in simis]
    # print(np.argmax(simis))
    best_ind = np.argmax(simis)
    return best_ind, compare_fns[best_ind]

def similarity_simp(img0_path, img1_path):
    img0 = cv2.imread(img0_path, cv2.IMREAD_UNCHANGED)
    img1 = cv2.imread(img1_path, cv2.IMREAD_UNCHANGED)
    img0 = (torch.tensor(img0.transpose(2, 0, 1)).to(device) / 255.).unsqueeze(0)
    img1 = (torch.tensor(img1.transpose(2, 0, 1)).to(device) / 255.).unsqueeze(0)
    return torch.abs(img0-img1).mean()

if __name__ == '__main__':
    try:
        parser = argparse.ArgumentParser(description='Interpolation for a pair of images')
        parser.add_argument('--img', dest='img',default='/home/ro/Documents/elad_designweek/coffee_reader_v2/initial_frame.jpg', required=False)
        args = parser.parse_args()
        best_ind, best_fn=find_similar_image(args.img)
        # with open('/home/ro/Documents/elad_designweek/sketch_230528a/fortune.txt', 'w') as h:
        #     h.writelines([str(best_ind)])
        print(time.time()-t)
        print(best_ind)
        cmd_str = "cd /home/ro/Documents/code/RIFE-interpolation/ && python3 inference_img.py --img /home/ro/Documents/elad_designweek/coffee_reader_v2/initial_frame.jpg randomsting --exp=8 --match_ind "+str(best_ind)

        proc = Popen([cmd_str], shell=True,
                     stdin=None, stdout=None, stderr=None, close_fds=False, preexec_fn=os.setpgrp)
        sys.exit(0)
    except Exception as e:
        logger.error(e)