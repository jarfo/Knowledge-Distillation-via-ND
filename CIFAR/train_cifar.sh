#!/bin/bash

#SBATCH -x veuc[01] # Excluded Servers
#SBATCH -p veu      # Partition to submit to
#SBATCH --mem=60G   # Max CPU Memory
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=8

# Debug info
set | grep SLURM | while read line; do echo "# $line"; done
echo "# CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
echo ""
nvidia-smi

# ----------------------------------------------------------------------------------------------
# BaseLine
# python3.8 train_cifar_baseline.py \
#         --model_name resnet20_cifar \
#         --dataset 'cifar100' \
#         --epoch 240 \
#         --batch_size 64 \
#         --lr 0.1 \
#         --save_dir "./run/resnet20_cifar"
# ----------------------------------------------------------------------------------------------

# KD++
# --------------------------------------------------------
# 1、resnet56 - resnet20         1.0*cls + 1.0*kd + 2.0*nd
# 2、resnet32x4 - resnet8x4      1.0*cls + 3.5*kd + 2.0*nd
# 3、wrn40_2 - wrn40_1           1.0*cls + 1.0*kd + 1.5*nd
# 4、resnet50 - mobilenetv2      1.0*cls + 3.0*kd + 0.5*nd
# 5、resnet32x4 - shufflenetv1   1.0*cls + 2.5*kd + 1.5*nd
# 6、resnet32x4 - shufflenetv2   1.0*cls + 4.0*kd + 0.5*nd
# --------------------------------------------------------
# python3.8 train_cifar_kd.py \
#         --model_name resnet20_cifar \
#         --teacher resnet56_cifar \
#         --teacher_weights '../ckpt/teacher/cifar_teachers/resnet56_vanilla/ckpt_epoch_240.pth' \
#         --dataset 'cifar100' \
#         --epoch 240 \
#         --batch_size 64 \
#         --lr 0.1 \
#         --cls_loss_factor 1.0 \
#         --kd_loss_factor 1.0 \
#         --nd_loss_factor 2.0 \
#         --save_dir "./run/CIFAR100/KD++/res56-res20"
# ----------------------------------------------------------------------------------------------

# DKD
# ---------------------------------------------------------------------
# 1、resnet56 - resnet20         1.0*cls + 2.5*tckd + 4.0*nckd + 3.5*nd
# 2、resnet32x4 - resnet8x4      1.0*cls + 2.0*tckd + 8.0*nckd + 0.5*nd
# 3、wrn40_2 - wrn40_1           1.0*cls + 1.0*tckd + 6.0*nckd + 1.0*nd
# 4、resnet50 - mobilenetv2      1.0*cls + 0.5*tckd + 8.0*nckd + 1.0*nd
# 5、resnet32x4 - shufflenetv1   1.0*cls + 0.5*tckd + 8.0*nckd + 4.0*nd
# 6、resnet32x4 - shufflenetv2   1.0*cls + 0.5*tckd + 6.0*nckd + 0.5*nd
# ---------------------------------------------------------------------
python3.8 train_cifar_dkd.py \
        --model_name shufflev1_cifar \
        --teacher resnet32x4_cifar \
        --teacher_weights '../ckpt/teacher/cifar_teachers/resnet32x4_vanilla/ckpt_epoch_240.pth' \
        --dataset 'cifar100' \
        --epoch 240 \
        --batch_size 64 \
        --lr 0.02 \
        --cls_loss_factor 1.0 \
        --dkd_alpha 0.5 \
        --dkd_beta 8.0 \
        --nd_loss_factor 4.0 \
        --save_dir "./run/CIFAR100/DKD++/res32x4-sv1"

python3.8 -c "import torch; print(torch.cuda.is_available(), 'GPUS:', torch.cuda.device_count(), 'CUDNN:', torch.backends.cudnn.version())"
