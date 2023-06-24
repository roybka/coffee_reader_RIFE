import os
import cv2
import time
import torch
import argparse
import logging
from torch.nn import functional as F
import warnings
from image_sim import *
logger=logging.getLogger()
file_handler = logging.FileHandler('/home/ro/Documents/elad_designweek/coffee_reader/logs.log')
formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)
# logger.setLevel(logging.INFO)

warnings.filterwarnings("ignore")
t=time.time()
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
torch.set_grad_enabled(False)

imgs_path = '/home/ro/Documents/elad_designweek/compare_imgs'
out_path='/home/ro/Documents/elad_designweek/coffee_reader_v2/data/'
compare_fns = os.listdir(imgs_path)
#'house.jpg', 'camera.jpg', 'heart.jpg', 'lookingglass.jpg', 'bubble.jpg', 'bell.jpg', 'envelope.jpg', 'eye.jpg', 'lock.jpg', 'arrow.jpg', 'trash.jpg', 'sandclock.jpg', 'hand.jpg']
radius=160
def crop_img(img,w,h):
    center = img.shape
    if center==(w,h):
        print('no crop')
        return img
    x = center[1] / 2 - w / 2
    y = center[0] / 2 - h / 2

    crop_img = img[int(y):int(y + h), int(x):int(x + w)]
    return crop_img

if torch.cuda.is_available():
    print("Using cuda")
    torch.backends.cudnn.enabled = True
    torch.backends.cudnn.benchmark = True

parser = argparse.ArgumentParser(description='Interpolation for a pair of images')
parser.add_argument('--img', dest='img', nargs=2, required=True)
parser.add_argument('--exp', default=4, type=int)
parser.add_argument('--ratio', default=0, type=float, help='inference ratio between two images with 0 - 1 range')
parser.add_argument('--rthreshold', default=0.02, type=float, help='returns image when actual ratio falls in given range threshold')
parser.add_argument('--rmaxcycles', default=8, type=int, help='limit max number of bisectional cycles')
parser.add_argument('--model', dest='modelDir', type=str, default='train_log', help='directory with trained model files')
parser.add_argument('--match_ind', dest='match_ind', type=int, default=99, help='matching image')

args = parser.parse_args()

try:
    try:
        try:
            from model.RIFE_HDv2 import Model
            model = Model()
            model.load_model(args.modelDir, -1)
            print("Loaded v2.x HD model.")
        except:
            from train_log.RIFE_HDv3 import Model
            model = Model()
            model.load_model(args.modelDir, -1)
            print("Loaded v3.x HD model.")
    except:
        from model.RIFE_HD import Model
        model = Model()
        model.load_model(args.modelDir, -1)
        print("Loaded v1.x HD model")
except:
    from model.RIFE import Model
    model = Model()
    model.load_model(args.modelDir, -1)
    print("Loaded ArXiv-RIFE model")
model.eval()
model.device()
print('read model', time.time()-t)
t = time.time()

match_ind = np.random.randint(len(compare_fns)) if args.match_ind==99 else args.match_ind
print(args.match_ind,match_ind)
if args.img[0].endswith('.exr') and args.img[1].endswith('.exr'):
    img0 = cv2.imread(args.img[0], cv2.IMREAD_COLOR | cv2.IMREAD_ANYDEPTH)
    img1 = cv2.imread(args.img[1], cv2.IMREAD_COLOR | cv2.IMREAD_ANYDEPTH)
    img0 = (torch.tensor(img0.transpose(2, 0, 1)).to(device)).unsqueeze(0)
    img1 = (torch.tensor(img1.transpose(2, 0, 1)).to(device)).unsqueeze(0)

else:
    img0 = cv2.imread(args.img[0], cv2.IMREAD_UNCHANGED)
    img1 = cv2.imread(os.path.join(imgs_path,compare_fns[match_ind]), cv2.IMREAD_UNCHANGED)
    img1=crop_img(img1,640,640)
    img0 = (torch.tensor(img0.transpose(2, 0, 1)).to(device) / 255.).unsqueeze(0)
    img1 = (torch.tensor(img1.transpose(2, 0, 1)).to(device) / 255.).unsqueeze(0)
# print(similarity_simp(args.img[0],args.img[1]))
n, c, h, w = img0.shape
ph = ((h - 1) // 32 + 1) * 32
pw = ((w - 1) // 32 + 1) * 32
padding = (0, pw - w, 0, ph - h)
img0 = F.pad(img0, padding)
img1 = F.pad(img1, padding)


if args.ratio:
    img_list = [img0]
    img0_ratio = 0.0
    img1_ratio = 1.0
    if args.ratio <= img0_ratio + args.rthreshold / 2:
        middle = img0
    elif args.ratio >= img1_ratio - args.rthreshold / 2:
        middle = img1
    else:
        tmp_img0 = img0
        tmp_img1 = img1
        for inference_cycle in range(args.rmaxcycles):
            middle = model.inference(tmp_img0, tmp_img1)
            middle_ratio = ( img0_ratio + img1_ratio ) / 2
            if args.ratio - (args.rthreshold / 2) <= middle_ratio <= args.ratio + (args.rthreshold / 2):
                break
            if args.ratio > middle_ratio:
                tmp_img0 = middle
                img0_ratio = middle_ratio
            else:
                tmp_img1 = middle
                img1_ratio = middle_ratio
    img_list.append(middle)
    img_list.append(img1)
else:
    img_list = [img0, img1]
    for i in range(args.exp):
        tmp = []
        for j in range(len(img_list) - 1):
            mid = model.inference(img_list[j], img_list[j + 1])
            tmp.append(img_list[j])
            tmp.append(mid)
        tmp.append(img1)
        img_list = tmp
print('done inference',time.time()-t)
t=time.time()

if not os.path.exists('output'):
    os.mkdir('output')

# for i in range(len(img_list)):
#     if args.img[0].endswith('.exr') and args.img[1].endswith('.exr'):
#         cv2.imwrite('output/img{}.exr'.format(i), (img_list[i][0]).cpu().numpy().transpose(1, 2, 0)[:h, :w], [cv2.IMWRITE_EXR_TYPE, cv2.IMWRITE_EXR_TYPE_HALF])
#     else:
#         cv2.imwrite('output/img{}.png'.format("%04d"%i), (img_list[i][0] * 255).byte().cpu().numpy().transpose(1, 2, 0)[:h, :w])
# print('done writing files',time.time()-t)
# t=time.time()
w=640

mask = np.ones((w,w))
cx = mask.shape[0]/2
cy = mask.shape[0]/2
for i in range(w):
    for j in range(w):
        if (i-cx)**2 + (j-cy)**2 < radius**2:
            mask[i,j] = 0
mask = torch.tensor(mask,dtype=bool,device='cuda')

for i in range(len(img_list)):

    img_list[i][0][:, mask]=img_list[0][0][:, mask]
    
out = cv2.VideoWriter(os.path.join(out_path,'morph.mp4'), cv2.VideoWriter_fourcc(*'mp4v'), 30, (640,640))
for i in range(len(img_list)):
    img = (img_list[i][0] * 255).byte().cpu().numpy().transpose(1, 2, 0)[:h, :w]
    out.write(img)
# arr=[-1,-1,-2,-2,-3,-3,-2,-2,-1,-1,-2,-2,-3,-3,-2,-1,-2,-3,-2,-1,-1-1,-1]
arr=[-1,-1,-1,-1,-1,-1]*3
for i in arr:
    img = (img_list[i][0] * 255).byte().cpu().numpy().transpose(1, 2, 0)[:h, :w]
    out.write(img)
out.release()
# os.system(f"ffmpeg -i {os.path.join(out_path,'morph.mp4')} -vcodec libx264 {os.path.join(out_path,'morpha.mp4')}")
torch.cuda.empty_cache()
print('done making video',time.time()-t)
